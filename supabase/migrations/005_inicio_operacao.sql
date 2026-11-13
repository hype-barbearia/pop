-- Hype POP · 005 · data de início da operação
-- Antes dessa data o sistema não cria checklists (serve para ler e assinar os POPs e testar).
alter table regras add column if not exists inicio_operacao date;

create or replace function gerar_dia(d date) returns int language plpgsql security definer set search_path = public as $$
declare
  dow int := extract(dow from d);
  r rotinas; j rotina_janelas; quem text[]; p text; n int := 0; desloc int;
  surpresa boolean := coalesce((select rondas_surpresa from regras where id = 1), false);
begin
  if dow = 0 then return 0; end if;
  if not exists (select 1 from regras where id = 1 and inicio_operacao is not null and d >= inicio_operacao) then return 0; end if;
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
revoke execute on function gerar_dia(date) from public, anon, authenticated;

-- Os checklists de 13/11/2026 foram gerados só para teste, antes de alguém usar o app
delete from execucoes where data = date '2026-11-13' and concluida_em is null
  and not exists (select 1 from execucao_itens i where i.execucao_id = execucoes.id);
