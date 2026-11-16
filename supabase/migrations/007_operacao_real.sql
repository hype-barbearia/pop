-- Hype POP · 007 · folgas, sábado, dias sem expediente, ausências, rodízios, permissões do Robson,
-- versões de POP, ocorrências completas, notificações e registro de erros.

/* ---------------- Estrutura ---------------- */
alter table rotinas add column if not exists ignora_folga boolean not null default false;
alter table rotinas add column if not exists rodizio boolean not null default false;
alter table rotina_janelas add column if not exists dias smallint[];

create table if not exists dias_fechados (
  data date primary key, motivo text, por text references pessoas(id), em timestamptz not null default now());

create table if not exists ausencias (
  id serial primary key, pessoa_id text not null references pessoas(id), inicio date not null, fim date not null,
  motivo text, substituto text references pessoas(id), por text references pessoas(id), em timestamptz not null default now(),
  check (fim >= inicio));

create table if not exists rodizio_escala (
  rotina_id text references rotinas(id) on delete cascade, dow smallint check (dow between 1 and 6),
  pessoa_id text references pessoas(id), primary key (rotina_id, dow));

create table if not exists pop_versoes (
  pop_id text references pops(id) on delete cascade, versao int, conteudo jsonb not null,
  publicado_em timestamptz not null default now(), por text references pessoas(id), primary key (pop_id, versao));

alter table ocorrencias add column if not exists responsavel_id text references pessoas(id);
alter table ocorrencias add column if not exists prazo date;
alter table ocorrencias add column if not exists foto_path text;

create table if not exists push_inscricoes (
  endpoint text primary key, pessoa_id text not null references pessoas(id) on delete cascade,
  p256dh text not null, auth text not null, ua text, criado_em timestamptz not null default now());

create table if not exists notificacoes (
  id serial primary key, chave text unique not null, pessoa_id text not null references pessoas(id) on delete cascade,
  titulo text not null, corpo text, url text default './', criado_em timestamptz not null default now(), enviado_em timestamptz);
create index if not exists notificacoes_pendentes on notificacoes (criado_em) where enviado_em is null;

create table if not exists resumos (data date primary key, texto text not null, criado_em timestamptz not null default now());

create table if not exists erros_app (
  id serial primary key, email text, pessoa_id text, em timestamptz not null default now(), msg text, ctx text);

create schema if not exists privado;
revoke all on schema privado from public, anon, authenticated;
create table if not exists privado.config (chave text primary key, valor text not null);

/* ---------------- Quem pode o quê ----------------
   sou_socio:  só sócio de papel (Victor) edita configuração.
   sou_gestor: sócio, gerente ou substituto da gerente ausente hoje: confere, cobra, trata ocorrência.
   ve_tudo:    gestor ou sócio-barbeiro (Robson): vê tudo, sem alterar. */
create or replace function sou_socio() returns boolean language sql stable security definer set search_path = public as
$$ select exists (select 1 from pessoas where id = eu() and papel = 'socio') $$;

create or replace function substitui_gerente(p text, d date) returns boolean language sql stable security definer set search_path = public as
$$ select exists (select 1 from ausencias a join pessoas g on g.id = a.pessoa_id and g.papel = 'gerente'
                  where a.substituto = p and d between a.inicio and a.fim) $$;

create or replace function sou_gestor() returns boolean language sql stable security definer set search_path = public as
$$ select exists (select 1 from pessoas where id = eu() and papel in ('socio','gerente')) or coalesce(substitui_gerente(eu(), hoje()), false) $$;

create or replace function ve_tudo() returns boolean language sql stable security definer set search_path = public as
$$ select sou_gestor() or exists (select 1 from pessoas where id = eu() and socio) $$;

create or replace function pode_ver_execucao(e uuid) returns boolean language sql stable security definer set search_path = public as
$$ select ve_tudo() or exists (
     select 1 from execucoes x join rotinas r on r.id = x.rotina_id
     where x.id = e and (x.pessoa_id = eu() or eu() = any(coalesce(r.junto, '{}')))) $$;

