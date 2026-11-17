-- Hype POP · 016 · ajustes da análise de 17/11/2026
-- 1. Ronda surpresa: sorteio de até 30 min e nunca em cima de reunião da mesma pessoa.
-- 2. Checklist só pode ser marcado a partir de 30 min antes do início (antes, só a tela impedia).
-- 3. Conferência por amostra: o admin define a fração; item "não feito" sempre vai para conferência.
-- 4. Lembrete da gerente avisa de novo 30 min depois, se ainda não foi marcado.
-- 5. Escalada de atraso pode incluir o sócio técnico (Robson), se o admin ligar.
-- 6. Lista de definições pendentes para o admin (folgas, almoços e rondas sem cobertura
--    aparecem sozinhos na tela Para definir, pelo detector de conflitos do app).
-- 7. Avisos de segurança do Supabase.

alter table regras add column if not exists conferir_amostra numeric not null default 1 check (conferir_amostra > 0 and conferir_amostra <= 1);
alter table regras add column if not exists escalar_socios boolean not null default false;
alter table execucoes add column if not exists sorteada boolean;

/* ---------------- 1. Ronda fora de reunião ---------------- */
create or replace function ajustar_rondas(d date) returns int language plpgsql security definer set search_path = public as $$
declare x execucoes; m execucoes; n int := 0; dur interval;
begin
  for x in select e.* from execucoes e join rotinas r on r.id = e.rotina_id
           where e.data = d and r.tipo = 'ronda' and e.concluida_em is null
             and not exists (select 1 from execucao_itens i where i.execucao_id = e.id) loop
    select e.* into m from execucoes e join rotinas r on r.id = e.rotina_id
     where e.data = d and e.pessoa_id = x.pessoa_id and e.id <> x.id and (r.ignora_folga or e.agendamento_id is not null)
       and e.inicio < x.prazo and e.prazo > x.inicio
     order by e.prazo desc limit 1;
    if m.id is not null then
      dur := x.prazo - x.inicio;
      update execucoes set inicio = m.prazo + interval '5 min', prazo = m.prazo + interval '5 min' + dur where id = x.id;
      n := n + 1;
    end if;
  end loop;
  return n;
end $$;

create or replace function gerar_dia(d date) returns int language plpgsql security definer set search_path = public as $$
declare
  dow int := extract(dow from d);
  r rotinas; j rotina_janelas; base text[]; quem text[]; p text; n int := 0; desloc int; resp text; ag rotina_agendamentos;
  surpresa boolean := coalesce((select rondas_surpresa from regras where id = 1), false);
begin
  if dow = 0 then return 0; end if;
  if not exists (select 1 from regras where id = 1 and inicio_operacao is not null and d >= inicio_operacao) then return 0; end if;
  if exists (select 1 from dias_fechados where data = d) then return 0; end if;
  for r in select * from rotinas where ativo and dow = any(dias) loop
    if r.quinzenal and ((d - date '2026-10-19') % 14) <> 0 then continue; end if;
    for j in select rj.* from rotina_janelas rj where rj.rotina_id = r.id and rj.ativo and (rj.dias is null or dow = any(rj.dias))
        and not (d = (select inicio_operacao from regras where id = 1) and rj.inicio < coalesce((select inicio_hora from regras where id = 1), '00:00')) loop
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
      -- sorteio de até 30 min para antes ou depois (antes era 1 hora)
      desloc := case when r.tipo = 'ronda' and surpresa then (floor(random() * 61) - 30)::int else 0 end;
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
  for ag in select * from rotina_agendamentos where data = d loop n := n + gerar_agendamento(ag); end loop;
  perform ajustar_rondas(d);
  return n;
end $$;

-- Reunião marcada depois da geração do dia também empurra a ronda
do $$ declare def text; begin
  def := pg_get_functiondef('agendar(text,date,time,time,text,text)'::regprocedure);
  if position('ajustar_rondas' in def) = 0 then
    def := replace(def, 'perform gerar_agendamento(a); end if;', 'perform gerar_agendamento(a); perform ajustar_rondas(a.data); end if;');
    if position('ajustar_rondas' in def) = 0 then raise exception 'agendar: trecho não encontrado'; end if;
    execute def;
  end if;
end $$;

