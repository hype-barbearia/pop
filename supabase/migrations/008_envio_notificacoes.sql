-- Hype POP · 008 · agendamento das notificações e da limpeza de fotos
-- As chaves VAPID e o segredo do agendamento ficam em privado.config (inseridos à parte, fora do repositório).
create extension if not exists pg_net;

create or replace function public.fotos_antigas(dias int) returns table (name text) language sql stable security definer set search_path = public, storage as
$$ select o.name from storage.objects o where o.bucket_id = 'fotos' and o.created_at < now() - make_interval(days => dias) limit 500 $$;
revoke execute on function public.fotos_antigas(int) from public, anon, authenticated;
grant execute on function public.fotos_antigas(int) to service_role;

create or replace function public.disparar_envio(tarefa text default 'enviar') returns void language plpgsql security definer set search_path = public, privado as $$
begin
  perform net.http_post(
    url := 'https://fwecscsvfxocgjspdsis.supabase.co/functions/v1/notificar?tarefa=' || tarefa,
    headers := jsonb_build_object('Content-Type', 'application/json', 'x-hype-segredo', (select valor from privado.config where chave = 'segredo_cron')),
    body := '{}'::jsonb);
end $$;
revoke execute on function public.disparar_envio(text) from public, anon, authenticated;

-- A cada 2 minutos: cria as notificações devidas e manda as pendentes
select cron.unschedule(jobid) from cron.job where jobname in ('hype_pop_notificar', 'hype_pop_limpeza');
select cron.schedule('hype_pop_notificar', '*/2 * * * *', $$ select public.gerar_notificacoes(); select public.disparar_envio('enviar'); $$);
-- Todo dia às 03:30 em Recife (06:30 UTC): apaga fotos com mais de 90 dias
select cron.schedule('hype_pop_limpeza', '30 6 * * *', $$ select public.disparar_envio('limpeza'); $$);