/* ---------------- RLS das tabelas novas e ajustes ---------------- */
alter table dias_fechados enable row level security;
alter table ausencias enable row level security;
alter table rodizio_escala enable row level security;
alter table pop_versoes enable row level security;
alter table push_inscricoes enable row level security;
alter table notificacoes enable row level security;
alter table resumos enable row level security;
alter table erros_app enable row level security;

do $$ declare t text; begin
  foreach t in array array['dias_fechados','ausencias','rodizio_escala','pop_versoes'] loop
    execute format('drop policy if exists ler on %I', t);
    execute format('create policy ler on %I for select to authenticated using (sou_membro())', t);
  end loop;
end $$;
drop policy if exists socio_edita on rodizio_escala;
create policy socio_edita on rodizio_escala for all to authenticated using (sou_socio()) with check (sou_socio());
drop policy if exists ler on push_inscricoes;
create policy ler on push_inscricoes for select to authenticated using (pessoa_id = eu());
drop policy if exists ler on notificacoes;
create policy ler on notificacoes for select to authenticated using (pessoa_id = eu());
drop policy if exists ler on resumos;
create policy ler on resumos for select to authenticated using (ve_tudo());
drop policy if exists ler on erros_app;
create policy ler on erros_app for select to authenticated using (sou_socio());

drop policy if exists ler on ocorrencias;
create policy ler on ocorrencias for select to authenticated using (ve_tudo() or pessoa_id = eu() or criado_por = eu() or responsavel_id = eu());
drop policy if exists ler on ocorrencia_acoes;
create policy ler on ocorrencia_acoes for select to authenticated using (exists (select 1 from ocorrencias o where o.id = ocorrencia_id
  and (ve_tudo() or o.pessoa_id = eu() or o.criado_por = eu() or o.responsavel_id = eu())));
drop policy if exists ler on lembretes_feitos;
create policy ler on lembretes_feitos for select to authenticated using (ve_tudo());

/* ---------------- Rotina: sábado, folgas e rodízios ---------------- */
-- Sábado: todos os barbeiros chegam às 08:50 e a casa fecha às 18:00
update rotinas set dias = '{1,2,3,4,5}' where id in ('BIN','BIF');
insert into rotinas (id, titulo, pop_id, tipo, conferir, dias, cada_papel, ordem)
values ('BIS', 'Chegada e grades (sábado)', 'POP-01', 'check', true, '{6}', 'barbeiro', 1)
on conflict (id) do nothing;
insert into rotina_janelas (rotina_id, inicio, prazo)
select 'BIS', '08:50', '09:00' where not exists (select 1 from rotina_janelas where rotina_id = 'BIS');
insert into rotina_itens (id, rotina_id, ordem, texto, critico) values
  ('BIS.i1','BIS',1,'Chegada às 08:50',true), ('BIS.i2','BIS',2,'Grades retiradas',false), ('BIS.i3','BIS',3,'Bancada organizada',false)
on conflict (id) do nothing;

-- Janelas de dia de semana e de sábado para o fechamento
update rotina_janelas set dias = '{1,2,3,4,5}' where rotina_id in ('FEC','BFE','INF','GRA','AMB') and dias is null and inicio >= '17:00'
  and not (rotina_id = 'AMB');
insert into rotina_janelas (rotina_id, inicio, prazo, responsavel, dias)
select v.* from (values
  ('FEC', time '18:00', time '18:30', 'suellen', '{6}'::smallint[]),
  ('BFE', time '18:00', time '18:20', null::text, '{6}'::smallint[]),
  ('INF', time '17:40', time '18:10', 'daniel', '{6}'::smallint[]),
  ('GRA', time '18:20', time '18:40', 'breno', '{6}'::smallint[])
) v(rotina_id, inicio, prazo, responsavel, dias)
where not exists (select 1 from rotina_janelas j where j.rotina_id = v.rotina_id and j.dias = v.dias);

