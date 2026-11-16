-- Hype POP · 012 · início da operação: terça, 17/11/2026, a partir das 09:00
-- No primeiro dia, checklists com janela antes desse horário não são criados.
alter table regras add column if not exists inicio_hora time;
update regras set inicio_operacao = '2026-11-17', inicio_hora = '09:00' where id = 1;

do $$ declare def text; begin
  def := pg_get_functiondef('gerar_dia(date)'::regprocedure);
  def := replace(def,
    'for j in select * from rotina_janelas where rotina_id = r.id and (dias is null or dow = any(dias)) loop',
    'for j in select rj.* from rotina_janelas rj where rj.rotina_id = r.id and (rj.dias is null or dow = any(rj.dias))
        and not (d = (select inicio_operacao from regras where id = 1) and rj.inicio < coalesce((select inicio_hora from regras where id = 1), ''00:00'')) loop');
  -- versão anterior desta mesma troca (usava j.inicio, que ainda não existe dentro da consulta)
  def := replace(def,
    'for j in select * from rotina_janelas where rotina_id = r.id and (dias is null or dow = any(dias))
        and not (d = (select inicio_operacao from regras where id = 1) and j.inicio < coalesce((select inicio_hora from regras where id = 1), ''00:00'')) loop',
    'for j in select rj.* from rotina_janelas rj where rj.rotina_id = r.id and (rj.dias is null or dow = any(rj.dias))
        and not (d = (select inicio_operacao from regras where id = 1) and rj.inicio < coalesce((select inicio_hora from regras where id = 1), ''00:00'')) loop');
  execute def;
end $$;
