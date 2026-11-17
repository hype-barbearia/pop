-- Hype POP · 017 · negócio, UX, programação e LGPD (17/11/2026)
-- 1. Semana de aprendizado: atraso não escala aos sócios e não entra no histórico até a data definida.
-- 2. Falhas por item (pauta da reunião e POP para revisar).
-- 3. Lista de reposição (falta de material).
-- 4. Elogio e reclamação de cliente.
-- 5. Status de acesso e de notificações da equipe.
-- 6. Foto de referência por item ("como deve ficar").
-- 7. Aviso de privacidade (LGPD) com registro de ciência.
-- 8. Alerta de saúde do sistema para os sócios.

/* ---------------- 1. Semana de aprendizado ---------------- */
alter table regras add column if not exists aprendizado_ate date;
update regras set aprendizado_ate = '2026-11-24' where id = 1 and aprendizado_ate is null;

do $$ declare def text; begin
  def := pg_get_functiondef('gerar_notificacoes()'::regprocedure);
  if position('aprendizado_ate' in def) = 0 then
    def := replace(def, 'if x.concluida_em is null and x.prazo + make_interval(mins => rg.escalar) <= agora',
      'if d > coalesce(rg.aprendizado_ate, date ''1900-01-01'') and x.concluida_em is null and x.prazo + make_interval(mins => rg.escalar) <= agora');
    if position('aprendizado_ate' in def) = 0 then raise exception 'gerar_notificacoes: trecho da escalada não encontrado'; end if;
    execute def;
  end if;
end $$;

create or replace function historico(dias int default 28)
returns table (data date, rotina_id text, pessoa_id text, chave text, previstos int, no_prazo int, atraso int, nao_feito int)
language sql stable security definer set search_path = public as $$
  select x.data, x.rotina_id, x.pessoa_id,
    x.rotina_id || '.' || x.pessoa_id || '.' || coalesce(to_char(j.inicio, 'HH24MI'), 'AVULSO'),
    1, (x.concluida_em is not null and x.concluida_em <= x.prazo)::int,
    (x.concluida_em is not null and x.concluida_em > x.prazo)::int, (x.concluida_em is null)::int
  from execucoes x left join rotina_janelas j on j.id = x.janela_id
  where sou_membro() and x.data < hoje() and x.data >= hoje() - historico.dias
    and x.data > coalesce((select aprendizado_ate from regras where id = 1), date '1900-01-01')
    and (ve_tudo() or x.pessoa_id = eu())
$$;

/* ---------------- 2. Falhas por item ---------------- */
create or replace function falhas_itens(dias int default 7)
returns table (item_id text, texto text, rotina_id text, rotina text, pop_id text, falhas int, ultima date)
language sql stable security definer set search_path = public as $$
  select i.id, i.texto, r.id, r.titulo, r.pop_id, count(*)::int, max(x.data)
  from execucao_itens ei
    join execucoes x on x.id = ei.execucao_id
    join rotina_itens i on i.id = ei.item_id
    join rotinas r on r.id = x.rotina_id
  where ve_tudo() and not ei.ok and x.data > hoje() - falhas_itens.dias
  group by i.id, i.texto, r.id, r.titulo, r.pop_id
  order by count(*) desc, max(x.data) desc
  limit 20
$$;

/* ---------------- 3. Reposição ---------------- */
create table if not exists reposicao (
  id serial primary key,
  item text not null,
  obs text,
  execucao_id uuid references execucoes(id) on delete set null,
  pedido_por text references pessoas(id),
  em timestamptz not null default now(),
  resolvido_em timestamptz,
  resolvido_por text references pessoas(id));
create index if not exists reposicao_aberta on reposicao (em) where resolvido_em is null;
alter table reposicao enable row level security;
drop policy if exists ler on reposicao;
create policy ler on reposicao for select to authenticated using (sou_membro());

create or replace function pedir_reposicao(item text, obs text default null, execucao uuid default null)
returns int language plpgsql security definer set search_path = public as $$
declare novo int;
begin
  if not sou_membro() then raise exception 'Acesso só para a equipe da Hype.'; end if;
  if coalesce(trim(item), '') = '' then raise exception 'Escreva o que está faltando.'; end if;
  insert into reposicao (item, obs, execucao_id, pedido_por) values (trim(item), nullif(trim(obs), ''), execucao, eu()) returning id into novo;
  perform notificar(g, 'rep:' || novo || ':' || g, 'Falta material: ' || trim(item), 'Pedido de ' || coalesce((select nome from pessoas where id = eu()), 'equipe') || '. Veja a lista de reposição.')
    from gerentes_do_dia(hoje()) g where g <> coalesce(eu(), '');
  return novo;
end $$;

create or replace function resolver_reposicao(r int, desfazer boolean default false)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not sou_gestor() then raise exception 'Só a gerente ou os sócios marcam a reposição.'; end if;
  update reposicao set resolvido_em = case when desfazer then null else now() end, resolvido_por = case when desfazer then null else eu() end where id = r;
end $$;

