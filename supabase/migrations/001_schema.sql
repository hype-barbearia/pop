-- Hype POP · 001 · tabelas, segurança (RLS) e funções
-- Fuso da barbearia: America/Recife (UTC-3, sem horário de verão)

create extension if not exists pgcrypto;

/* ---------------- Tabelas ---------------- */
create table if not exists pessoas (
  id text primary key,
  nome text not null,
  email text unique,
  papel text not null check (papel in ('socio','gerente','barbeiro','atendente')),
  rotulo text,
  turno text,
  folga smallint check (folga between 0 and 6),
  socio boolean not null default false,
  cor smallint not null default 30,
  ativo boolean not null default true,
  ordem int not null default 0,
  criado_em timestamptz not null default now()
);

create table if not exists pops (
  id text primary key,
  titulo text not null,
  area text not null,
  cargos text[] not null default '{todos}',
  quem text, dono text, frequencia text, objetivo text,
  materiais jsonb not null default '[]', passos jsonb not null default '[]',
  qualidade jsonb not null default '[]', erros jsonb not null default '[]',
  tabelas jsonb, guia jsonb,
  versao int not null default 1,
  atualizado text, aprovado_por text,
  ordem int not null default 0,
  ativo boolean not null default true
);

create table if not exists pop_leituras (
  pop_id text references pops(id) on delete cascade,
  pessoa_id text references pessoas(id) on delete cascade,
  versao int not null,
  assinado_em timestamptz not null default now(),
  primary key (pop_id, pessoa_id, versao)
);

create table if not exists rotinas (
  id text primary key,
  titulo text not null,
  pop_id text references pops(id),
  tipo text not null default 'check' check (tipo in ('check','ronda')),
  conferir boolean not null default false,
  dias smallint[] not null default '{1,2,3,4,5,6}',
  cada text[],          -- lista fixa de pessoas (ex.: barbeiros de abertura)
  cada_papel text,      -- todos os presentes de um papel (ex.: barbeiro)
  junto text[],         -- quem divide a tarefa com o responsável
  quinzenal boolean not null default false,
  ativo boolean not null default true,
  ordem int not null default 0
);

create table if not exists rotina_janelas (
  id serial primary key,
  rotina_id text not null references rotinas(id) on delete cascade,
  inicio time not null,
  prazo time not null,
  responsavel text references pessoas(id)
);

create table if not exists rotina_itens (
  id text primary key,
  rotina_id text not null references rotinas(id) on delete cascade,
  ordem int not null,
  texto text not null,
  foto boolean not null default false,
  critico boolean not null default false,
  ativo boolean not null default true
);

create table if not exists execucoes (
  id uuid primary key default gen_random_uuid(),
  data date not null,
  rotina_id text not null references rotinas(id),
  janela_id int not null references rotina_janelas(id) on delete cascade,
  pessoa_id text not null references pessoas(id),
  inicio timestamptz not null,
  prazo timestamptz not null,
  concluida_em timestamptz,
  refazer_em timestamptz, refazer_obs text,
  conferido_em timestamptz, conferido_resultado text check (conferido_resultado in ('ok','ressalva')), conferido_obs text, conferido_por text references pessoas(id),
  unique (data, janela_id, pessoa_id)
);
create index if not exists execucoes_data on execucoes (data);

create table if not exists execucao_itens (
  execucao_id uuid references execucoes(id) on delete cascade,
  item_id text references rotina_itens(id),
  ok boolean not null,
  marcado_em timestamptz not null default now(),
  foto_path text, obs text,
  por text references pessoas(id),
  primary key (execucao_id, item_id)
);

create table if not exists cobrancas (
  id serial primary key,
  execucao_id uuid not null references execucoes(id) on delete cascade,
  por text references pessoas(id),
  em timestamptz not null default now()
);

create table if not exists ocorrencias (
  id serial primary key,
  data date not null,
  em timestamptz not null default now(),
  pessoa_id text references pessoas(id),
  origem text not null,
  execucao_id uuid references execucoes(id) on delete set null,
  pop_id text references pops(id),
  titulo text not null,
  descricao text,
  status text not null default 'aberta' check (status in ('aberta','tratamento','resolvida')),
  criado_por text references pessoas(id)
);
create table if not exists ocorrencia_acoes (
  id serial primary key,
  ocorrencia_id int not null references ocorrencias(id) on delete cascade,
  por text references pessoas(id),
  em timestamptz not null default now(),
  texto text not null
);

create table if not exists lembretes (
  id serial primary key,
  hora time not null,
  texto text not null,
  dias smallint[] not null default '{1,2,3,4,5,6}',
  ativo boolean not null default true
);
create table if not exists lembretes_feitos (
  lembrete_id int references lembretes(id) on delete cascade,
  data date not null,
  em timestamptz not null default now(),
  por text references pessoas(id),
  primary key (lembrete_id, data)
);