-- Reuniões acontecem mesmo em dia de folga (ex.: técnicas do Robson na segunda)
update rotinas set ignora_folga = true where id in ('GES','ALI','TEC','O1T','O1Q');
-- Tarefas em revezamento: a escala por dia de semana define quem faz
update rotinas set rodizio = true where id in ('PLA','GRD','INF');

/* ---------------- Gerar o dia ---------------- */
create or replace function quem_faz(p text, d date, ignora_folga boolean) returns text
language plpgsql stable security definer set search_path = public as $$
declare a ausencias; f smallint;
begin
  if p is null then return null; end if;
  select * into a from ausencias where pessoa_id = p and d between inicio and fim order by id desc limit 1;
  if a.id is not null then return a.substituto; end if;
  select folga into f from pessoas where id = p and ativo;
  if not found then return null; end if;
  if not ignora_folga and f = extract(dow from d) then return null; end if;
  return p;
end $$;

create or replace function gerar_dia(d date) returns int language plpgsql security definer set search_path = public as $$
declare
  dow int := extract(dow from d);
  r rotinas; j rotina_janelas; base text[]; quem text[]; p text; n int := 0; desloc int; resp text;
  surpresa boolean := coalesce((select rondas_surpresa from regras where id = 1), false);
begin
  if dow = 0 then return 0; end if;
  if not exists (select 1 from regras where id = 1 and inicio_operacao is not null and d >= inicio_operacao) then return 0; end if;
  if exists (select 1 from dias_fechados where data = d) then return 0; end if;
  for r in select * from rotinas where ativo and dow = any(dias) loop
    if r.quinzenal and ((d - date '2026-10-19') % 14) <> 0 then continue; end if;
    for j in select * from rotina_janelas where rotina_id = r.id and (dias is null or dow = any(dias)) loop
      if r.cada is not null then
        select array_agg(id) into base from pessoas where id = any(r.cada) and ativo;
      elsif r.cada_papel is not null then
        select array_agg(id order by ordem) into base from pessoas where papel = r.cada_papel and ativo;
      else
        resp := coalesce((select pessoa_id from rodizio_escala where rotina_id = r.id and rodizio_escala.dow = extract(dow from d)), j.responsavel);
        base := array[resp];
      end if;
      quem := '{}';
      foreach p in array coalesce(base, '{}') loop
        p := quem_faz(p, d, r.ignora_folga);
        if p is not null and not p = any(quem) then quem := quem || p; end if;
      end loop;
      desloc := case when r.tipo = 'ronda' and surpresa then (floor(random() * 121) - 60)::int else 0 end;
      foreach p in array quem loop
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
revoke execute on function gerar_dia(date), quem_faz(text, date, boolean) from public, anon, authenticated;

/* ---------------- Dias sem expediente e ausências ---------------- */
create or replace function fechar_dia(d date, motivo text) returns void language plpgsql security definer set search_path = public as $$
begin
  if not sou_gestor() then raise exception 'Só a gerente ou os sócios fecham um dia.'; end if;
  insert into dias_fechados (data, motivo, por) values (d, motivo, eu()) on conflict (data) do update set motivo = excluded.motivo;
  delete from execucoes x where x.data = d and x.concluida_em is null and not exists (select 1 from execucao_itens i where i.execucao_id = x.id);
end $$;

create or replace function reabrir_dia(d date) returns void language plpgsql security definer set search_path = public as $$
begin
  if not sou_gestor() then raise exception 'Só a gerente ou os sócios reabrem um dia.'; end if;
  delete from dias_fechados where data = d;
  if d = hoje() then perform gerar_dia(d); end if;
end $$;

