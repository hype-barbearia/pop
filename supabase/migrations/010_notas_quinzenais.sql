-- Hype POP · 010 · notas fiscais quinzenais com valor definido pela gestão
-- 1ª quinzena (dias 1 a 15): nota até o dia 16. 2ª quinzena (16 ao fim do mês): nota até o dia 1º do mês seguinte.
-- O período da nota é guardado pela data de início (dia 1 ou dia 16).

update regras set nf_descricao = 'Serviços de barbearia prestados em regime de parceria (Lei 13.352/2016), cota-parte do profissional-parceiro referente a {periodo}.'
where id = 1 and nf_descricao like '%{mes}%';

create or replace function brl(v numeric) returns text language sql immutable as
$$ select translate(to_char(v, 'FM999,999,990.00'), ',.', '.,') $$;
create or replace function nf_prazo(p date) returns date language sql immutable as
$$ select case when extract(day from p) = 1 then p + 15 else (date_trunc('month', p) + interval '1 month')::date end $$;
create or replace function nf_fim(p date) returns date language sql immutable as
$$ select case when extract(day from p) = 1 then p + 14 else (date_trunc('month', p) + interval '1 month - 1 day')::date end $$;
create or replace function nf_rotulo(p date) returns text language sql immutable as
$$ select to_char(p, 'DD/MM') || ' a ' || to_char(nf_fim(p), 'DD/MM/YYYY') $$;
-- Período que vence agora: o que acabou de terminar
create or replace function nf_periodo_atual(d date) returns date language sql immutable as
$$ select case when extract(day from d) >= 16 then date_trunc('month', d)::date else (date_trunc('month', d) - interval '1 month' + interval '15 days')::date end $$;

create table if not exists nf_valores (
  pessoa_id text references pessoas(id), periodo date check (extract(day from periodo) in (1, 16)),
  valor numeric(12,2) not null check (valor >= 0), definido_por text references pessoas(id), em timestamptz not null default now(),
  primary key (pessoa_id, periodo));
alter table nf_valores enable row level security;
drop policy if exists ler on nf_valores;
create policy ler on nf_valores for select to authenticated using (pessoa_id = eu() or ve_tudo());

create or replace function definir_valor_nf(pessoa text, periodo date, valor numeric) returns void
language plpgsql security definer set search_path = public as $$
begin
  if not sou_gestor() then raise exception 'Só a gerente ou os sócios definem o valor da nota.'; end if;
  if extract(day from periodo) not in (1, 16) then raise exception 'Período inválido.'; end if;
  if valor is null or valor < 0 then raise exception 'Informe um valor válido.'; end if;
  insert into nf_valores (pessoa_id, periodo, valor, definido_por) values (pessoa, periodo, valor, eu())
  on conflict on constraint nf_valores_pkey do update set valor = excluded.valor, definido_por = excluded.definido_por, em = now();
  perform notificar(pessoa, 'nfval:' || pessoa || ':' || periodo || ':' || valor,
    'Valor da sua nota: R$ ' || brl(valor),
    'Período de ' || nf_rotulo(periodo) || '. Emita a NFS-e para a Hype e envie em Perfil até ' || to_char(nf_prazo(periodo), 'DD/MM') || '.');
end $$;

create or replace function enviar_documento(competencia date, tipo text, numero text, valor numeric, arquivo text)
returns int language plpgsql security definer set search_path = public as $$
declare novo int; quem pessoas; per date; v numeric; rot text; g text;
begin
  select * into quem from pessoas where id = eu() and ativo;
  if quem.id is null then raise exception 'Acesso só para a equipe da Hype.'; end if;
  if not quem.parceiro then raise exception 'Só profissionais-parceiros enviam notas fiscais.'; end if;
  if arquivo is null or split_part(arquivo, '/', 1) <> quem.id then raise exception 'Arquivo inválido.'; end if;
  if tipo = 'nfse' then
    per := competencia;
    if extract(day from per) not in (1, 16) then raise exception 'Período inválido.'; end if;
    select nv.valor into v from nf_valores nv where nv.pessoa_id = quem.id and nv.periodo = per;
    if v is null then raise exception 'A gestão ainda não informou o valor desta nota.'; end if;
    rot := 'a nota fiscal de ' || nf_rotulo(per);
  else
    per := date_trunc('month', competencia)::date; v := null;
    rot := 'o comprovante do DAS de ' || to_char(per, 'MM/YYYY');
  end if;
  insert into documentos_fiscais (pessoa_id, competencia, tipo, numero, valor, arquivo_path)
  values (quem.id, per, tipo, nullif(trim(numero), ''), v, arquivo) returning id into novo;
  for g in select * from gerentes_do_dia(hoje()) union select id from pessoas where papel = 'socio' and ativo loop
    perform notificar(g, 'doc:' || novo || ':' || g, quem.nome || ' enviou ' || rot, 'Abra Notas fiscais no app para conferir.');
  end loop;
  return novo;
end $$;

create or replace function revisar_documento(doc int, resultado text, nota text default null)
returns void language plpgsql security definer set search_path = public as $$
declare d documentos_fiscais;
begin
  if not sou_gestor() then raise exception 'Só a gerente ou os sócios conferem notas fiscais.'; end if;
  if resultado not in ('aceita','recusada') then raise exception 'Resultado inválido.'; end if;
  if resultado = 'recusada' and coalesce(trim(nota), '') = '' then raise exception 'Explique o motivo da recusa.'; end if;
  update documentos_fiscais set status = resultado, obs = nota, revisado_por = eu(), revisado_em = now() where id = doc returning * into d;
  perform notificar(d.pessoa_id, 'docrev:' || doc || ':' || resultado,
    case when resultado = 'aceita' then 'Documento aceito: ' else 'Documento recusado: ' end ||
    case when d.tipo = 'nfse' then 'nota de ' || nf_rotulo(d.competencia) else 'DAS de ' || to_char(d.competencia, 'MM/YYYY') end,
    coalesce(nota, 'Tudo certo.'));
end $$;

-- Roda todo dia às 10:05 em Recife
create or replace function lembretes_fiscais() returns int language plpgsql security definer set search_path = public as $$
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
        -- A gestão ainda não informou o valor
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
end $$;

do $$ begin
  revoke execute on function definir_valor_nf(text, date, numeric) from public, anon;
  grant execute on function definir_valor_nf(text, date, numeric) to authenticated;
  revoke execute on function lembretes_fiscais() from public, anon, authenticated;
  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and tablename = 'nf_valores') then
    alter publication supabase_realtime add table nf_valores;
  end if;
end $$;
