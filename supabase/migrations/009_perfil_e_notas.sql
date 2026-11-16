-- Hype POP · 009 · e-mails da equipe, perfil e notas fiscais do Salão-Parceiro (Lei 13.352/2016)

/* ---------------- Pessoas: nome completo, e-mail e quem é profissional-parceiro ---------------- */
alter table pessoas add column if not exists nome_completo text;
alter table pessoas add column if not exists parceiro boolean not null default false;

update pessoas p set email = v.email, nome_completo = v.nome, parceiro = v.parceiro
from (values
  ('victor',  'victor@hypebarbearia.com',           'Victor Eustáquio',  false),
  ('robson',  'robson@hypebarbearia.com',           'Robson Conceição',  false),
  ('jessica', 'jessica.silva@hypebarbearia.com',    'Jessica Silva',     false),
  ('breno',   'breno.sales@hypebarbearia.com',      'Breno Sales',       true),
  ('daniel',  'daniel.nunes@hypebarbearia.com',     'Daniel Nunes',      true),
  ('durval',  'durval.rodrigues@hypebarbearia.com', 'Durval Rodrigues',  true),
  ('heberth', 'heberth.henrique@hypebarbearia.com', 'Heberth Henrique',  true),
  ('magda',   'magda.cristina@hypebarbearia.com',   'Magda Cristina',    false),
  ('suellen', 'suellen.silva@hypebarbearia.com',    'Suellen Silva',     false)
) v(id, email, nome, parceiro) where p.id = v.id;

/* ---------------- Regras das notas ---------------- */
alter table regras add column if not exists nf_dia_limite int not null default 5;
alter table regras add column if not exists nf_exigir_das boolean not null default true;
alter table regras add column if not exists nf_cnpj text;
alter table regras add column if not exists nf_razao text;
alter table regras add column if not exists nf_descricao text not null default
  'Serviços de barbearia prestados em regime de parceria (Lei 13.352/2016), cota-parte do profissional-parceiro referente a {mes}.';

/* ---------------- Documentos fiscais ---------------- */
create table if not exists documentos_fiscais (
  id serial primary key,
  pessoa_id text not null references pessoas(id),
  competencia date not null,                       -- primeiro dia do mês de referência
  tipo text not null check (tipo in ('nfse','das')),
  numero text, valor numeric(12,2),
  arquivo_path text not null,
  enviado_em timestamptz not null default now(),
  status text not null default 'enviada' check (status in ('enviada','aceita','recusada')),
  obs text, revisado_por text references pessoas(id), revisado_em timestamptz
);
create index if not exists documentos_fiscais_comp on documentos_fiscais (competencia, pessoa_id);
alter table documentos_fiscais enable row level security;
drop policy if exists ler on documentos_fiscais;
create policy ler on documentos_fiscais for select to authenticated using (pessoa_id = eu() or ve_tudo());

create or replace function enviar_documento(competencia date, tipo text, numero text, valor numeric, arquivo text)
returns int language plpgsql security definer set search_path = public as $$
declare novo int; quem pessoas; mes text; g text;
begin
  select * into quem from pessoas where id = eu() and ativo;
  if quem.id is null then raise exception 'Acesso só para a equipe da Hype.'; end if;
  if not quem.parceiro then raise exception 'Só profissionais-parceiros enviam notas fiscais.'; end if;
  if arquivo is null or split_part(arquivo, '/', 1) <> quem.id then raise exception 'Arquivo inválido.'; end if;
  insert into documentos_fiscais (pessoa_id, competencia, tipo, numero, valor, arquivo_path)
  values (quem.id, date_trunc('month', competencia)::date, tipo, nullif(trim(numero), ''), valor, arquivo) returning id into novo;
  mes := to_char(date_trunc('month', competencia), 'MM/YYYY');
  for g in select * from gerentes_do_dia(hoje()) union select id from pessoas where papel = 'socio' and ativo loop
    perform notificar(g, 'doc:' || novo || ':' || g,
      quem.nome || ' enviou ' || case when tipo = 'nfse' then 'a nota fiscal' else 'o comprovante do DAS' end || ' de ' || mes,
      'Abra Notas fiscais no app para conferir.');
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
    case when d.tipo = 'nfse' then 'nota fiscal' else 'DAS' end || ' de ' || to_char(d.competencia, 'MM/YYYY'),
    coalesce(nota, 'Tudo certo.'));
end $$;

