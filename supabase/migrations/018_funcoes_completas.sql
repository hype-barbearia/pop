-- Hype POP · 018 · definição completa das funções que foram ajustadas por troca de texto
-- As migrações 008, 010, 014, 016 e 017 alteraram estas funções editando o texto delas no banco.
-- Este arquivo grava a versão final de cada uma, inteira, para o banco poder ser recriado igual
-- a partir das migrações (copiado do banco em 17/11/2026). Rodar de novo não muda nada.

CREATE OR REPLACE FUNCTION public.agendar(rotina text, data date, inicio time without time zone, prazo time without time zone, pessoa text, obs text DEFAULT NULL::text)
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare a rotina_agendamentos;
begin
  if not sou_socio() then raise exception 'Só os sócios agendam.'; end if;
  if prazo <= inicio then raise exception 'O prazo precisa ser depois do início.'; end if;
  insert into rotina_agendamentos (rotina_id, data, inicio, prazo, pessoa_id, obs, criado_por)
  values (rotina, data, inicio, prazo, pessoa, nullif(trim(obs), ''), eu()) returning * into a;
  if a.data <= hoje() then perform gerar_agendamento(a); perform ajustar_rondas(a.data); end if;
  return a.id;
end $function$
;

CREATE OR REPLACE FUNCTION public.definir_valor_nf(pessoa text, periodo date, valor numeric)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if not sou_gestor() then raise exception 'Só a gerente ou os sócios definem o valor da nota.'; end if;
  if extract(day from periodo) not in (1, 16) then raise exception 'Período inválido.'; end if;
  if valor is null or valor < 0 then raise exception 'Informe um valor válido.'; end if;
  insert into nf_valores (pessoa_id, periodo, valor, definido_por) values (pessoa, periodo, valor, eu())
  on conflict on constraint nf_valores_pkey do update set valor = excluded.valor, definido_por = excluded.definido_por, em = now();
  perform notificar(pessoa, 'nfval:' || pessoa || ':' || periodo || ':' || valor,
    'Valor da sua nota: R$ ' || brl(valor),
    'Período de ' || nf_rotulo(periodo) || '. Emita a NFS-e para a Hype e envie em Perfil até ' || to_char(nf_prazo(periodo), 'DD/MM') || '.');
end $function$
;

CREATE OR REPLACE FUNCTION public.gerar_notificacoes()
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  d date := hoje(); agora timestamptz := now(); rg regras; x record; g text; s text; n int := 0; txt text;
begin
  select * into rg from regras where id = 1;
  if exists (select 1 from dias_fechados where data = d) then return 0; end if;
  for x in select e.*, r.titulo, r.conferir, p.nome from execucoes e join rotinas r on r.id = e.rotina_id join pessoas p on p.id = e.pessoa_id where e.data = d loop
    if x.inicio <= agora and x.inicio > agora - interval '15 min' and x.concluida_em is null and x.rotina_id <> 'RON' then
      perform notificar(x.pessoa_id, 'ini:' || x.id, 'Hora do checklist: ' || x.titulo, 'Prazo até ' || to_char(x.prazo at time zone 'America/Recife', 'HH24:MI') || '.');
    end if;
    if x.rotina_id = 'RON' and x.inicio - make_interval(mins => rg.antes) <= agora and x.inicio > agora - interval '15 min' then
      perform notificar(x.pessoa_id, 'ini:' || x.id, 'Ronda dos inegociáveis às ' || to_char(x.inicio at time zone 'America/Recife', 'HH24:MI'), 'Avalie os 10 itens com a casa funcionando.');
    end if;
    if x.concluida_em is null and x.prazo <= agora and x.prazo > agora - interval '3 hours' then
      perform notificar(x.pessoa_id, 'atr:' || x.id, 'Checklist atrasado: ' || x.titulo, 'O prazo era ' || to_char(x.prazo at time zone 'America/Recife', 'HH24:MI') || '. Conclua assim que puder.');
      for g in select * from gerentes_do_dia(d) loop
        if g <> x.pessoa_id then perform notificar(g, 'atrg:' || x.id || ':' || g, 'Atraso: ' || x.titulo || ' · ' || x.nome, 'Prazo era ' || to_char(x.prazo at time zone 'America/Recife', 'HH24:MI') || '. Abra o app para cobrar.'); end if;
      end loop;
    end if;
    if d > coalesce(rg.aprendizado_ate, date '1900-01-01') and x.concluida_em is null and x.prazo + make_interval(mins => rg.escalar) <= agora and x.prazo > agora - interval '3 hours' then
      for s in select id from pessoas where (papel = 'socio' or (socio and rg.escalar_socios)) and ativo loop
        perform notificar(s, 'esc:' || x.id || ':' || s, 'Escalado: ' || x.titulo || ' · ' || x.nome, rg.escalar || ' min de atraso.');
      end loop;
    end if;
    if x.conferir and coalesce(x.sorteada, true) and x.concluida_em is not null and x.conferido_em is null and x.concluida_em + make_interval(mins => rg.conferir) <= agora and x.concluida_em > agora - interval '4 hours' then
      for g in select * from gerentes_do_dia(d) loop
        perform notificar(g, 'conf:' || x.id || ':' || g, 'Conferir: ' || x.titulo || ' · ' || x.nome, 'Concluído às ' || to_char(x.concluida_em at time zone 'America/Recife', 'HH24:MI') || '.');
      end loop;
    end if;
  end loop;
  for x in select * from lembretes l where l.ativo and extract(dow from d) = any(l.dias)
           and (d + l.hora) at time zone 'America/Recife' <= agora and (d + l.hora) at time zone 'America/Recife' > agora - interval '30 min'
           and not exists (select 1 from lembretes_feitos f where f.lembrete_id = l.id and f.data = d) loop
    for g in select * from gerentes_do_dia(d) loop
      perform notificar(g, 'lem:' || x.id || ':' || d || ':' || g, 'Lembrete: ' || x.texto, 'Marque como feito no app.');
    end loop;
  end loop;
  for x in select * from lembretes l where l.ativo and extract(dow from d) = any(l.dias)
           and (d + l.hora) at time zone 'America/Recife' + interval '30 min' <= agora and (d + l.hora) at time zone 'America/Recife' > agora - interval '60 min'
           and not exists (select 1 from lembretes_feitos f where f.lembrete_id = l.id and f.data = d) loop
    for g in select * from gerentes_do_dia(d) loop
      perform notificar(g, 'lem2:' || x.id || ':' || d || ':' || g, 'Ainda pendente: ' || x.texto, 'Lembrete das ' || to_char(x.hora, 'HH24:MI') || '. Marque como feito no app.');
    end loop;
  end loop;
  if (d + rg.resumo) at time zone 'America/Recife' <= agora and exists (select 1 from execucoes where data = d) then
    txt := resumo_do_dia(d);
    insert into resumos (data, texto) values (d, txt) on conflict (data) do nothing;
    for s in select id from pessoas where (papel = 'socio' or socio) and ativo loop
      perform notificar(s, 'res:' || d || ':' || s, 'Resumo de hoje na Hype', txt);
    end loop;
  end if;
  get diagnostics n = row_count;
  return n;
