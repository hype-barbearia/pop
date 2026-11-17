-- Hype POP · 015 · horário de checklist pode ser desligado sem apagar o histórico
alter table rotina_janelas add column if not exists ativo boolean not null default true;
do $$ declare def text; begin
  def := pg_get_functiondef('gerar_dia(date)'::regprocedure);
  if position('rj.ativo' in def) = 0 then
    def := replace(def, 'where rj.rotina_id = r.id and', 'where rj.rotina_id = r.id and rj.ativo and');
    execute def;
  end if;
end $$;