/* ---------------- 2. Marcar só a partir de 30 min antes ---------------- */
create or replace function marcar_item(e uuid, item text, feito boolean, nota text default null, foto text default null)
returns void language plpgsql security definer set search_path = public as $$
declare x execucoes; r rotinas; it rotina_itens;
begin
  if not pode_executar(e) then raise exception 'Este checklist não é seu.'; end if;
  select * into x from execucoes where id = e;
  if x.concluida_em is not null then raise exception 'Checklist já concluído.'; end if;
  if now() < x.inicio - interval '30 min' then
    raise exception 'Este checklist libera às %.', to_char((x.inicio - interval '30 min') at time zone 'America/Recife', 'HH24:MI');
  end if;
  select * into it from rotina_itens where id = item and rotina_id = x.rotina_id;
  if it.id is null then raise exception 'Item inválido.'; end if;
  if feito and it.foto and foto is null then raise exception 'Este item precisa de foto.'; end if;
  if not feito and coalesce(trim(nota), '') = '' then raise exception 'Explique o motivo.'; end if;
  insert into execucao_itens (execucao_id, item_id, ok, marcado_em, foto_path, obs, por)
  values (e, item, feito, now(), foto, nota, eu())
  on conflict (execucao_id, item_id) do update set ok = excluded.ok, marcado_em = excluded.marcado_em, foto_path = excluded.foto_path, obs = excluded.obs, por = excluded.por;
  if not feito then
    select * into r from rotinas where id = x.rotina_id;
    insert into ocorrencias (data, pessoa_id, origem, execucao_id, pop_id, titulo, descricao, criado_por)
    values (x.data, case when r.tipo = 'ronda' then null else x.pessoa_id end,
      case when r.tipo = 'ronda' then 'Ronda da gerente' else 'Checklist' end, e, r.pop_id,
      it.texto || case when r.tipo = 'ronda' then ': não conforme' else ': não feito' end, nota, eu());
  end if;
end $$;

/* ---------------- 3. Conferência por amostra ---------------- */
create or replace function concluir(e uuid) returns void language plpgsql security definer set search_path = public as $$
declare faltam int; nc boolean; amostra numeric;
begin
  if not pode_executar(e) then raise exception 'Este checklist não é seu.'; end if;
  select count(*) into faltam from rotina_itens i join execucoes x on x.rotina_id = i.rotina_id
   where x.id = e and i.ativo and not exists (select 1 from execucao_itens ei where ei.execucao_id = e and ei.item_id = i.id);
  if faltam > 0 then raise exception 'Faltam % itens.', faltam; end if;
  nc := exists (select 1 from execucao_itens where execucao_id = e and not ok);
  amostra := coalesce((select conferir_amostra from regras where id = 1), 1);
  -- sorteada fica fixa na primeira conclusão; num "refazer" a gerente confere de novo
  update execucoes set concluida_em = now(), refazer_em = null, refazer_obs = null,
    sorteada = case when refazer_em is not null or nc then true else coalesce(sorteada, random() < amostra) end
  where id = e and concluida_em is null;
end $$;