-- Lembretes do mês: roda uma vez por dia (10:05 em Recife)
create or replace function lembretes_fiscais() returns int language plpgsql security definer set search_path = public as $$
declare
  d date := hoje(); rg regras; comp date := (date_trunc('month', hoje()) - interval '1 month')::date;
  lim date; lim_das date; p pessoas; tem_nf boolean; tem_das boolean; g text; mes text := to_char((date_trunc('month', hoje()) - interval '1 month')::date, 'MM/YYYY'); n int := 0;
begin
  select * into rg from regras where id = 1;
  lim := least(make_date(extract(year from d)::int, extract(month from d)::int, greatest(1, rg.nf_dia_limite)), (date_trunc('month', d) + interval '1 month - 1 day')::date);
  lim_das := make_date(extract(year from d)::int, extract(month from d)::int, 20);
  for p in select * from pessoas where parceiro and ativo loop
    select exists (select 1 from documentos_fiscais f where f.pessoa_id = p.id and f.competencia = comp and f.tipo = 'nfse' and f.status <> 'recusada') into tem_nf;
    select exists (select 1 from documentos_fiscais f where f.pessoa_id = p.id and f.competencia = comp and f.tipo = 'das' and f.status <> 'recusada') into tem_das;
    if not tem_nf then
      if extract(day from d) = 1 or d = lim - 2 or d = lim then
        perform notificar(p.id, 'nf:' || p.id || ':' || d, 'Nota fiscal de ' || mes, 'Emita a NFS-e para a Hype e envie em Perfil até ' || to_char(lim, 'DD/MM') || '.'); n := n + 1;
      elsif d > lim then
        for g in select * from gerentes_do_dia(d) union select id from pessoas where papel = 'socio' and ativo loop
          perform notificar(g, 'nfatr:' || p.id || ':' || comp || ':' || g, 'Nota fiscal atrasada: ' || p.nome, 'A NFS-e de ' || mes || ' venceu em ' || to_char(lim, 'DD/MM') || '.');
        end loop;
        perform notificar(p.id, 'nfatr:' || p.id || ':' || d, 'Sua nota fiscal de ' || mes || ' está atrasada', 'Envie em Perfil assim que emitir.');
      end if;
    end if;
    if rg.nf_exigir_das and not tem_das then
      if d = lim_das - 2 or d = lim_das then
        perform notificar(p.id, 'das:' || p.id || ':' || d, 'DAS do MEI de ' || mes, 'O DAS vence dia 20. Pague e envie o comprovante em Perfil.');
      elsif d > lim_das then
        for g in select * from gerentes_do_dia(d) union select id from pessoas where papel = 'socio' and ativo loop
          perform notificar(g, 'dasatr:' || p.id || ':' || comp || ':' || g, 'DAS sem comprovante: ' || p.nome, 'O DAS de ' || mes || ' venceu dia 20.');
        end loop;
      end if;
    end if;
  end loop;
  return n;
end $$;

do $$ declare f text; begin
  foreach f in array array['enviar_documento(date,text,text,numeric,text)','revisar_documento(int,text,text)'] loop
    execute format('revoke execute on function %s from public, anon', f);
    execute format('grant execute on function %s to authenticated', f);
  end loop;
  revoke execute on function lembretes_fiscais() from public, anon, authenticated;
end $$;

select cron.unschedule(jobid) from cron.job where jobname = 'hype_pop_fiscal';
select cron.schedule('hype_pop_fiscal', '5 13 * * *', $$ select public.lembretes_fiscais(); select public.disparar_envio('enviar'); $$);

/* ---------------- Arquivos das notas (privado, uma pasta por pessoa) ---------------- */
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('documentos', 'documentos', false, 10485760, array['application/pdf','text/xml','application/xml','image/jpeg','image/png','image/heic','image/webp'])
on conflict (id) do nothing;
drop policy if exists documentos_enviar on storage.objects;
create policy documentos_enviar on storage.objects for insert to authenticated
  with check (bucket_id = 'documentos' and (storage.foldername(name))[1] = eu());
drop policy if exists documentos_ler on storage.objects;
create policy documentos_ler on storage.objects for select to authenticated
  using (bucket_id = 'documentos' and ((storage.foldername(name))[1] = eu() or ve_tudo()));

do $$ begin
  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and tablename = 'documentos_fiscais') then
    alter publication supabase_realtime add table documentos_fiscais;
  end if;
end $$;
