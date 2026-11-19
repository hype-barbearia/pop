-- Hype POP · 024 · tipos de atividade e cultura por exceção
-- Separa o que é tarefa recorrente do que é comportamento:
-- 1. Reunião vira um tipo próprio (presença e combinados), não um checklist de "Feito / Não deu".
-- 2. Cada item pode ter uma instrução ("como fazer"), que a pessoa consulta e não marca.
-- 3. Cultura: padrões de comportamento da casa, fora dos checklists. A gerência registra só a exceção
--    (um desvio ou um destaque), ligada à pessoa. Os itens de comportamento saem da ronda.

/* ---------- 1. Reunião ---------- */
alter table rotinas drop constraint if exists rotinas_tipo_check;
alter table rotinas add constraint rotinas_tipo_check check (tipo in ('check', 'ronda', 'reuniao'));
update rotinas set tipo = 'reuniao' where id in ('GES', 'ALI', 'TEC', 'O1T', 'O1Q');

alter table execucoes add column if not exists notas text;

create or replace function anotar_reuniao(e uuid, texto text) returns void
language plpgsql security definer set search_path = public as $$
declare x execucoes; r rotinas;
begin
  select * into x from execucoes where id = e;
  if x.id is null then raise exception 'Reunião não encontrada.'; end if;
  select * into r from rotinas where id = x.rotina_id;
  if r.tipo <> 'reuniao' then raise exception 'Só reuniões têm combinados.'; end if;
  if not (x.pessoa_id = eu() or eu() = any(coalesce(r.junto, '{}')) or sou_gestor()) then raise exception 'Só quem conduz a reunião ou a gestão anota os combinados.'; end if;
  update execucoes set notas = nullif(trim(texto), '') where id = e;
end $$;
revoke execute on function anotar_reuniao(uuid, text) from public, anon;
grant execute on function anotar_reuniao(uuid, text) to authenticated;

/* ---------- 2. Instrução por item ---------- */
alter table rotina_itens add column if not exists instrucao text;

/* ---------- 3. Cultura ---------- */
create table if not exists cultura_padroes (
  id serial primary key,
  texto text not null,
  detalhe text,
  pop_id text references pops(id),
  ordem int not null default 0,
  ativo boolean not null default true
);
create table if not exists cultura_registros (
  id serial primary key,
  data date not null default hoje(),
  em timestamptz not null default now(),
  pessoa_id text not null references pessoas(id),
  padrao_id int references cultura_padroes(id),
  tipo text not null check (tipo in ('desvio', 'destaque')),
  nota text,
  por text references pessoas(id)
);
create index if not exists cultura_registros_pessoa on cultura_registros (pessoa_id, data);
create index if not exists cultura_registros_data on cultura_registros (data);

alter table cultura_padroes enable row level security;
alter table cultura_registros enable row level security;
create policy membro_le on cultura_padroes for select to authenticated using ((select sou_membro()));
create policy socio_insere on cultura_padroes for insert to authenticated with check ((select sou_socio()));
create policy socio_altera on cultura_padroes for update to authenticated using ((select sou_socio())) with check ((select sou_socio()));
create policy socio_apaga on cultura_padroes for delete to authenticated using ((select sou_socio()));
-- a gestão vê todos; cada pessoa vê os próprios (o aviso de privacidade garante isso)
create policy le_cultura on cultura_registros for select to authenticated using ((select ve_tudo()) or pessoa_id = (select eu()));

create or replace function registrar_cultura(pessoa text, padrao int, tipo text, nota text default null) returns int
language plpgsql security definer set search_path = public as $$
declare novo int;
begin
  if not sou_gestor() then raise exception 'Só a gerente ou os sócios registram.'; end if;
  if tipo not in ('desvio', 'destaque') then raise exception 'Tipo inválido.'; end if;
  if not exists (select 1 from pessoas p where p.id = pessoa and p.ativo) then raise exception 'Escolha a pessoa.'; end if;
  if tipo = 'desvio' and coalesce(trim(nota), '') = '' then raise exception 'Escreva o que aconteceu.'; end if;
  insert into cultura_registros (pessoa_id, padrao_id, tipo, nota, por) values (pessoa, padrao, tipo, nullif(trim(nota), ''), eu()) returning id into novo;
  return novo;
end $$;
create or replace function apagar_cultura(r int) returns void
language plpgsql security definer set search_path = public as $$
begin
  if not exists (select 1 from cultura_registros c where c.id = r and (c.por = eu() or sou_socio())) then
    raise exception 'Só quem registrou ou os sócios apagam.'; end if;
  delete from cultura_registros where id = r;
end $$;
revoke execute on function registrar_cultura(text, int, text, text) from public, anon;
revoke execute on function apagar_cultura(int) from public, anon;
grant execute on function registrar_cultura(text, int, text, text) to authenticated;
grant execute on function apagar_cultura(int) to authenticated;

-- Padrões iniciais: os comportamentos que estavam na ronda (o Victor edita em Informações da casa)
insert into cultura_padroes (texto, detalhe, pop_id, ordem)
select * from (values
  ('Cliente vem primeiro', 'Ninguém esperando sem atendimento; o cliente interrompe qualquer outra coisa.', 'POP-00', 1),
  ('Sorriso e gentileza', 'No balcão, na cadeira e no lavatório.', 'POP-00', 2),
  ('Postura', 'Foco no cliente, sem conversa paralela, sem gritar.', 'POP-00', 3)
) v(texto, detalhe, pop_id, ordem)
where not exists (select 1 from cultura_padroes);

-- Os itens de comportamento saem da ronda (ficam guardados, com o histórico, e podem voltar pelo editor)
update rotina_itens set ativo = false where id in ('RON.i2', 'RON.i10');