/* ---------------- 4 e 5. Notificações ---------------- */
do $$ declare def text; begin
  def := pg_get_functiondef('gerar_notificacoes()'::regprocedure);
  if position('sorteada' in def) = 0 then
    def := replace(def, 'if x.conferir and x.concluida_em is not null', 'if x.conferir and coalesce(x.sorteada, true) and x.concluida_em is not null');
  end if;
  if position('escalar_socios' in def) = 0 then
    def := replace(def, 'for s in select id from pessoas where papel = ''socio'' and ativo loop',
      'for s in select id from pessoas where (papel = ''socio'' or (socio and rg.escalar_socios)) and ativo loop');
  end if;
  if position('lem2:' in def) = 0 then
    def := replace(def, '  if (d + rg.resumo)', '  for x in select * from lembretes l where l.ativo and extract(dow from d) = any(l.dias)
           and (d + l.hora) at time zone ''America/Recife'' + interval ''30 min'' <= agora and (d + l.hora) at time zone ''America/Recife'' > agora - interval ''60 min''
           and not exists (select 1 from lembretes_feitos f where f.lembrete_id = l.id and f.data = d) loop
    for g in select * from gerentes_do_dia(d) loop
      perform notificar(g, ''lem2:'' || x.id || '':'' || d || '':'' || g, ''Ainda pendente: '' || x.texto, ''Lembrete das '' || to_char(x.hora, ''HH24:MI'') || ''. Marque como feito no app.'');
    end loop;
  end loop;
  if (d + rg.resumo)');
  end if;
  if position('sorteada' in def) = 0 or position('escalar_socios' in def) = 0 or position('lem2:' in def) = 0 then raise exception 'gerar_notificacoes: trecho não encontrado'; end if;
  execute def;
end $$;

/* ---------------- 6. Definições pendentes para o admin ---------------- */
create table if not exists definicoes (
  id serial primary key,
  ordem int not null default 0,
  titulo text not null,
  detalhe text,
  sugestao text,
  onde text,
  resposta text,
  resolvido_em timestamptz,
  resolvido_por text references pessoas(id),
  criado_em timestamptz not null default now());
alter table definicoes enable row level security;
drop policy if exists ler on definicoes;
create policy ler on definicoes for select to authenticated using (ve_tudo());
drop policy if exists socio_insere on definicoes;
create policy socio_insere on definicoes for insert to authenticated with check (sou_socio());
drop policy if exists socio_altera on definicoes;
create policy socio_altera on definicoes for update to authenticated using (sou_socio()) with check (sou_socio());
drop policy if exists socio_apaga on definicoes;
create policy socio_apaga on definicoes for delete to authenticated using (sou_socio());

insert into definicoes (ordem, titulo, detalhe, sugestao, onde)
select * from (values
 (2, 'Quantas rondas por dia e em que horários',
  'Hoje são 2 rondas (12:00 e 16:30). O pedido original era conferência de 3 em 3 horas, e depois das 17:00, horário mais movimentado, não há ronda.',
  '4 rondas: 10:30, 13:30, 16:30 e 19:00 (sábado: 10:30, 13:30 e 16:30).', 'rotina'),
 (5, 'Horário do Robson',
  'O Robson está como "sem horário fixo", mas recebe todo dia "Bancada limpa antes de sair" às 20:00 e, no sábado, "Chegada e grades" às 08:50. Se sair antes, aparece atraso.',
  'Tirar o Robson desses dois checklists ou definir os dias em que ele fecha.', 'rotina'),
 (6, 'O que é "VIX da área gourmet"',
  'O checklist existe, mas o significado de VIX não está claro para a equipe. Hoje ele também não passa pela conferência da gerente.',
  'Renomear com uma descrição clara e decidir se a gerente confere.', 'rotina'),
 (7, 'Quanto a gerente confere (conferência por amostra)',
  'Num dia normal são cerca de 20 conferências para a Jessica. Com a amostra, ela confere só uma parte, sorteada. Checklist com item não feito sempre vai para conferência.',
  '35% (cerca de 7 por dia). Hoje está em 100%.', 'gerente'),
 (8, 'Atraso grave avisa o Robson também?',
  'Atrasos de 30 min ou mais chegam só ao Victor. O Robson recebe apenas o resumo das 21:00.',
  'Ligar "Avisar também o sócio técnico" em Gerente e lembretes, se o Robson deve cobrar junto.', 'gerente'),
 (9, 'Horário de chegada da Jessica e quem confere a abertura',
  'A abertura (Magda, 08:30 às 09:00) é conferida pela gerente, mas a Jessica não tem horário de chegada cadastrado.',
  'Registrar o turno da Jessica em Equipe e confirmar se ela confere a abertura ao chegar.', 'equipe'),
 (10, 'Confirmar as escalas provisórias de revezamento',
  'Porta de vidro e Head Spa (Magda e Suellen), plantas, gradis e grades fechadas estão com escalas provisórias.',
  'Conferir em Rotina e checklists, na escala por dia de cada um.', 'rotina'),
 (11, 'Usuário sistemas@hypebarbearia.com no login',
  'Existe uma conta de acesso com esse e-mail, mas ela não pertence a ninguém da equipe. Ela não vê nada do app.',
  'Se não for usada, pedir ao Claude para apagar a conta.', null)
) v(ordem, titulo, detalhe, sugestao, onde)
where not exists (select 1 from definicoes);

/* ---------------- 7. Segurança ---------------- */
alter function brl(numeric) set search_path = public;
alter function nf_fim(date) set search_path = public;
alter function nf_periodo_atual(date) set search_path = public;
alter function nf_prazo(date) set search_path = public;
alter function nf_rotulo(date) set search_path = public;
revoke execute on function rls_auto_enable() from public, anon, authenticated;
revoke execute on function ajustar_rondas(date) from public, anon, authenticated;

-- A ronda de hoje que caiu em cima dos one-on-ones vai para depois deles
select ajustar_rondas(hoje());