create or replace function registrar_ausencia(pessoa text, de date, ate date, motivo text, substituto text default null)
returns void language plpgsql security definer set search_path = public as $$
declare x execucoes;
begin
  if not sou_gestor() then raise exception 'Só a gerente ou os sócios registram ausência.'; end if;
  if substituto = pessoa then raise exception 'O substituto precisa ser outra pessoa.'; end if;
  insert into ausencias (pessoa_id, inicio, fim, motivo, substituto, por) values (pessoa, de, ate, motivo, nullif(substituto, ''), eu());
  -- Checklists já criados e ainda não começados passam para o substituto, ou saem do dia
  for x in select * from execucoes e where e.pessoa_id = pessoa and e.data between de and ate and e.concluida_em is null
           and not exists (select 1 from execucao_itens i where i.execucao_id = e.id) loop
    if nullif(substituto, '') is not null and not exists (select 1 from execucoes y where y.data = x.data and y.janela_id = x.janela_id and y.pessoa_id = substituto) then
      update execucoes set pessoa_id = substituto where id = x.id;
    else
      delete from execucoes where id = x.id;
    end if;
  end loop;
end $$;

create or replace function remover_ausencia(a int) returns void language plpgsql security definer set search_path = public as $$
begin
  if not sou_gestor() then raise exception 'Só a gerente ou os sócios mexem em ausências.'; end if;
  delete from ausencias where id = a;
end $$;

/* ---------------- Ações: gestor de verdade (Robson só vê) ---------------- */
create or replace function lembrete_feito(l int) returns void language plpgsql security definer set search_path = public as $$
begin
  if not sou_gestor() then raise exception 'Só a gerente marca lembretes.'; end if;
  insert into lembretes_feitos (lembrete_id, data, por) values (l, hoje(), eu()) on conflict do nothing;
end $$;

/* ---------------- Ocorrências ---------------- */
drop function if exists abrir_ocorrencia(text, text, text, text, text);
create or replace function abrir_ocorrencia(titulo text, pessoa text, origem text, descricao text, pop text default null,
  responsavel text default null, prazo date default null, foto text default null)
returns int language plpgsql security definer set search_path = public as $$
declare novo int; gestor boolean := sou_gestor();
begin
  if not sou_membro() then raise exception 'Acesso só para a equipe da Hype.'; end if;
  insert into ocorrencias (data, pessoa_id, origem, pop_id, titulo, descricao, criado_por, responsavel_id, prazo, foto_path)
  values (hoje(), nullif(pessoa, ''), case when gestor then origem else 'Equipe' end, pop, titulo, descricao, eu(),
          case when gestor then nullif(responsavel, '') end, case when gestor then prazo end, foto) returning id into novo;
  return novo;
end $$;

create or replace function ajustar_ocorrencia(oc int, responsavel text, prazo date) returns void language plpgsql security definer set search_path = public as $$
begin
  if not sou_gestor() then raise exception 'Só a gerente ou os sócios ajustam ocorrências.'; end if;
  update ocorrencias set responsavel_id = nullif(responsavel, ''), prazo = ajustar_ocorrencia.prazo where id = oc;
end $$;

/* ---------------- POPs: editar e versionar ---------------- */
create or replace function salvar_pop(pop text, dados jsonb, nova_versao boolean) returns int language plpgsql security definer set search_path = public as $$
declare p pops; v int;
begin
  if not sou_socio() then raise exception 'Só os sócios editam POPs.'; end if;
  select * into p from pops where id = pop;
  if p.id is null then raise exception 'POP não encontrado.'; end if;
  if nova_versao then
    insert into pop_versoes (pop_id, versao, conteudo, por) values (p.id, p.versao, to_jsonb(p), eu()) on conflict do nothing;
  end if;
  update pops set
    titulo = coalesce(dados->>'titulo', titulo), objetivo = coalesce(dados->>'objetivo', objetivo),
    quem = coalesce(dados->>'quem', quem), frequencia = coalesce(dados->>'frequencia', frequencia), dono = coalesce(dados->>'dono', dono),
    passos = coalesce(dados->'passos', passos), qualidade = coalesce(dados->'qualidade', qualidade), erros = coalesce(dados->'erros', erros),
    materiais = coalesce(dados->'materiais', materiais),
    versao = case when nova_versao then versao + 1 else versao end,
    atualizado = to_char(hoje(), 'DD/MM/YYYY'),
    aprovado_por = (select nome from pessoas where id = eu())
  where id = pop returning versao into v;
  return v;
