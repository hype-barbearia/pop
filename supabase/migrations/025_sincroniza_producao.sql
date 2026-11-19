-- Hype POP · 025 · o repositório passa a guardar exatamente o que roda na produção
-- Ao montar o banco de teste a partir das migrações (19/11/2026), a comparação objeto por objeto
-- mostrou 7 funções da produção diferentes das migrações (ajustes feitos direto no banco).
-- Este arquivo grava a versão da produção, copiada do banco, para teste e produção ficarem iguais.
-- Rodar na produção não muda nada, a não ser disparar_envio (item 3), que continua com o mesmo efeito.

/* 1. Proteção do Supabase: toda tabela nova em public nasce com as regras de acesso ligadas */
-- (só cria se não existir: na produção ela já vem do Supabase e não é tocada)
do $do$ begin if to_regproc('public.rls_auto_enable') is null then execute $x$
create or replace function public.rls_auto_enable() returns event_trigger
language plpgsql security definer set search_path to 'pg_catalog' as $fn$
declare cmd record; tbl name;
begin
  for cmd in select * from pg_event_trigger_ddl_commands()
    where command_tag in ('CREATE TABLE', 'CREATE TABLE AS', 'SELECT INTO') and object_type in ('table', 'partitioned table')
  loop
    if cmd.schema_name is not null and cmd.schema_name in ('public') then
      begin
        select c.relname into tbl from pg_catalog.pg_class c where c.oid = cmd.objid;
        execute format('alter table if exists %I.%I enable row level security', cmd.schema_name, tbl);
      exception when others then raise log 'rls_auto_enable: failed on %', cmd.object_identity;
      end;
    end if;
  end loop;
end $fn$
$x$; end if; end $do$;
do $$ begin if not exists (select 1 from pg_event_trigger where evtname = 'ensure_rls') then
  create event trigger ensure_rls on ddl_command_end execute function public.rls_auto_enable(); end if; end $$;

/* 2. Funções na versão da produção */
create or replace function public.config_privada(k text) returns text
language sql stable security definer set search_path to 'public', 'privado'
as $function$ select valor from privado.config where chave = k $function$;
revoke execute on function public.config_privada(text) from public, anon, authenticated;
grant execute on function public.config_privada(text) to service_role;

create or replace function public.checar_saude() returns integer
language plpgsql security definer set search_path to 'public', 'cron' as $function$
declare d date := hoje(); dow int := extract(dow from hoje()); n int := 0; s text; k int; rg regras;
  hora time := (now() at time zone 'America/Recife')::time;
begin
  select * into rg from regras where id = 1;
  for s in select id from pessoas where papel = 'socio' and ativo loop
    if dow <> 0 and hora >= '09:05' and rg.inicio_operacao is not null and d >= rg.inicio_operacao
       and not exists (select 1 from dias_fechados where data = d) and not exists (select 1 from execucoes where data = d) then
      perform notificar(s, 'saude:dia:' || d || ':' || s, 'Atenção: nenhum checklist foi criado hoje', 'A geração automática do dia não rodou. Avise o suporte do app.'); n := n + 1;
    end if;
    select count(*) into k from cron.job_run_details where status = 'failed' and start_time > now() - interval '24 hours';
    if k > 0 then
      perform notificar(s, 'saude:cron:' || d || ':' || s, 'Atenção: tarefas automáticas com falha', k || ' falha(s) nas últimas 24 horas. Avise o suporte do app.'); n := n + 1;
    end if;
    select count(*) into k from notificacoes where enviado_em is null and criado_em < now() - interval '15 min' and criado_em > now() - interval '2 hours';
    if k >= 3 then
      perform notificar(s, 'saude:push:' || d || ':' || s, 'Atenção: avisos presos', k || ' notificações não saíram. Avise o suporte do app.'); n := n + 1;
    end if;
    select count(*) into k from erros_app where em > now() - interval '24 hours';
    if k >= 5 then
      perform notificar(s, 'saude:erros:' || d || ':' || s, 'O app registrou ' || k || ' erros hoje', 'Pode ser algo pontual de internet. Se repetir, avise o suporte do app.'); n := n + 1;
    end if;
  end loop;
  return n;
end $function$;
revoke execute on function public.checar_saude() from public, anon, authenticated;

create or replace function public.concluir(e uuid) returns void
language plpgsql security definer set search_path to 'public' as $function$
declare faltam int; nc boolean; amostra numeric;
begin
  if not pode_executar(e) then raise exception 'Este checklist não é seu.'; end if;
  select count(*) into faltam from rotina_itens i join execucoes x on x.rotina_id = i.rotina_id
   where x.id = e and i.ativo and not exists (select 1 from execucao_itens ei where ei.execucao_id = e and ei.item_id = i.id);
  if faltam > 0 then raise exception 'Faltam % itens.', faltam; end if;
  nc := exists (select 1 from execucao_itens where execucao_id = e and not ok);
  amostra := coalesce((select conferir_amostra from regras where id = 1), 1);
  update execucoes set concluida_em = now(), refazer_em = null, refazer_obs = null,
    sorteada = case when refazer_em is not null or nc then true else coalesce(sorteada, random() < amostra) end
  where id = e and concluida_em is null;
end $function$;

create or replace function public.dev_registrar_acesso(alvo text, modo text, detalhe text default null::text) returns void
language plpgsql security definer set search_path to 'public' as $function$
begin
  if not sou_dev() then raise exception 'Só o acesso DEV.'; end if;
  if modo not in ('ver', 'simulador') then raise exception 'Modo inválido.'; end if;
  if exists (select 1 from dev_acessos where dev_id = eu() and alvo_id is not distinct from nullif(alvo, '') and modo = dev_registrar_acesso.modo and em > now() - interval '10 min') then return; end if;
  insert into dev_acessos (dev_id, alvo_id, modo, detalhe) values (eu(), nullif(alvo, ''), modo, nullif(detalhe, ''));
