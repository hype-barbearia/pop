-- Hype POP · 023 · desempenho e retenção (sem mudar regras nem funcionalidades)
-- 1. Índices para as buscas que crescem com o tempo (por dia, por checklist, por pessoa).
-- 2. Políticas de acesso: mesmas regras, mas as funções de permissão passam a ser avaliadas
--    uma vez por consulta, e não uma vez por linha: (select sou_membro()) em vez de sou_membro().
--    As políticas "socio_edita" (ALL) viram INSERT/UPDATE/DELETE, para a leitura ter uma política só.
-- 3. Limpeza diária de registros técnicos: histórico do agendador, avisos já enviados e erros antigos.

/* ---------------- 1. Índices ---------------- */
create index if not exists cobrancas_execucao on cobrancas (execucao_id);
create index if not exists ocorrencias_data on ocorrencias (data);
create index if not exists ocorrencias_execucao on ocorrencias (execucao_id);
create index if not exists ocorrencia_acoes_ocorrencia on ocorrencia_acoes (ocorrencia_id);
create index if not exists rotina_janelas_rotina on rotina_janelas (rotina_id);
create index if not exists rotina_itens_rotina on rotina_itens (rotina_id);
create index if not exists execucoes_pessoa_data on execucoes (pessoa_id, data);
create index if not exists execucao_itens_item on execucao_itens (item_id);
create index if not exists push_inscricoes_pessoa on push_inscricoes (pessoa_id);
create index if not exists notificacoes_pessoa on notificacoes (pessoa_id);
create index if not exists notificacoes_criado on notificacoes (criado_em);
create index if not exists erros_app_em on erros_app (em);
create index if not exists ausencias_pessoa on ausencias (pessoa_id, inicio, fim);
create index if not exists documentos_fiscais_pessoa on documentos_fiscais (pessoa_id, competencia);
create index if not exists pop_leituras_pessoa on pop_leituras (pessoa_id);
create index if not exists lembretes_feitos_data on lembretes_feitos (data);

/* ---------------- 2. Políticas avaliadas uma vez por consulta ---------------- */
do $$
declare r record; q text; c text; f text;
  fs text[] := array['sou_membro', 'sou_socio', 'sou_gestor', 've_tudo', 'sou_dev', 'eu'];
begin
  -- socio_edita (ALL) → três políticas de escrita
  for r in select tablename from pg_policies where schemaname = 'public' and policyname = 'socio_edita' and cmd = 'ALL' loop
    execute format('drop policy socio_edita on %I', r.tablename);
    execute format('create policy socio_insere on %I for insert to authenticated with check (sou_socio())', r.tablename);
    execute format('create policy socio_altera on %I for update to authenticated using (sou_socio()) with check (sou_socio())', r.tablename);
    execute format('create policy socio_apaga on %I for delete to authenticated using (sou_socio())', r.tablename);
  end loop;
  -- envolve as funções de permissão em (select ...): mesmo resultado, calculado uma vez
  for r in select tablename, policyname, qual, with_check from pg_policies where schemaname = 'public' loop
    q := r.qual; c := r.with_check;
    foreach f in array fs loop
      if q is not null and position('(select ' || f || '()' in q) = 0 and position('( SELECT ' || f || '()' in q) = 0 then
        q := regexp_replace(q, '\m' || f || '\(\)', '(select ' || f || '())', 'g'); end if;
      if c is not null and position('(select ' || f || '()' in c) = 0 and position('( SELECT ' || f || '()' in c) = 0 then
        c := regexp_replace(c, '\m' || f || '\(\)', '(select ' || f || '())', 'g'); end if;
    end loop;
    if q is distinct from r.qual then execute format('alter policy %I on %I using (%s)', r.policyname, r.tablename, q); end if;
    if c is distinct from r.with_check then execute format('alter policy %I on %I with check (%s)', r.policyname, r.tablename, c); end if;
  end loop;
end $$;

/* ---------------- 3. Limpeza diária ---------------- */
create or replace function limpar_registros_tecnicos() returns jsonb
language plpgsql security definer set search_path = public, cron as $$
declare a int; b int; c int;
begin
  delete from cron.job_run_details where end_time < now() - interval '14 days'; get diagnostics a = row_count;
  delete from notificacoes where (enviado_em is not null and enviado_em < now() - interval '60 days') or (enviado_em is null and criado_em < now() - interval '7 days');
  get diagnostics b = row_count;
  delete from erros_app where em < now() - interval '180 days'; get diagnostics c = row_count;
  return jsonb_build_object('agendador', a, 'avisos', b, 'erros', c);
end $$;
revoke execute on function limpar_registros_tecnicos() from public, anon, authenticated;

do $$ begin
  if not exists (select 1 from cron.job where jobname = 'hype_pop_limpeza_dados') then
    perform cron.schedule('hype_pop_limpeza_dados', '40 6 * * *', $c$ select public.limpar_registros_tecnicos(); $c$);
  end if;
end $$;