end $$;

/* ---------------- Notificações ---------------- */
create or replace function inscrever_push(endpoint text, p256dh text, auth text, ua text default null) returns void
language plpgsql security definer set search_path = public as $$
begin
  if not sou_membro() then raise exception 'Acesso só para a equipe da Hype.'; end if;
  insert into push_inscricoes (endpoint, pessoa_id, p256dh, auth, ua) values (endpoint, eu(), p256dh, auth, ua)
  on conflict on constraint push_inscricoes_pkey do update set pessoa_id = excluded.pessoa_id, p256dh = excluded.p256dh, auth = excluded.auth, ua = excluded.ua;
end $$;
create or replace function remover_push(endpoint text) returns void language plpgsql security definer set search_path = public as $$
begin delete from push_inscricoes p where p.endpoint = remover_push.endpoint and p.pessoa_id = eu(); end $$;

create or replace function notificar(p text, chave text, titulo text, corpo text) returns void language sql security definer set search_path = public as
$$ insert into notificacoes (chave, pessoa_id, titulo, corpo) values (chave, p, titulo, corpo) on conflict (chave) do nothing $$;

-- Gerentes do dia: a gerente presente ou quem a substitui
create or replace function gerentes_do_dia(d date) returns setof text language sql stable security definer set search_path = public as $$
  select id from pessoas g where g.papel = 'gerente' and g.ativo and not exists (select 1 from ausencias a where a.pessoa_id = g.id and d between a.inicio and a.fim)
  union select a.substituto from ausencias a join pessoas g on g.id = a.pessoa_id and g.papel = 'gerente' where d between a.inicio and a.fim and a.substituto is not null
$$;

create or replace function resumo_do_dia(d date) returns text language plpgsql stable security definer set search_path = public as $$
declare tot int; venc int; ok int; tarde int; nf int; oc int; ron int; ron_ok int; t text;
begin
  select count(*), count(*) filter (where prazo <= now()), count(*) filter (where concluida_em <= prazo),
         count(*) filter (where concluida_em > prazo), count(*) filter (where concluida_em is null and prazo <= now())
    into tot, venc, ok, tarde, nf from execucoes where data = d;
  select count(*) into oc from ocorrencias where data = d;
  select count(*), count(*) filter (where concluida_em is not null) into ron, ron_ok from execucoes where data = d and rotina_id = 'RON';
  t := format('Conformidade: %s%% no prazo (%s de %s). Com atraso: %s. Não feitos: %s. Ocorrências: %s. Rondas: %s de %s.',
    case when venc > 0 then round(100.0 * ok / venc) else 100 end, ok, venc, tarde, nf, oc, ron_ok, ron);
  return t;
end $$;

-- Roda a cada 5 minutos: cria as notificações devidas (cada uma uma vez só)
create or replace function gerar_notificacoes() returns int language plpgsql security definer set search_path = public as $$
declare
  d date := hoje(); agora timestamptz := now(); rg regras; x record; g text; s text; n int := 0; txt text;