create table if not exists regras (
  id int primary key default 1 check (id = 1),
  antes int not null default 10,
  escalar int not null default 30,
  conferir int not null default 30,
  meta numeric not null default .9,
  rondas_surpresa boolean not null default true,
  resumo time not null default '21:00'
);

/* ---------------- Quem sou eu ---------------- */
create or replace function hoje() returns date language sql stable set search_path = public as
$$ select (now() at time zone 'America/Recife')::date $$;

create or replace function eu() returns text language sql stable security definer set search_path = public as
$$ select id from pessoas where ativo and lower(email) = lower(auth.jwt() ->> 'email') limit 1 $$;

create or replace function sou_membro() returns boolean language sql stable security definer set search_path = public as
$$ select eu() is not null $$;

create or replace function sou_socio() returns boolean language sql stable security definer set search_path = public as
$$ select exists (select 1 from pessoas where id = eu() and (papel = 'socio' or socio)) $$;

create or replace function sou_gestor() returns boolean language sql stable security definer set search_path = public as
$$ select exists (select 1 from pessoas where id = eu() and (papel in ('socio','gerente') or socio)) $$;

create or replace function pode_ver_execucao(e uuid) returns boolean language sql stable security definer set search_path = public as
$$ select sou_gestor() or exists (
     select 1 from execucoes x join rotinas r on r.id = x.rotina_id
     where x.id = e and (x.pessoa_id = eu() or eu() = any(coalesce(r.junto, '{}')))) $$;

/* ---------------- RLS ---------------- */
alter table pessoas enable row level security;
alter table pops enable row level security;
alter table pop_leituras enable row level security;
alter table rotinas enable row level security;
alter table rotina_janelas enable row level security;
alter table rotina_itens enable row level security;
alter table execucoes enable row level security;
alter table execucao_itens enable row level security;
alter table cobrancas enable row level security;
alter table ocorrencias enable row level security;
alter table ocorrencia_acoes enable row level security;
alter table lembretes enable row level security;
alter table lembretes_feitos enable row level security;
alter table regras enable row level security;

-- Leitura para quem é da equipe; edição de configuração só para sócios
do $$ declare t text; begin
  foreach t in array array['pessoas','pops','rotinas','rotina_janelas','rotina_itens','lembretes','regras','pop_leituras'] loop
    execute format('drop policy if exists ler on %I', t);
    execute format('create policy ler on %I for select to authenticated using (sou_membro())', t);
  end loop;
  foreach t in array array['pessoas','pops','rotinas','rotina_janelas','rotina_itens','lembretes','regras'] loop
    execute format('drop policy if exists socio_edita on %I', t);
    execute format('create policy socio_edita on %I for all to authenticated using (sou_socio()) with check (sou_socio())', t);
  end loop;
end $$;

drop policy if exists ler on execucoes;
create policy ler on execucoes for select to authenticated using (pode_ver_execucao(id));
drop policy if exists ler on execucao_itens;
create policy ler on execucao_itens for select to authenticated using (pode_ver_execucao(execucao_id));
drop policy if exists ler on cobrancas;
create policy ler on cobrancas for select to authenticated using (pode_ver_execucao(execucao_id));
drop policy if exists ler on ocorrencias;
create policy ler on ocorrencias for select to authenticated using (sou_gestor() or pessoa_id = eu());
drop policy if exists ler on ocorrencia_acoes;
create policy ler on ocorrencia_acoes for select to authenticated using (exists (select 1 from ocorrencias o where o.id = ocorrencia_id and (sou_gestor() or o.pessoa_id = eu())));
drop policy if exists ler on lembretes_feitos;
create policy ler on lembretes_feitos for select to authenticated using (sou_gestor());
-- Escritas da operação passam pelas funções abaixo (security definer), não por insert direto.

/* ---------------- Gerar o dia ---------------- */
create or replace function gerar_dia(d date) returns int language plpgsql security definer set search_path = public as $$
declare
  dow int := extract(dow from d);
  r rotinas; j rotina_janelas; quem text[]; p text; n int := 0; desloc int;
  surpresa boolean := coalesce((select rondas_surpresa from regras where id = 1), false);