end $function$;

create or replace function public.gerar_dia(d date) returns integer
language plpgsql security definer set search_path to 'public' as $function$
declare
  dow int := extract(dow from d);
  r rotinas; j rotina_janelas; base text[]; quem text[]; p text; n int := 0; desloc int; resp text; ag rotina_agendamentos;
  surpresa boolean := coalesce((select rondas_surpresa from regras where id = 1), false);
begin
  if dow = 0 then return 0; end if;
  if not exists (select 1 from regras where id = 1 and inicio_operacao is not null and d >= inicio_operacao) then return 0; end if;
  if exists (select 1 from dias_fechados where data = d) then return 0; end if;
  for r in select * from rotinas where ativo and dow = any(dias) loop
    if r.quinzenal and ((d - date '2026-10-19') % 14) <> 0 then continue; end if;
    for j in select rj.* from rotina_janelas rj where rj.rotina_id = r.id and rj.ativo and (rj.dias is null or dow = any(rj.dias))
        and not (d = (select inicio_operacao from regras where id = 1) and rj.inicio < coalesce((select inicio_hora from regras where id = 1), '00:00')) loop
      if r.cada is not null then
        select array_agg(id) into base from pessoas where id = any(r.cada) and ativo;
      elsif r.cada_papel is not null then
        select array_agg(id order by ordem) into base from pessoas where papel = r.cada_papel and ativo;
      else
        resp := coalesce((select pessoa_id from rodizio_escala where rotina_id = r.id and rodizio_escala.dow = extract(dow from d)), j.responsavel);
        base := array[resp];
      end if;
      quem := '{}';
      foreach p in array coalesce(base, '{}') loop
        p := quem_faz(p, d, r.ignora_folga);
        if p is not null and not p = any(quem) then quem := quem || p; end if;
      end loop;
      desloc := case when r.tipo = 'ronda' and surpresa then (floor(random() * 61) - 30)::int else 0 end;
      foreach p in array quem loop
        insert into execucoes (data, rotina_id, janela_id, pessoa_id, inicio, prazo)
        values (d, r.id, j.id, p,
          ((d + j.inicio) at time zone 'America/Recife') + make_interval(mins => desloc),
          ((d + j.prazo) at time zone 'America/Recife') + make_interval(mins => desloc))
        on conflict (data, janela_id, pessoa_id) do nothing;
        if found then n := n + 1; end if;
      end loop;
    end loop;
  end loop;
  for ag in select * from rotina_agendamentos where data = d loop n := n + gerar_agendamento(ag); end loop;
  perform ajustar_rondas(d);
  return n;
end $function$;
revoke execute on function public.gerar_dia(date) from public, anon, authenticated;

create or replace function public.lembrar_nf(pessoa text, periodo date) returns void
language plpgsql security definer set search_path to 'public' as $function$
declare v numeric;
begin
  if not sou_gestor() then raise exception 'Só a gerente ou os sócios mandam o lembrete.'; end if;
  select nv.valor into v from nf_valores nv where nv.pessoa_id = pessoa and nv.periodo = lembrar_nf.periodo;
  if v is null then raise exception 'Informe o valor antes de lembrar.'; end if;
  perform notificar(pessoa, 'nflem:' || pessoa || ':' || periodo || ':' || to_char(now(), 'YYYYMMDDHH24'),
    'Lembrete: nota fiscal de ' || nf_rotulo(periodo),
    'Valor: R$ ' || brl(v) || '. Emita a NFS-e para a Hype e envie em Perfil até ' || to_char(nf_prazo(periodo), 'DD/MM') || '.');
  perform disparar_envio('enviar');
end $function$;

create or replace function public.registrar_ausencia(pessoa text, de date, ate date, motivo text, substituto text default null::text) returns void
language plpgsql security definer set search_path to 'public' as $function$
declare x execucoes;
begin
  if not sou_gestor() then raise exception 'Só a gerente ou os sócios registram ausência.'; end if;
  if substituto = pessoa then raise exception 'O substituto precisa ser outra pessoa.'; end if;
  insert into ausencias (pessoa_id, inicio, fim, motivo, substituto, por) values (pessoa, de, ate, motivo, nullif(substituto, ''), eu());
  for x in select * from execucoes e where e.pessoa_id = pessoa and e.data between de and ate and e.concluida_em is null
           and not exists (select 1 from execucao_itens i where i.execucao_id = e.id) loop
    if nullif(substituto, '') is not null and not exists (select 1 from execucoes y where y.data = x.data and y.janela_id = x.janela_id and y.pessoa_id = substituto) then
      update execucoes set pessoa_id = substituto where id = x.id;
    else
      delete from execucoes where id = x.id;
    end if;
  end loop;
end $function$;

/* 3. Envio das notificações: o endereço do projeto vem de privado.config ('url_projeto'),
      para o mesmo código servir à produção e ao teste. Sem a chave, vale o endereço da produção. */
create or replace function public.disparar_envio(tarefa text default 'enviar') returns void language plpgsql security definer set search_path = public, privado as $$
begin
  perform net.http_post(
    url := coalesce((select valor from privado.config where chave = 'url_projeto'), 'https://fwecscsvfxocgjspdsis.supabase.co') || '/functions/v1/notificar?tarefa=' || tarefa,
    headers := jsonb_build_object('Content-Type', 'application/json', 'x-hype-segredo', (select valor from privado.config where chave = 'segredo_cron')),
    body := '{}'::jsonb);
end $$;
revoke execute on function public.disparar_envio(text) from public, anon, authenticated;