begin
  select * into rg from regras where id = 1;
  if exists (select 1 from dias_fechados where data = d) then return 0; end if;
  for x in select e.*, r.titulo, r.conferir, p.nome from execucoes e join rotinas r on r.id = e.rotina_id join pessoas p on p.id = e.pessoa_id where e.data = d loop
    -- Abriu a janela
    if x.inicio <= agora and x.inicio > agora - interval '15 min' and x.concluida_em is null and x.rotina_id <> 'RON' then
      perform notificar(x.pessoa_id, 'ini:' || x.id, 'Hora do checklist: ' || x.titulo, 'Prazo até ' || to_char(x.prazo at time zone 'America/Recife', 'HH24:MI') || '.');
    end if;
    -- Ronda e checklists da gerente: aviso antes de começar
    if x.rotina_id = 'RON' and x.inicio - make_interval(mins => rg.antes) <= agora and x.inicio > agora - interval '15 min' then
      perform notificar(x.pessoa_id, 'ini:' || x.id, 'Ronda dos inegociáveis às ' || to_char(x.inicio at time zone 'America/Recife', 'HH24:MI'), 'Avalie os 10 itens com a casa funcionando.');
    end if;
    -- Venceu sem concluir: avisa a pessoa e a gerente
    if x.concluida_em is null and x.prazo <= agora and x.prazo > agora - interval '3 hours' then
      perform notificar(x.pessoa_id, 'atr:' || x.id, 'Checklist atrasado: ' || x.titulo, 'O prazo era ' || to_char(x.prazo at time zone 'America/Recife', 'HH24:MI') || '. Conclua assim que puder.');
      for g in select * from gerentes_do_dia(d) loop
        if g <> x.pessoa_id then perform notificar(g, 'atrg:' || x.id || ':' || g, 'Atraso: ' || x.titulo || ' · ' || x.nome, 'Prazo era ' || to_char(x.prazo at time zone 'America/Recife', 'HH24:MI') || '. Abra o app para cobrar.'); end if;
      end loop;
    end if;
    -- Continua atrasado depois do limite: escala aos sócios
    if x.concluida_em is null and x.prazo + make_interval(mins => rg.escalar) <= agora and x.prazo > agora - interval '3 hours' then
      for s in select id from pessoas where papel = 'socio' and ativo loop
        perform notificar(s, 'esc:' || x.id || ':' || s, 'Escalado: ' || x.titulo || ' · ' || x.nome, rg.escalar || ' min de atraso.');
      end loop;
    end if;
    -- Concluído e sem conferência depois do limite
    if x.conferir and x.concluida_em is not null and x.conferido_em is null and x.concluida_em + make_interval(mins => rg.conferir) <= agora and x.concluida_em > agora - interval '4 hours' then
      for g in select * from gerentes_do_dia(d) loop
        perform notificar(g, 'conf:' || x.id || ':' || g, 'Conferir: ' || x.titulo || ' · ' || x.nome, 'Concluído às ' || to_char(x.concluida_em at time zone 'America/Recife', 'HH24:MI') || '.');
      end loop;
    end if;
  end loop;
  -- Lembretes fixos
  for x in select * from lembretes l where l.ativo and extract(dow from d) = any(l.dias)
           and (d + l.hora) at time zone 'America/Recife' <= agora and (d + l.hora) at time zone 'America/Recife' > agora - interval '30 min'
           and not exists (select 1 from lembretes_feitos f where f.lembrete_id = l.id and f.data = d) loop
    for g in select * from gerentes_do_dia(d) loop
      perform notificar(g, 'lem:' || x.id || ':' || d || ':' || g, 'Lembrete: ' || x.texto, 'Marque como feito no app.');
    end loop;
  end loop;
  -- Resumo do dia aos sócios
  if (d + rg.resumo) at time zone 'America/Recife' <= agora and exists (select 1 from execucoes where data = d) then
    txt := resumo_do_dia(d);
    insert into resumos (data, texto) values (d, txt) on conflict (data) do nothing;
    for s in select id from pessoas where (papel = 'socio' or socio) and ativo loop
      perform notificar(s, 'res:' || d || ':' || s, 'Resumo de hoje na Hype', txt);
    end loop;
  end if;
  get diagnostics n = row_count;
  return n;
end $$;

-- Cobrança da gerente vira notificação na hora
create or replace function ao_cobrar() returns trigger language plpgsql security definer set search_path = public as $$
declare x record;
begin
  select e.pessoa_id, r.titulo, e.prazo into x from execucoes e join rotinas r on r.id = e.rotina_id where e.id = new.execucao_id;
  perform notificar(x.pessoa_id, 'cob:' || new.id, coalesce((select nome from pessoas where id = new.por), 'A gerência') || ' te lembrou: ' || x.titulo,
    'O prazo era ' || to_char(x.prazo at time zone 'America/Recife', 'HH24:MI') || '.');
  return new;
end $$;
drop trigger if exists ao_cobrar on cobrancas;
create trigger ao_cobrar after insert on cobrancas for each row execute function ao_cobrar();