begin
  if dow = 0 then return 0; end if;
  for r in select * from rotinas where ativo and dow = any(dias) loop
    if r.quinzenal and ((d - date '2026-10-19') % 14) <> 0 then continue; end if;
    for j in select * from rotina_janelas where rotina_id = r.id loop
      if r.cada is not null then
        select array_agg(id) into quem from pessoas where id = any(r.cada) and ativo and coalesce(folga, -1) <> dow;
      elsif r.cada_papel is not null then
        select array_agg(id order by ordem) into quem from pessoas where papel = r.cada_papel and ativo and coalesce(folga, -1) <> dow;
      else
        quem := array[j.responsavel];
      end if;
      -- Ronda surpresa: horário sorteado até 60 min antes ou depois do previsto
      desloc := case when r.tipo = 'ronda' and surpresa then (floor(random() * 121) - 60)::int else 0 end;
      foreach p in array coalesce(quem, '{}') loop
        continue when p is null;
        insert into execucoes (data, rotina_id, janela_id, pessoa_id, inicio, prazo)
        values (d, r.id, j.id, p,
          ((d + j.inicio) at time zone 'America/Recife') + make_interval(mins => desloc),
          ((d + j.prazo) at time zone 'America/Recife') + make_interval(mins => desloc))
        on conflict (data, janela_id, pessoa_id) do nothing;
        if found then n := n + 1; end if;
      end loop;
    end loop;
  end loop;
  return n;
end $$;

create or replace function garantir_dia() returns int language plpgsql security definer set search_path = public as $$
begin
  if not sou_membro() then raise exception 'Acesso só para a equipe da Hype.'; end if;
  return gerar_dia(hoje());
end $$;

/* ---------------- Ações da operação ---------------- */
create or replace function pode_executar(e uuid) returns boolean language sql stable security definer set search_path = public as
$$ select exists (select 1 from execucoes x join rotinas r on r.id = x.rotina_id
     where x.id = e and (x.pessoa_id = eu() or eu() = any(coalesce(r.junto, '{}')))) $$;

create or replace function marcar_item(e uuid, item text, feito boolean, nota text default null, foto text default null)
returns void language plpgsql security definer set search_path = public as $$
declare x execucoes; r rotinas; it rotina_itens;
begin
  if not pode_executar(e) then raise exception 'Este checklist não é seu.'; end if;
  select * into x from execucoes where id = e;
  if x.concluida_em is not null then raise exception 'Checklist já concluído.'; end if;
  select * into it from rotina_itens where id = item and rotina_id = x.rotina_id;
  if it.id is null then raise exception 'Item inválido.'; end if;
  if feito and it.foto and foto is null then raise exception 'Este item precisa de foto.'; end if;
  if not feito and coalesce(trim(nota), '') = '' then raise exception 'Explique o motivo.'; end if;
  insert into execucao_itens (execucao_id, item_id, ok, marcado_em, foto_path, obs, por)
  values (e, item, feito, now(), foto, nota, eu())
  on conflict (execucao_id, item_id) do update set ok = excluded.ok, marcado_em = excluded.marcado_em, foto_path = excluded.foto_path, obs = excluded.obs, por = excluded.por;
  if not feito then
    select * into r from rotinas where id = x.rotina_id;
    insert into ocorrencias (data, pessoa_id, origem, execucao_id, pop_id, titulo, descricao, criado_por)
    values (x.data, case when r.tipo = 'ronda' then null else x.pessoa_id end,
      case when r.tipo = 'ronda' then 'Ronda da gerente' else 'Checklist' end, e, r.pop_id,
      it.texto || case when r.tipo = 'ronda' then ': não conforme' else ': não feito' end, nota, eu());
  end if;
end $$;

create or replace function desmarcar_item(e uuid, item text) returns void language plpgsql security definer set search_path = public as $$
begin
  if not pode_executar(e) then raise exception 'Este checklist não é seu.'; end if;
  if (select concluida_em from execucoes where id = e) is not null then raise exception 'Checklist já concluído.'; end if;
  delete from execucao_itens where execucao_id = e and item_id = item;
end $$;

create or replace function concluir(e uuid) returns void language plpgsql security definer set search_path = public as $$
declare faltam int;
begin
  if not pode_executar(e) then raise exception 'Este checklist não é seu.'; end if;
  select count(*) into faltam from rotina_itens i join execucoes x on x.rotina_id = i.rotina_id
   where x.id = e and i.ativo and not exists (select 1 from execucao_itens ei where ei.execucao_id = e and ei.item_id = i.id);
  if faltam > 0 then raise exception 'Faltam % itens.', faltam; end if;
  update execucoes set concluida_em = now(), refazer_em = null, refazer_obs = null where id = e and concluida_em is null;
end $$;

create or replace function conferir(e uuid, resultado text, nota text default null) returns void language plpgsql security definer set search_path = public as $$
begin
  if not sou_gestor() then raise exception 'Só a gerente ou os sócios conferem.'; end if;
  if resultado not in ('ok','ressalva','refazer') then raise exception 'Resultado inválido.'; end if;
  if resultado <> 'ok' and coalesce(trim(nota), '') = '' then raise exception 'Escreva a observação.'; end if;
  if resultado = 'refazer' then
    update execucoes set concluida_em = null, refazer_em = now(), refazer_obs = nota, conferido_em = null, conferido_resultado = null where id = e;
    delete from execucao_itens where execucao_id = e and foto_path is not null;
  else
    update execucoes set conferido_em = now(), conferido_resultado = resultado, conferido_obs = nota, conferido_por = eu() where id = e and concluida_em is not null;
  end if;
