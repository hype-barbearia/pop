-- Hype POP · 003 · cria os checklists do dia toda madrugada (00:05 em Recife = 03:05 UTC)
create extension if not exists pg_cron;

select cron.unschedule(jobid) from cron.job where jobname = 'hype_pop_gerar_dia';
select cron.schedule('hype_pop_gerar_dia', '5 3 * * *', $$ select public.gerar_dia(public.hoje()) $$);

-- Gera hoje, para começar a usar já
select public.gerar_dia(public.hoje());
