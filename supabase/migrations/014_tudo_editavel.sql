-- Hype POP · 014 · tudo editável pelo admin (Victor)
-- 1. Textos da casa (cultura, horário, posições, reuniões, áreas) saem do código e vão para o banco.
-- 2. Agendamentos avulsos: checklist numa data e hora específicas (ex.: reunião de técnicas com horário variável).

/* ---------------- Textos da casa ---------------- */
create table if not exists config_textos (
  chave text primary key, valor jsonb not null, atualizado_em timestamptz not null default now(), por text references pessoas(id));
alter table config_textos enable row level security;
drop policy if exists ler on config_textos;
create policy ler on config_textos for select to authenticated using (sou_membro());
drop policy if exists socio_edita on config_textos;
create policy socio_edita on config_textos for all to authenticated using (sou_socio()) with check (sou_socio());

insert into config_textos (chave, valor) values
('cultura', $j${
  "missao": "Oferecer a cada cliente uma experiência de cuidado, relaxamento e renovação, com atenção a cada detalhe, domínio técnico e soluções reais para o seu cabelo, barba e pele.",
  "visao": "Ser a barbearia referência em qualidade e satisfação dos clientes na Zona Norte do Recife.",
  "valores": [
    ["Cooperação", "Jogamos juntos e cobrimos uns aos outros.", "Sem cliente na cadeira? Olhe ao redor."],
    ["Posicionamento", "Somos autoridade no que fazemos.", "Quem domina o assunto não precisa convencer: o cliente confia."],
    ["Atenção", "Fazemos o cliente se sentir cuidado.", "Lembrar o nome de todos os clientes atendidos."],
    ["Intenção", "Todo atendimento resolve algo.", "Não vendemos serviços. Resolvemos problemas."]]}$j$::jsonb),
('escala', $j${
  "horario": "Segunda a sexta, 09h às 20h. Sábado, 09h às 18h, e todos os barbeiros chegam às 08:50.",
  "posicoes": "Posição padrão: Magda no balcão do Lounge, Suellen no sofá da recepção.",
  "reunioes": [
    ["Segunda", "14:00 às 15:00", "Gestão", "Semanal"],
    ["Segunda", "19:00 às 19:30", "Alinhamento semanal", "Semanal"],
    ["Variável", "Agendada no app", "Técnicas com Robson", "Data e horário marcados a cada reunião"],
    ["Terça", "09:00 às 11:30", "One-on-ones de 30 min: Breno 09:00, Magda 09:30, Daniel 10:00, Heberth 10:30, Suellen 11:00", "Semanal"],
    ["Quarta", "09:00 às 10:00", "One-on-ones de 30 min: Durval 09:00, Jessica 09:30", "Semanal"]]}$j$::jsonb),
('areas', $j${"cultura":"Inegociáveis","abertura":"Abertura","recepcao":"Recepção","agenda":"Agenda","atendimento":"Atendimento",
  "barbeiros":"Barbeiros","vendas":"Preços e indicações","jornada":"Jornada do cliente","fechamento":"Fechamento","gestao":"Reuniões"}$j$::jsonb)
on conflict (chave) do nothing;

/* ---------------- Agendamentos avulsos ---------------- */
create table if not exists rotina_agendamentos (
  id serial primary key,
  rotina_id text not null references rotinas(id) on delete cascade,
  data date not null, inicio time not null, prazo time not null,
  pessoa_id text not null references pessoas(id),
  obs text, criado_por text references pessoas(id), em timestamptz not null default now(),
  check (prazo > inicio));
alter table rotina_agendamentos enable row level security;
drop policy if exists ler on rotina_agendamentos;
create policy ler on rotina_agendamentos for select to authenticated using (sou_membro());

alter table execucoes alter column janela_id drop not null;
alter table execucoes add column if not exists agendamento_id int references rotina_agendamentos(id) on delete cascade;
create unique index if not exists execucoes_agendamento on execucoes (agendamento_id);