-- Pedido de refazer vira notificação
create or replace function ao_refazer() returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.refazer_em is not null and (old.refazer_em is null or old.refazer_em <> new.refazer_em) then
    perform notificar(new.pessoa_id, 'ref:' || new.id || ':' || extract(epoch from new.refazer_em)::bigint,
      'Refazer: ' || (select titulo from rotinas where id = new.rotina_id), coalesce(new.refazer_obs, ''));
  end if;
  return new;
end $$;
drop trigger if exists ao_refazer on execucoes;
create trigger ao_refazer after update on execucoes for each row execute function ao_refazer();

/* ---------------- Erros do app ---------------- */
create or replace function registrar_erro(msg text, ctx text default null) returns void language sql security definer set search_path = public as
$$ insert into erros_app (email, pessoa_id, msg, ctx) values (auth.jwt() ->> 'email', eu(), left(msg, 2000), left(ctx, 2000)) $$;

/* ---------------- Histórico: o Robson também vê ---------------- */
create or replace function historico(dias int default 28)
returns table (data date, rotina_id text, pessoa_id text, chave text, previstos int, no_prazo int, atraso int, nao_feito int)
language sql stable security definer set search_path = public as $$
  select x.data, x.rotina_id, x.pessoa_id,
    x.rotina_id || '.' || x.pessoa_id || '.' || to_char(j.inicio, 'HH24MI'),
    1, (x.concluida_em is not null and x.concluida_em <= x.prazo)::int,
    (x.concluida_em is not null and x.concluida_em > x.prazo)::int, (x.concluida_em is null)::int
  from execucoes x join rotina_janelas j on j.id = x.janela_id
  where sou_membro() and x.data < hoje() and x.data >= hoje() - historico.dias
    and (ve_tudo() or x.pessoa_id = eu())
$$;

/* ---------------- Relatório de um período ---------------- */
create or replace function relatorio(de date, ate date)
returns table (pessoa_id text, rotina_id text, previstos int, no_prazo int, atraso int, nao_feito int, itens_nao int)
language sql stable security definer set search_path = public as $$
  select x.pessoa_id, x.rotina_id, count(*)::int,
    count(*) filter (where x.concluida_em <= x.prazo)::int, count(*) filter (where x.concluida_em > x.prazo)::int,
    count(*) filter (where x.concluida_em is null)::int,
    coalesce(sum((select count(*) from execucao_itens i where i.execucao_id = x.id and not i.ok)), 0)::int
  from execucoes x where ve_tudo() and x.data between de and least(ate, hoje() - 1)
  group by 1, 2
$$;

/* ---------------- Permissões ---------------- */
do $$ declare f text; begin
  foreach f in array array['fechar_dia(date,text)','reabrir_dia(date)','registrar_ausencia(text,date,date,text,text)','remover_ausencia(int)',
    'abrir_ocorrencia(text,text,text,text,text,text,date,text)','ajustar_ocorrencia(int,text,date)','salvar_pop(text,jsonb,boolean)',
    'inscrever_push(text,text,text,text)','remover_push(text)','registrar_erro(text,text)','relatorio(date,date)',
    've_tudo()','substitui_gerente(text,date)','sou_gestor()','sou_socio()','pode_ver_execucao(uuid)'] loop
    execute format('revoke execute on function %s from public, anon', f);
    execute format('grant execute on function %s to authenticated', f);
  end loop;
  foreach f in array array['notificar(text,text,text,text)','gerentes_do_dia(date)','resumo_do_dia(date)','gerar_notificacoes()','ao_cobrar()','ao_refazer()'] loop
    execute format('revoke execute on function %s from public, anon, authenticated', f);
  end loop;
end $$;

/* ---------------- Tempo real ---------------- */
do $$ declare t text; begin
  foreach t in array array['ausencias','dias_fechados','notificacoes'] loop
    if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and tablename = t) then
      execute format('alter publication supabase_realtime add table %I', t);
    end if;
  end loop;
end $$;
