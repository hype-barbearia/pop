-- Hype POP · 013 · ajustes pedidos em 16/11/2026
-- 1. Limpeza diária da porta de vidro da entrada e da área do Head Spa, revezando Magda e Suellen.
-- 2. Grades fechadas às 19:30 (sábado 17:30), com a casa ainda aberta.
-- 3. Quem fecha as grades vira escala por dia da semana (fácil de mudar na tela Rotina e checklists).

insert into rotinas (id, titulo, pop_id, tipo, conferir, dias, rodizio, ordem)
values ('POR', 'Porta de vidro e área do Head Spa', 'POP-04', 'check', true, '{1,2,3,4,5,6}', true, 7)
on conflict (id) do nothing;
insert into rotina_janelas (rotina_id, inicio, prazo, responsavel)
select 'POR', '15:00', '16:00', 'magda' where not exists (select 1 from rotina_janelas where rotina_id = 'POR');
insert into rotina_itens (id, rotina_id, ordem, texto) values
  ('POR.i1', 'POR', 1, 'Porta de vidro da entrada limpa, por dentro e por fora'),
  ('POR.i2', 'POR', 2, 'Área do Head Spa limpa e organizada')
on conflict (id) do nothing;
-- Revezamento provisório, um dia cada (a gestão define os dias na escala)
insert into rodizio_escala (rotina_id, dow, pessoa_id) values
  ('POR',1,'magda'), ('POR',2,'suellen'), ('POR',3,'magda'), ('POR',4,'suellen'), ('POR',5,'magda'), ('POR',6,'suellen')
on conflict (rotina_id, dow) do nothing;

-- Grades: uma rotina só, todos os dias, responsável pela escala
update rotinas set dias = '{1,2,3,4,5,6}', rodizio = true, junto = null, titulo = 'Grades fechadas' where id = 'GRA';
update rotinas set ativo = false where id = 'GRB';
update rotina_janelas set inicio = '19:30', prazo = '19:50' where rotina_id = 'GRA' and (dias is null or not (6 = any(dias)));
update rotina_janelas set inicio = '17:30', prazo = '17:50' where rotina_id = 'GRA' and 6 = any(dias);
update rotina_janelas set dias = '{1,2,3,4,5}' where rotina_id = 'GRA' and dias is null;
-- Mesma divisão de hoje: seg, qua e sex Durval; ter, qui e sáb Breno
insert into rodizio_escala (rotina_id, dow, pessoa_id) values
  ('GRA',1,'durval'), ('GRA',2,'breno'), ('GRA',3,'durval'), ('GRA',4,'breno'), ('GRA',5,'durval'), ('GRA',6,'breno')
on conflict (rotina_id, dow) do update set pessoa_id = excluded.pessoa_id;