-- Cria a execução de um agendamento (respeitando ausência; folga não impede, pois a data foi escolhida)
create or replace function gerar_agendamento(a rotina_agendamentos) returns int language plpgsql security definer set search_path = public as $$
declare p text;
begin
  if exists (select 1 from dias_fechados where data = a.data) then return 0; end if;
  p := quem_faz(a.pessoa_id, a.data, true);
  if p is null then return 0; end if;
  insert into execucoes (data, rotina_id, janela_id, pessoa_id, inicio, prazo, agendamento_id)
  values (a.data, a.rotina_id, null, p, (a.data + a.inicio) at time zone 'America/Recife', (a.data + a.prazo) at time zone 'America/Recife', a.id)
  on conflict (agendamento_id) do nothing;
  return case when found then 1 else 0 end;
end $$;

create or replace function agendar(rotina text, data date, inicio time, prazo time, pessoa text, obs text default null)
returns int language plpgsql security definer set search_path = public as $$
declare a rotina_agendamentos;
begin
  if not sou_socio() then raise exception 'Só os sócios agendam.'; end if;
  if prazo <= inicio then raise exception 'O prazo precisa ser depois do início.'; end if;
  insert into rotina_agendamentos (rotina_id, data, inicio, prazo, pessoa_id, obs, criado_por)
  values (rotina, data, inicio, prazo, pessoa, nullif(trim(obs), ''), eu()) returning * into a;
  -- Se for hoje (ou já passou do horário da geração), cria na hora
  if a.data <= hoje() then perform gerar_agendamento(a); end if;
  return a.id;
end $$;

create or replace function desagendar(ag int) returns void language plpgsql security definer set search_path = public as $$
begin
  if not sou_socio() then raise exception 'Só os sócios mexem na agenda.'; end if;
  if exists (select 1 from execucoes x where x.agendamento_id = ag and (x.concluida_em is not null or exists (select 1 from execucao_itens i where i.execucao_id = x.id))) then
    raise exception 'Este checklist já começou e não pode ser desmarcado.';
  end if;
  delete from rotina_agendamentos where id = ag;
end $$;

-- gerar_dia também cria os agendamentos do dia
do $$ declare def text; begin
  def := pg_get_functiondef('gerar_dia(date)'::regprocedure);
  if position('rotina_agendamentos' in def) = 0 then
    def := regexp_replace(def, '  return n;\s*end', '  for ag in select * from rotina_agendamentos where data = d loop n := n + gerar_agendamento(ag); end loop;
  return n;
end');
    def := replace(def, 'desloc int; resp text;', 'desloc int; resp text; ag rotina_agendamentos;');
    execute def;
  end if;
end $$;

-- Histórico e chave das execuções avulsas
create or replace function historico(dias int default 28)
returns table (data date, rotina_id text, pessoa_id text, chave text, previstos int, no_prazo int, atraso int, nao_feito int)
language sql stable security definer set search_path = public as $$
  select x.data, x.rotina_id, x.pessoa_id,
    x.rotina_id || '.' || x.pessoa_id || '.' || coalesce(to_char(j.inicio, 'HH24MI'), 'AVULSO'),
    1, (x.concluida_em is not null and x.concluida_em <= x.prazo)::int,
    (x.concluida_em is not null and x.concluida_em > x.prazo)::int, (x.concluida_em is null)::int
  from execucoes x left join rotina_janelas j on j.id = x.janela_id
  where sou_membro() and x.data < hoje() and x.data >= hoje() - historico.dias
    and (ve_tudo() or x.pessoa_id = eu())
$$;

-- Reunião de técnicas: sem horário fixo, passa a ser agendada
delete from rotina_janelas j where j.rotina_id = 'TEC'
  and not exists (select 1 from execucoes x where x.janela_id = j.id);
update rotinas set quinzenal = false where id = 'TEC';

do $$ declare f text; begin
  foreach f in array array['agendar(text,date,time,time,text,text)','desagendar(int)'] loop
    execute format('revoke execute on function %s from public, anon', f);
    execute format('grant execute on function %s to authenticated', f);
  end loop;
  revoke execute on function gerar_agendamento(rotina_agendamentos) from public, anon, authenticated;
end $$;
