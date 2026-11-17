-- Hype POP · 019 · modo TV (apresentação da semana na reunião)
-- Itens que mais falharam num período escolhido (a semana passada, por exemplo).
-- As escolhas do que aparecer na TV ficam em config_textos, chave 'tv' (só os sócios editam).
create or replace function falhas_periodo(de date, ate date)
returns table (item_id text, texto text, rotina_id text, rotina text, pop_id text, falhas int, ultima date)
language sql stable security definer set search_path = public as $$
  select i.id, i.texto, r.id, r.titulo, r.pop_id, count(*)::int, max(x.data)
  from execucao_itens ei
    join execucoes x on x.id = ei.execucao_id
    join rotina_itens i on i.id = ei.item_id
    join rotinas r on r.id = x.rotina_id
  where ve_tudo() and not ei.ok and x.data between de and ate
  group by i.id, i.texto, r.id, r.titulo, r.pop_id
  order by count(*) desc, max(x.data) desc
  limit 10
$$;
revoke execute on function falhas_periodo(date, date) from public, anon;
grant execute on function falhas_periodo(date, date) to authenticated;
