-- Hype POP · 021 · registro de acessos do DEV e liga/desliga de recursos

/* Registro de acessos: toda vez que o DEV abre a visão de alguém, fica gravado */
create table if not exists dev_acessos (
  id bigserial primary key,
  dev_id text not null references pessoas(id),
  alvo_id text references pessoas(id),
  modo text not null,            -- 'ver', 'simulador'
  detalhe text,
  em timestamptz not null default now());
create index if not exists dev_acessos_em on dev_acessos (em desc);
alter table dev_acessos enable row level security;
drop policy if exists ler on dev_acessos;
create policy ler on dev_acessos for select to authenticated using (sou_socio() or sou_dev());

create or replace function dev_registrar_acesso(alvo text, modo text, detalhe text default null) returns void
language plpgsql security definer set search_path = public as $$
begin
  if not sou_dev() then raise exception 'Só o acesso DEV.'; end if;
  if modo not in ('ver', 'simulador') then raise exception 'Modo inválido.'; end if;
  -- uma linha por pessoa vista a cada 10 minutos, para não encher o registro ao trocar de tela
  if exists (select 1 from dev_acessos where dev_id = eu() and alvo_id is not distinct from nullif(alvo, '') and modo = dev_registrar_acesso.modo and em > now() - interval '10 min') then return; end if;
  insert into dev_acessos (dev_id, alvo_id, modo, detalhe) values (eu(), nullif(alvo, ''), modo, nullif(detalhe, ''));
end $$;

/* Liga/desliga de recursos: 'todos' (liberado), 'dev' (só o DEV vê) ou 'desligado' */
create table if not exists recursos (
  chave text primary key,
  nome text not null,
  descricao text,
  estado text not null default 'todos' check (estado in ('todos', 'dev', 'desligado')),
  atualizado_em timestamptz not null default now(),
  por text references pessoas(id));
alter table recursos enable row level security;
drop policy if exists ler on recursos;
create policy ler on recursos for select to authenticated using (sou_membro());
drop policy if exists dev_altera on recursos;
create policy dev_altera on recursos for update to authenticated using (sou_dev()) with check (sou_dev());

insert into recursos (chave, nome, descricao) values
  ('treino', 'Checklist de treino', 'Cartão "Primeira vez no app?" e o checklist de treino local.'),
  ('lote', 'Conferência em lote', 'Botão da gerente para conferir vários checklists com as fotos lado a lado.'),
  ('reposicao', 'Reposição de material', 'Pedido de material no Registrar e no "Não deu", e a lista da gerente.'),
  ('cliente', 'Elogio e reclamação de cliente', 'Opção "Cliente elogiou ou reclamou" no Registrar.'),
  ('pauta', 'Pauta do alinhamento', 'Pauta automática da reunião de segunda (gerente e Relatórios).'),
  ('modo_tv', 'Modo TV', 'Apresentação da semana em tela cheia (só o Victor).')
on conflict (chave) do nothing;

do $$ begin
  revoke execute on function dev_registrar_acesso(text, text, text) from public, anon;
  grant execute on function dev_registrar_acesso(text, text, text) to authenticated;
end $$;