end $$;

create or replace function cobrar(e uuid) returns void language plpgsql security definer set search_path = public as $$
begin
  if not sou_gestor() then raise exception 'Só a gerente ou os sócios cobram.'; end if;
  insert into cobrancas (execucao_id, por) values (e, eu());
end $$;

create or replace function abrir_ocorrencia(titulo text, pessoa text, origem text, descricao text, pop text default null)
returns int language plpgsql security definer set search_path = public as $$
declare novo int;
begin
  if not sou_gestor() then raise exception 'Só a gerente ou os sócios registram ocorrência.'; end if;
  insert into ocorrencias (data, pessoa_id, origem, pop_id, titulo, descricao, criado_por)
  values (hoje(), nullif(pessoa, ''), origem, pop, titulo, descricao, eu()) returning id into novo;
  return novo;
end $$;

create or replace function registrar_acao(oc int, texto text, resolver boolean default false) returns void language plpgsql security definer set search_path = public as $$
begin
  if not sou_gestor() then raise exception 'Só a gerente ou os sócios tratam ocorrências.'; end if;
  if coalesce(trim(texto), '') <> '' then insert into ocorrencia_acoes (ocorrencia_id, por, texto) values (oc, eu(), texto); end if;
  update ocorrencias set status = case when resolver then 'resolvida' else 'tratamento' end where id = oc;
end $$;

create or replace function assinar_pop(pop text) returns void language plpgsql security definer set search_path = public as $$
begin
  if not sou_membro() then raise exception 'Acesso só para a equipe da Hype.'; end if;
  insert into pop_leituras (pop_id, pessoa_id, versao) select id, eu(), versao from pops where id = pop on conflict do nothing;
end $$;

create or replace function lembrete_feito(l int) returns void language plpgsql security definer set search_path = public as $$
begin
  if not sou_gestor() then raise exception 'Só a gerente marca lembretes.'; end if;
  insert into lembretes_feitos (lembrete_id, data, por) values (l, hoje(), eu()) on conflict do nothing;
end $$;

/* ---------------- Histórico (dias anteriores) ---------------- */
create or replace function historico(dias int default 28)
returns table (data date, rotina_id text, pessoa_id text, chave text, previstos int, no_prazo int, atraso int, nao_feito int)
language sql stable security definer set search_path = public as $$
  select x.data, x.rotina_id, x.pessoa_id,
    x.rotina_id || '.' || x.pessoa_id || '.' || to_char(j.inicio, 'HH24MI'),
    1, (x.concluida_em is not null and x.concluida_em <= x.prazo)::int,
    (x.concluida_em is not null and x.concluida_em > x.prazo)::int, (x.concluida_em is null)::int
  from execucoes x join rotina_janelas j on j.id = x.janela_id
  where sou_membro() and x.data < hoje() and x.data >= hoje() - dias
    and (sou_gestor() or x.pessoa_id = eu())
$$;

/* ---------------- Permissões das funções ---------------- */
revoke execute on function gerar_dia(date) from public, anon, authenticated;
do $$ declare f text; begin
  foreach f in array array['garantir_dia()','marcar_item(uuid,text,boolean,text,text)','desmarcar_item(uuid,text)','concluir(uuid)','conferir(uuid,text,text)',
    'cobrar(uuid)','abrir_ocorrencia(text,text,text,text,text)','registrar_acao(int,text,boolean)','assinar_pop(text)','lembrete_feito(int)','historico(int)'] loop
    execute format('revoke execute on function %s from public, anon', f);
    execute format('grant execute on function %s to authenticated', f);
  end loop;
end $$;

/* ---------------- Fotos ---------------- */
insert into storage.buckets (id, name, public) values ('fotos', 'fotos', false) on conflict (id) do nothing;
drop policy if exists fotos_ler on storage.objects;
create policy fotos_ler on storage.objects for select to authenticated using (bucket_id = 'fotos' and sou_membro());
drop policy if exists fotos_enviar on storage.objects;
create policy fotos_enviar on storage.objects for insert to authenticated with check (bucket_id = 'fotos' and sou_membro());

/* ---------------- Tempo real ---------------- */
do $$ declare t text; begin
  foreach t in array array['execucoes','execucao_itens','cobrancas','ocorrencias','ocorrencia_acoes','lembretes_feitos','pop_leituras'] loop
    if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and tablename = t) then
      execute format('alter publication supabase_realtime add table %I', t);
    end if;
  end loop;
end $$;