/* ---------------- 4. Cliente: elogio e reclamação ---------------- */
create or replace function registrar_cliente(tipo text, texto text, pessoa text default null)
returns int language plpgsql security definer set search_path = public as $$
declare novo int;
begin
  if not sou_membro() then raise exception 'Acesso só para a equipe da Hype.'; end if;
  if tipo not in ('elogio', 'reclamacao') then raise exception 'Tipo inválido.'; end if;
  if coalesce(trim(texto), '') = '' then raise exception 'Escreva o que o cliente disse.'; end if;
  insert into ocorrencias (data, pessoa_id, origem, titulo, descricao, criado_por, status)
  values (hoje(), nullif(pessoa, ''), case when tipo = 'elogio' then 'Cliente · elogio' else 'Cliente · reclamação' end,
    case when tipo = 'elogio' then 'Elogio de cliente' else 'Reclamação de cliente' end, trim(texto), eu(),
    case when tipo = 'elogio' then 'resolvida' else 'aberta' end)
  returning id into novo;
  return novo;
end $$;

/* ---------------- 5. Status da equipe (acesso, avisos, privacidade) ---------------- */
create table if not exists privacidade_aceite (
  pessoa_id text not null references pessoas(id), versao int not null, em timestamptz not null default now(),
  primary key (pessoa_id, versao));
alter table privacidade_aceite enable row level security;
drop policy if exists ler on privacidade_aceite;
create policy ler on privacidade_aceite for select to authenticated using (pessoa_id = eu() or ve_tudo());

create or replace function aceitar_privacidade(versao int) returns void language plpgsql security definer set search_path = public as $$
begin
  if eu() is null then raise exception 'Acesso só para a equipe da Hype.'; end if;
  insert into privacidade_aceite (pessoa_id, versao) values (eu(), aceitar_privacidade.versao) on conflict do nothing;
end $$;

create or replace function status_equipe()
returns table (pessoa_id text, avisos int, ultimo_acesso timestamptz, privacidade timestamptz)
language sql stable security definer set search_path = public, auth as $$
  select p.id,
    (select count(*)::int from push_inscricoes s where s.pessoa_id = p.id),
    (select max(u.last_sign_in_at) from auth.users u where p.email is not null and lower(u.email) = lower(p.email)),
    (select max(a.em) from privacidade_aceite a where a.pessoa_id = p.id)
  from pessoas p where ve_tudo() and p.ativo
$$;

/* ---------------- 6. Foto de referência ---------------- */
alter table rotina_itens add column if not exists foto_ref text;
-- A limpeza de 90 dias não apaga as fotos de referência
create or replace function fotos_antigas(dias int) returns table (name text)
language sql stable security definer set search_path = public, storage as $$
  select o.name from storage.objects o
  where o.bucket_id = 'fotos' and o.name not like 'ref/%' and o.created_at < now() - make_interval(days => dias) limit 500
$$;

/* ---------------- 8. Saúde do sistema ---------------- */
create or replace function checar_saude() returns int language plpgsql security definer set search_path = public, cron as $$
declare d date := hoje(); dow int := extract(dow from hoje()); n int := 0; s text; k int; rg regras;
  hora time := (now() at time zone 'America/Recife')::time;
begin
  select * into rg from regras where id = 1;
  for s in select id from pessoas where papel = 'socio' and ativo loop
    -- dia útil sem nenhum checklist criado
    if dow <> 0 and hora >= '09:05' and rg.inicio_operacao is not null and d >= rg.inicio_operacao
       and not exists (select 1 from dias_fechados where data = d) and not exists (select 1 from execucoes where data = d) then
      perform notificar(s, 'saude:dia:' || d || ':' || s, 'Atenção: nenhum checklist foi criado hoje', 'A geração automática do dia não rodou. Avise o suporte do app.'); n := n + 1;
    end if;
    -- tarefas automáticas com falha nas últimas 24 h
    select count(*) into k from cron.job_run_details where status = 'failed' and start_time > now() - interval '24 hours';
    if k > 0 then
      perform notificar(s, 'saude:cron:' || d || ':' || s, 'Atenção: tarefas automáticas com falha', k || ' falha(s) nas últimas 24 horas. Avise o suporte do app.'); n := n + 1;
    end if;
    -- avisos que não saíram
    select count(*) into k from notificacoes where enviado_em is null and criado_em < now() - interval '15 min' and criado_em > now() - interval '2 hours';
    if k >= 3 then
      perform notificar(s, 'saude:push:' || d || ':' || s, 'Atenção: avisos presos', k || ' notificações não saíram. Avise o suporte do app.'); n := n + 1;
    end if;
    -- erros registrados pelo app
    select count(*) into k from erros_app where em > now() - interval '24 hours';
    if k >= 5 then
      perform notificar(s, 'saude:erros:' || d || ':' || s, 'O app registrou ' || k || ' erros hoje', 'Pode ser algo pontual de internet. Se repetir, avise o suporte do app.'); n := n + 1;
    end if;
  end loop;
  return n;
end $$;

do $$ begin
  if not exists (select 1 from cron.job where jobname = 'hype_pop_saude') then
    perform cron.schedule('hype_pop_saude', '10 12,18,23 * * *', $c$ select public.checar_saude(); select public.disparar_envio('enviar'); $c$);
  end if;
end $$;

/* ---------------- Permissões ---------------- */
do $$ declare f text; begin
  foreach f in array array['falhas_itens(int)','pedir_reposicao(text,text,uuid)','resolver_reposicao(int,boolean)','registrar_cliente(text,text,text)',
                           'aceitar_privacidade(int)','status_equipe()'] loop
    execute format('revoke execute on function %s from public, anon', f);
    execute format('grant execute on function %s to authenticated', f);
  end loop;
  revoke execute on function checar_saude() from public, anon, authenticated;
end $$;