end $function$
;

CREATE OR REPLACE FUNCTION public.lembretes_fiscais()
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  d date := hoje(); rg regras; per date := nf_periodo_atual(hoje()); prazo date := nf_prazo(nf_periodo_atual(hoje()));
  comp date := (date_trunc('month', hoje()) - interval '1 month')::date; lim_das date := make_date(extract(year from hoje())::int, extract(month from hoje())::int, 20);
  p pessoas; v numeric; tem_nf boolean; tem_das boolean; g text; n int := 0;
begin
  select * into rg from regras where id = 1;
  for p in select * from pessoas where parceiro and ativo loop
    select nv.valor into v from nf_valores nv where nv.pessoa_id = p.id and nv.periodo = per;
    select exists (select 1 from documentos_fiscais f where f.pessoa_id = p.id and f.competencia = per and f.tipo = 'nfse' and f.status <> 'recusada') into tem_nf;
    if not tem_nf then
      if v is null and d >= prazo - 1 then
        for g in select * from gerentes_do_dia(d) union select id from pessoas where papel = 'socio' and ativo loop
          perform notificar(g, 'nfsemval:' || p.id || ':' || per || ':' || d || ':' || g, 'Informe o valor da nota de ' || p.nome, 'Período de ' || nf_rotulo(per) || '. Sem o valor o barbeiro não consegue emitir.');
        end loop;
      elsif v is not null and d between prazo and prazo + 2 then
        perform notificar(p.id, 'nf:' || p.id || ':' || d, 'Nota fiscal de ' || nf_rotulo(per), 'Valor: R$ ' || brl(v) || '. Emita para a Hype e envie em Perfil.'); n := n + 1;
      end if;
      if v is not null and d >= prazo + 2 then
        for g in select * from gerentes_do_dia(d) union select id from pessoas where papel = 'socio' and ativo loop
          perform notificar(g, 'nfatr:' || p.id || ':' || per || ':' || g, 'Nota fiscal atrasada: ' || p.nome, 'A nota de ' || nf_rotulo(per) || ' venceu em ' || to_char(prazo, 'DD/MM') || '.');
        end loop;
      end if;
    end if;
    if rg.nf_exigir_das then
      select exists (select 1 from documentos_fiscais f where f.pessoa_id = p.id and f.competencia = comp and f.tipo = 'das' and f.status <> 'recusada') into tem_das;
      if not tem_das then
        if d = lim_das - 2 or d = lim_das then
          perform notificar(p.id, 'das:' || p.id || ':' || d, 'DAS do MEI de ' || to_char(comp, 'MM/YYYY'), 'O DAS vence dia 20. Pague e envie o comprovante em Perfil.');
        elsif d > lim_das then
          for g in select * from gerentes_do_dia(d) union select id from pessoas where papel = 'socio' and ativo loop
            perform notificar(g, 'dasatr:' || p.id || ':' || comp || ':' || g, 'DAS sem comprovante: ' || p.nome, 'O DAS de ' || to_char(comp, 'MM/YYYY') || ' venceu dia 20.');
          end loop;
        end if;
      end if;
    end if;
  end loop;
  return n;
end $function$
;
