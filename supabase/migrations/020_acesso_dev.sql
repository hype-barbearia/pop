-- Hype POP · 020 · acesso DEV (sistemas@hypebarbearia.com)
-- Perfil de desenvolvimento: vê o app como qualquer pessoa da equipe, só leitura.
-- Lê tudo (como os sócios), não altera nada de gestão, não entra em rotinas, listas nem números.

alter table pessoas drop constraint if exists pessoas_papel_check;
alter table pessoas add constraint pessoas_papel_check check (papel in ('socio', 'gerente', 'barbeiro', 'atendente', 'dev'));

insert into pessoas (id, nome, nome_completo, papel, email, ativo, ordem, rotulo, cor, socio, parceiro, turno, folga)
values ('sistemas', 'Sistemas', 'Sistemas (DEV)', 'dev', 'sistemas@hypebarbearia.com', true, 99, 'Acesso de desenvolvimento · só leitura', 200, false, false, null, null)
on conflict (id) do update set papel = 'dev', email = excluded.email, ativo = true, rotulo = excluded.rotulo;

create or replace function sou_dev() returns boolean language sql stable security definer set search_path = public as
$$ select exists (select 1 from pessoas where id = eu() and papel = 'dev' and ativo) $$;

-- Lê tudo, como os sócios. Escrita de gestão continua só com sou_gestor() e sou_socio().
create or replace function ve_tudo() returns boolean language sql stable security definer set search_path = public as
$$ select sou_gestor() or exists (select 1 from pessoas where id = eu() and (socio or papel = 'dev')) $$;

-- O DEV não aparece no status da equipe
create or replace function status_equipe()
returns table (pessoa_id text, avisos int, ultimo_acesso timestamptz, privacidade timestamptz)
language sql stable security definer set search_path = public, auth as $$
  select p.id,
    (select count(*)::int from push_inscricoes s where s.pessoa_id = p.id),
    (select max(u.last_sign_in_at) from auth.users u where p.email is not null and lower(u.email) = lower(p.email)),
    (select max(a.em) from privacidade_aceite a where a.pessoa_id = p.id)
  from pessoas p where ve_tudo() and p.ativo and p.papel <> 'dev'
$$;

/* Diagnóstico do sistema (só DEV) */
create or replace function dev_diagnostico() returns jsonb language plpgsql stable security definer set search_path = public, cron, net, auth as $$
begin
  if not sou_dev() then raise exception 'Só o acesso DEV.'; end if;
  return jsonb_build_object(
    'agora', now(),
    'hoje', hoje(),
    'tarefas', (select jsonb_agg(t order by t->>'job') from (
        select jsonb_build_object('job', j.jobname, 'quando', j.schedule, 'ativo', j.active,
          'ultima', (select max(d.start_time) from cron.job_run_details d where d.jobid = j.jobid),
          'ultimo_status', (select d.status from cron.job_run_details d where d.jobid = j.jobid order by d.start_time desc limit 1),
          'falhas_24h', (select count(*) from cron.job_run_details d where d.jobid = j.jobid and d.status = 'failed' and d.start_time > now() - interval '24 hours')) t
        from cron.job j where j.jobname like 'hype_pop%') x),
    'checklists_hoje', (select count(*) from execucoes where data = hoje()),
    'concluidos_hoje', (select count(*) from execucoes where data = hoje() and concluida_em is not null),
    'avisos', jsonb_build_object(
      'enviados_24h', (select count(*) from notificacoes where enviado_em > now() - interval '24 hours'),
      'pendentes', (select count(*) from notificacoes where enviado_em is null and criado_em > now() - interval '2 hours'),
      'presos', (select count(*) from notificacoes where enviado_em is null and criado_em < now() - interval '15 min' and criado_em > now() - interval '2 hours'),
      'ultimos', (select jsonb_agg(n) from (select pessoa_id, titulo, criado_em, enviado_em from notificacoes order by criado_em desc limit 12) n)),
    'envio_http_24h', (select jsonb_agg(h) from (select status_code, count(*) c from net._http_response where created > now() - interval '24 hours' group by 1) h),
    'erros', (select jsonb_agg(e) from (select em, pessoa_id, msg, ctx from erros_app order by em desc limit 20) e),
    'aparelhos', (select jsonb_agg(a) from (select pessoa_id, count(*) n, max(criado_em) ultimo from push_inscricoes group by 1) a),
    'acessos', (select jsonb_agg(s) from (select p.id pessoa_id, p.nome, p.papel,
        (select max(u.last_sign_in_at) from auth.users u where lower(u.email) = lower(p.email)) ultimo_acesso
        from pessoas p where p.ativo order by p.ordem) s));
end $$;

/* Aviso de teste no próprio aparelho do DEV */
create or replace function dev_notificar_teste() returns void language plpgsql security definer set search_path = public as $$
begin
  if not sou_dev() then raise exception 'Só o acesso DEV.'; end if;
  perform notificar(eu(), 'devteste:' || extract(epoch from now())::bigint, 'Teste de notificação do Hype POP', 'Se este aviso chegou, o envio de notificações está funcionando.');
  perform disparar_envio('enviar');
end $$;

do $$ declare f text; begin
  foreach f in array array['sou_dev()', 'dev_diagnostico()', 'dev_notificar_teste()'] loop
    execute format('revoke execute on function %s from public, anon', f);
    execute format('grant execute on function %s to authenticated', f);
  end loop;
end $$;

-- A conta sistemas@ tinha ficado em "Para definir" por não pertencer a ninguém: agora é o acesso DEV
update definicoes set resolvido_em = now(), resposta = 'Virou o acesso DEV (sistemas@hypebarbearia.com), só leitura.'
where titulo like 'Usuário sistemas@%' and resolvido_em is null;
