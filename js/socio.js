/* =========================================================
   Visão dos sócios: painel de acompanhamento a distância
   ========================================================= */
const SNAV = [
  ['Operação', [['painel','Painel','painel'], ['hoje','Linha do dia','hoje'], ['ocorrencias','Ocorrências','alerta']]],
  ['Pessoas', [['equipe','Equipe','equipe'], ['gerente','Gerente e lembretes','sino']]],
  ['Processos', [['pops','Biblioteca de POPs','livro'], ['rotina','Rotina e checklists','rotina']]],
];
const NAV_L = Object.fromEntries(SNAV.flatMap(g => g[1]).map(x => [x[0], x[1]]));
const eyebrow = () => `Sócios · ${DIA_CURTO} · agora ${hm(NOW())}`;

function navBadge(k){
  if (k === 'hoje') { const n = dayStats().atrasado; return n ? `<span class="count bad">${n}</span>` : ''; }
  if (k === 'ocorrencias') { const n = occOpen().length; return n ? `<span class="count">${n}</span>` : ''; }
  if (k === 'pops') { const n = pendingReads().length; return n ? `<span class="count">${n}</span>` : ''; }
  return '';
}

function renderSocio(){
  const v = S.ui.view;
  const side = `<nav class="side" aria-label="Menu">${SNAV.map(([g, items]) => `<div class="side-group">${g}</div>${items.map(([k, l, ic]) =>
    `<button class="nav-item ${v === k ? 'on' : ''}" data-act="nav" data-v="${k}"><span class="row nowrap gap8">${icon(ic)}${l}</span>${navBadge(k)}</button>`).join('')}`).join('')}
    <div class="side-foot">Tudo o que a equipe marca no app aparece aqui na hora, com horário e foto.</div></nav>`;
  const bn = [['painel','Painel','painel'], ['hoje','Dia','hoje'], ['ocorrencias','Ocorrências','alerta'], ['equipe','Equipe','equipe']];
  const bnav = `<nav class="bnav" aria-label="Menu">${bn.map(([k, l, ic]) => `<button class="${v === k ? 'on' : ''}" data-act="nav" data-v="${k}">${icon(ic)}${l}</button>`).join('')}<button class="${!bn.some(x => x[0] === v) ? 'on' : ''}" data-act="more">${icon('mais')}Mais</button></nav>`;
  const sheet = S.ui.more ? `<div class="sheet" data-act="more"><div class="sheet-in" data-stop="1">${SNAV.map(([g, items]) => `<div class="side-group">${g}</div>${items.map(([k, l, ic]) =>
    `<button class="nav-item ${v === k ? 'on' : ''}" data-act="nav" data-v="${k}"><span class="row nowrap gap8">${icon(ic)}${l}</span>${navBadge(k)}</button>`).join('')}`).join('')}</div></div>` : '';
  const page = ({painel:pgPainel, hoje:pgHoje, ocorrencias:pgOcc, equipe:pgEquipe, gerente:pgGerente, pops:pgPops, rotina:pgRotina}[v] || pgPainel)();
  return side + `<main class="work">${page}</main>` + bnav + sheet;
}

/* ---------- Painel ---------- */
function pgPainel(){
  const d = dayStats(), n = NOW(), h = histAgg(x => x.tot), g = gerenteStats();
  const late = S.inst.filter(i => status(i) === 'atrasado').sort((a, b) => a.due - b.due);
  const open = S.inst.filter(i => status(i) === 'aberto').sort((a, b) => a.due - b.due);
  const next = S.inst.filter(i => status(i) === 'agendado' && i.start - n <= 90).sort((a, b) => a.start - b.start);
  const pv = S.inst.filter(needsVer), oo = occOpen(), pr = pendingReads();
  const task = (num, txt, kind, act, v) => `<button class="task ${kind}" data-act="${act}" data-v="${v}"><b>${num}</b><span>${txt}</span></button>`;
  const tasks = [late.length ? task(late.length, late.length === 1 ? 'checklist atrasado agora' : 'checklists atrasados agora', 'bad', 'nav', 'hoje') : '',
    oo.length ? task(oo.length, oo.length === 1 ? 'ocorrência em aberto' : 'ocorrências em aberto', 'warn', 'nav', 'ocorrencias') : '',
    pv.length ? task(pv.length, 'esperando a conferência da gerente', '', 'nav', 'gerente') : '',
    pr.length ? task(pr.length, 'leituras de POP pendentes', '', 'nav', 'pops') : ''].join('');

  // Alertas e padrões
  const ppl = team().map(p => ({p, a:histAgg(x => x.byP[p.id])})).sort((a, b) => a.a.rate - b.a.rate);
  const best = ppl.filter(x => x.a.rate >= .95);
  const slots = S.inst.map(i => ({i, a:histAgg(x => x.bySlot[i.key])})).filter(x => x.a.exp >= 8).sort((a, b) => a.a.rate - b.a.rate)[0];
  const ins = [
    slots && slots.a.rate < .75 ? ['warn', `${tpl(slots.i.tpl).title} das ${hm(slots.i.start)} é o horário mais fraco`, `Feita no prazo em só ${pct(slots.a.rate)} dos dias. Coincide com o almoço da outra atendente, das 14h às 15h: avalie mudar a janela.`] : null,
    pr.length ? ['', `${pr.length} ${pr.length === 1 ? 'pessoa ainda não leu' : 'leituras pendentes de'} POP atualizado`, pr.map(x => `${first(x.who)}: ${x.pop.id} v${x.pop.version}`).join(' · ')] : null,
    best.length ? ['good', `${best.length} de ${ppl.length} pessoas acima de 95% no prazo`, 'Nas últimas 4 semanas. O detalhe por pessoa está em Equipe.'] : null,
  ].filter(Boolean);

  const ph_ = photos().slice(0, 8);
  const resumoAt = toMin(S.rules.resumo), sent = n >= resumoAt;
  return `${ph('Sócios · painel', 'A operação de hoje', `${DIA_LABEL[0].toUpperCase() + DIA_LABEL.slice(1)}. Agora são ${hm(n)}. Tudo o que a equipe marca no app aparece aqui na hora.`)}
    ${avisoInicio()}
    ${tasks ? `<section class="tasks"><h2>Precisa de atenção</h2><div class="task-row">${tasks}</div></section>` : `<p class="callout good"><b>Tudo em dia.</b> Nenhum atraso, ocorrência aberta ou conferência pendente.</p>`}
    <div class="grid kpis">
      ${kpi('Conformidade hoje', rateTxt(d.rate), `${d.ok} de ${d.due} checklists vencidos foram feitos no prazo`, rateKind(d.rate), bar(d.rate, rateKind(d.rate), S.rules.meta))}
      ${kpi('Checklists do dia', `${d.done} de ${d.total}`, `${d.atrasado} atrasados · ${d.aberto} abertos · ${d.agendado} agendados`)}
      ${kpi('Média de 4 semanas', rateTxt(h.rate), h.exp ? `${pct(h.doneRate)} feitos, contando os atrasados` : 'Aparece depois do primeiro dia completo', rateKind(h.rate))}
      ${kpi('Rondas da gerente', `${g.ronDone.length} de ${g.ron.length}`, g.ronItems.length ? `${g.ronOk} de ${g.ronItems.length} itens conformes` : 'Primeira ronda às 12:00')}
      ${kpi('Gerente atendeu', rateTxt(g.rate), `${g.got} de ${g.exp} lembretes: conferir, cobrar, rondas e fixos`, rateKind(g.rate))}
    </div>
    <div class="grid cols-2">
      <section class="panel"><div class="panel-h"><h2>Agora na barbearia</h2><button class="linkbtn small" data-act="nav" data-v="hoje">Ver o dia inteiro</button></div>
        <div class="stack gap8">
          ${late.length ? `<p class="day-h">Atrasados</p>${late.map(i => instCard(i) + (lateMin(i) >= S.rules.escalar ? `<p class="small bad-t esc">Escalado aos sócios: ${mins(lateMin(i))} de atraso${nudgesOf(i.id).length ? ', já cobrado pela gerente' : ', sem cobrança da gerente'}.</p>` : '')).join('')}` : ''}
          ${open.length ? `<p class="day-h">Abertos agora</p>${open.map(i => instCard(i)).join('')}` : ''}
          ${next.length ? `<p class="day-h">Próximos 90 minutos</p>${next.map(i => instCard(i)).join('')}` : ''}
          ${!late.length && !open.length && !next.length ? `<p class="muted">${n >= DAY_END - 15 ? 'O dia acabou. Veja o resumo abaixo.' : 'Nada aberto ou previsto para os próximos 90 minutos.'}</p>` : ''}
        </div></section>
      <section class="panel"><div class="panel-h"><h2>Alertas e padrões</h2><p>últimas 4 semanas</p></div>
        <div class="insights">${ins.map(([k, t, s]) => `<div class="ins"><span class="dot" style="background:var(--${k === 'bad' ? 'bad' : k === 'warn' ? 'warn' : k === 'good' ? 'good' : 'accent'})"></span><div><b>${esc(t)}</b><p>${esc(s)}</p></div></div>`).join('')}</div></section>
    </div>
    <div class="grid cols-2">
      <section class="panel"><div class="panel-h"><h2>Conformidade por dia</h2><p>checklists feitos no prazo ÷ previstos</p></div>${dailyChart()}
        <div class="legend"><span><i class="dot" style="background:var(--good)"></i>na meta</span><span><i class="dot" style="background:var(--accent)"></i>até 10 p.p. abaixo</span><span><i class="dot" style="background:var(--bad)"></i>mais de 10 p.p. abaixo</span><span><i class="dash"></i>meta</span></div></section>
      <section class="panel"><div class="panel-h"><h2>Fotos de hoje</h2><p>${photos().length} registradas</p></div>
        ${ph_.length ? `<div class="photos">${ph_.map(x => `<button class="ph-fig" data-act="open" data-id="${x.i.id}">${photo(x.it.t, x.at, x.path)}<span class="small"><b>${esc(x.it.t)}</b></span><span class="small muted">${esc(first(person(x.i.who)))} · ${hm(x.at)}</span></button>`).join('')}</div>` : '<p class="muted">Nenhuma foto ainda.</p>'}</section>
    </div>
    <section class="panel"><div class="panel-h"><h2>Resumo diário no WhatsApp</h2><p>${sent ? `enviado às ${S.rules.resumo}` : `prévia, envio às ${S.rules.resumo}`}</p></div><div class="wa" id="wa-text">${resumo()}</div><div class="row" style="margin-top:10px"><button class="btn sm" data-act="copiar">Copiar para o WhatsApp</button></div></section>`;
}

function resumo(){
  const d = dayStats(), g = gerenteStats(), oo = S.occ.filter(o => !o.day && vis(o.at));
  const ppl = team().map(p => ({p, s:dayStats(i => i.who === p.id)})).filter(x => x.s.due);
  const top = ppl.filter(x => x.s.ok === x.s.due).map(x => first(x.p)), att = S.inst.filter(i => status(i) === 'atrasado').map(i => `${tpl(i.tpl).title} das ${hm(i.start)}`);
  return esc(`*Hype · ${DIA_CURTO}${NOW() < toMin(S.rules.resumo) ? ` (até ${hm(NOW())})` : ''}*
Conformidade: ${rateTxt(d.rate)} no prazo (${d.ok} de ${d.due} checklists)
Com atraso: ${d.tarde} · Atrasados agora: ${d.atrasado}
Ocorrências: ${oo.length} novas, ${oo.filter(o => o.status === 'resolvida').length} resolvidas
Rondas da gerente: ${g.ronDone.length} de ${g.ron.length}${g.ronItems.length ? ` (${g.ronOk} de ${g.ronItems.length} itens conformes)` : ''}
Conferências: ${g.ver.length} de ${g.verList.length} · tempo médio ${mins(g.verAvg)}
${top.length ? `Tudo no prazo hoje: ${top.length} de ${ppl.length} pessoas\n` : ''}${att.length ? `Atrasado agora: ${att.join(', ')}\n` : ''}Abrir o painel: ${location.origin + location.pathname}`);
}

/* ---------- Linha do dia ---------- */
function pgHoje(){
  const f = S.ui.f.st || 'todos', fp = S.ui.f.p || 'todos', n = NOW();
  const span = DAY_END - DAY_START, x = m => (clamp(m, DAY_START, DAY_END) - DAY_START) / span * 100;
  const rows = team().map(p => {
    const list = S.inst.filter(i => i.who === p.id);
    return `<div class="tl-row"><button class="tl-who" data-act="f" data-k="p" data-v="${fp === p.id ? 'todos' : p.id}">${av(p)}<span>${esc(first(p))}</span></button><div class="tl-track">${list.map(i => {
      const s = status(i), end = isDone(i) ? Math.max(i.doneAt, i.due) : s === 'atrasado' ? n : i.due;
      return `<button class="tl-b ${ST[s].k || 'sched'}" style="left:${x(i.start)}%;width:${Math.max(x(end) - x(i.start), .9)}%" data-act="open" data-id="${i.id}" title="${hm(i.start)} ${tpl(i.tpl).title}: ${ST[s].l}"><span class="sr">${tpl(i.tpl).title}</span></button>`;
    }).join('')}<span class="tl-now" style="left:${x(n)}%"></span></div></div>`;
  }).join('');
  const axis = `<div class="tl-row axis"><span></span><div class="tl-track bare">${Array.from({length:14}, (_, k) => `<span style="left:${x(DAY_START + k * 60)}%">${8 + k}h</span>`).join('')}</div></div>`;
  let list = S.inst.filter(i => fp === 'todos' || i.who === fp);
  const fs = {atrasados:i => status(i) === 'atrasado', abertos:i => status(i) === 'aberto', feitos:i => isDone(i), proximos:i => status(i) === 'agendado'}[f];
  if (fs) list = list.filter(fs);
  list.sort((a, b) => a.start - b.start || a.who.localeCompare(b.who));
  const groups = {}; list.forEach(i => (groups[Math.floor(i.start / 60)] ??= []).push(i));
  const d = dayStats();
  return `${ph(eyebrow(), 'Linha do dia', 'Cada barra é um checklist na sua janela de horário. Toque para ver os itens, os horários e as fotos.')}
    <section class="panel"><div class="panel-h"><h2>Por pessoa</h2><div class="legend"><span><i class="dot" style="background:var(--good)"></i>no prazo</span><span><i class="dot" style="background:var(--warn)"></i>com atraso</span><span><i class="dot" style="background:var(--bad)"></i>atrasado</span><span><i class="dot" style="background:var(--accent)"></i>aberto</span><span><i class="dot" style="background:var(--line)"></i>agendado</span><span><i class="dash"></i>agora</span></div></div>
      <div class="tl-wrap"><div class="tl">${axis}${rows}</div></div></section>
    <section class="panel"><div class="panel-h"><div class="row gap8">${segUi('st', [['todos', `Todos ${d.total}`], ['atrasados', `Atrasados ${d.atrasado}`], ['abertos', `Abertos ${d.aberto}`], ['feitos', `Feitos ${d.done}`], ['proximos', `Próximos ${d.agendado}`]], f)}
      <label class="sr" for="f-p">Pessoa</label><select class="inp w-auto" id="f-p" data-f="p"><option value="todos">Toda a equipe</option>${team().map(p => `<option value="${p.id}" ${fp === p.id ? 'selected' : ''}>${esc(p.name)}</option>`).join('')}</select></div></div>
      ${list.length ? Object.entries(groups).map(([h, arr]) => `<p class="day-h">${h}h</p><div class="stack gap6">${arr.map(i => instCard(i)).join('')}</div>`).join('') : '<p class="muted">Nada com esse filtro.</p>'}</section>`;
}

/* ---------- Ocorrências ---------- */
function pgOcc(){
  const f = S.ui.f.oc || 'abertas';
  const all = S.occ.filter(occVis), list = all.filter(o => f === 'todas' || (f === 'abertas' ? o.status !== 'resolvida' : o.status === 'resolvida'));
  return `${ph(eyebrow(), 'Ocorrências', 'Tudo o que saiu do padrão: item não feito, item reprovado na ronda e reclamação de cliente. A gerente registra a ação; você acompanha.')}
    <div class="grid kpis">${kpi('Em aberto', occOpen().length, 'aberta ou em tratamento', occOpen().length ? 'warn' : 'good')}${kpi('Hoje', all.filter(o => !o.day).length, 'abertas hoje')}${kpi('Resolvidas', all.filter(o => o.status === 'resolvida').length, 'nos últimos dias')}</div>
    <div class="row between">${segUi('oc', [['abertas','Em aberto'], ['resolvidas','Resolvidas'], ['todas','Todas']], f)}</div>
    <div class="stack gap8">${list.length ? list.map(o => occCard(o, {edit:true})).join('') : '<p class="muted">Nenhuma ocorrência aqui.</p>'}</div>`;
}

/* ---------- Equipe ---------- */
const mailIn = p => sou_socio_ui() ? `<label class="sr" for="em-${p.id}">E-mail de ${esc(p.name)}</label><input class="inp mail" type="email" id="em-${p.id}" data-email="${p.id}" value="${esc(p.email)}" placeholder="sem acesso">` : esc(p.email || 'sem acesso');
const sou_socio_ui = () => { const p = me(); return p && (p.role === 'socio' || p.socio); };

function pgEquipe(){
  const sel = S.ui.selP;
  const rows = team().map(p => {
    const d = dayStats(i => i.who === p.id), a = histAgg(x => x.byP[p.id]), pr = pendingReads(p.id).length;
    return `<tr class="${sel === p.id ? 'sel' : ''}"><td><button class="who-cell linkrow" data-act="selP" data-v="${p.id}">${av(p)}<span><b>${esc(p.name)}</b><span class="small muted block">${roleL(p)} · ${esc(p.turno)}</span></span></button></td>
      <td class="num">${d.done} de ${d.total}${d.atrasado ? ` ${chip(d.atrasado + ' atrasado', 'bad')}` : ''}</td>
      <td class="num"><span class="${rateKind(a.rate)}-t"><b>${rateTxt(a.rate)}</b></span></td><td class="num">${a.late}</td><td class="num">${a.miss}</td>
      <td>${dots(p.id)}</td><td class="num">${streak(p.id)} ${streak(p.id) === 1 ? 'dia' : 'dias'}</td>
      <td>${pr ? chip(pr + ' pendente', 'warn') : chip('em dia', 'good')}</td><td>${mailIn(p)}</td></tr>`;
  }).join('');
  const p = sel && person(sel);
  return `${ph(eyebrow(), 'Equipe', 'Quem cumpre a rotina no prazo, quem atrasa e quem ainda não leu as versões novas dos POPs.')}
    <section class="panel"><div class="tw"><table class="t"><thead><tr><th>Pessoa</th><th class="num">Hoje</th><th class="num">No prazo, 4 sem.</th><th class="num">Com atraso</th><th class="num">Não feitos</th><th>Últimos 24 dias</th><th class="num">Sequência</th><th>Termo de ciência</th><th>E-mail de acesso</th></tr></thead><tbody>${rows}</tbody></table></div>
      <p class="small muted pager-info">Cada tracinho é um dia: verde, tudo no prazo; âmbar, algo com atraso; vermelho, algo não feito. Sequência conta os dias seguidos com tudo no prazo.</p></section>
    ${p ? `<section class="panel"><div class="panel-h"><div class="row nowrap gap8">${av(p, true)}<div><h2>${esc(p.name)}</h2><p>${roleL(p)} · ${esc(p.turno)}</p></div></div><button class="btn sm" data-act="selP" data-v="">Fechar</button></div>
      <div class="grid cols-eq"><div class="stack gap6"><p class="day-h">Checklists de hoje</p>${S.inst.filter(i => i.who === p.id).sort((a, b) => a.start - b.start).map(i => instCard(i, {who:false})).join('')}</div>
      <div class="stack gap6"><p class="day-h">Ocorrências</p>${S.occ.filter(o => o.who === p.id && occVis(o)).map(o => occCard(o)).join('') || '<p class="muted small">Nenhuma ocorrência recente.</p>'}
      <p class="day-h">POPs do cargo</p><div class="row gap6">${S.pops.filter(x => popPeople(x).some(y => y.id === p.id)).map(x => { const ok = (x.reads[p.id] || 0) >= x.version; return `<button class="chip ${ok ? 'good' : 'warn'} linkchip" data-act="pop" data-id="${x.id}">${x.id} ${ok ? 'lido' : 'pendente'}</button>`; }).join('')}</div></div></div></section>`
      : '<p class="small muted">Toque no nome de alguém para ver o dia, as ocorrências e os POPs da pessoa. O e-mail é o que a pessoa usa para entrar no app.</p>'}`;
}

/* ---------- Gerente e lembretes ---------- */
function pgGerente(){
  const g = gerenteStats(), j = person('jessica'), log = gerenteLog(), r = S.rules;
  const ownRate = g.own.length ? g.ownOk.length / g.own.length : null;
  return `${ph(eyebrow(), 'Gerente e lembretes', `${j.name} é quem garante a rotina na loja. O sistema lembra ela do que conferir e de quem cobrar, e mede se os lembretes foram atendidos.`)}
    <div class="grid kpis">
      ${kpi('Lembretes atendidos', rateTxt(g.rate), `${g.got} de ${g.exp} até agora`, rateKind(g.rate), bar(g.rate, rateKind(g.rate), r.meta))}
      ${kpi('Conferências', `${g.ver.length} de ${g.verList.length}`, g.ver.length ? `${mins(g.verAvg)} em média para conferir (limite ${r.conferir} min)` : 'Nenhuma ainda', g.verAvg > r.conferir ? 'warn' : '')}
      ${kpi('Atrasos cobrados', `${g.nudged.length} de ${g.late.length}`, g.nudged.length ? `${mins(g.nudgeAvg)} em média depois do prazo` : 'Nenhum atraso até agora', g.nudged.length < g.late.length ? 'warn' : '')}
      ${kpi('Rondas', `${g.ronDone.length} de ${g.ron.length}`, g.ronItems.length ? `${g.ronOk} de ${g.ronItems.length} itens conformes` : 'Primeira às 12:00')}
      ${kpi('Checklists dela', `${g.ownOk.length} de ${g.own.length}`, 'no prazo, dos que já venceram', rateKind(ownRate))}
    </div>
    <div class="grid cols-2">
      <section class="panel"><div class="panel-h"><h2>O que a gerente fez hoje</h2><p>${log.length} registros</p></div>
        ${log.length ? `<ol class="log">${log.map(e => `<li class="${e.k}"><span class="num">${hm(e.at)}</span><div><b>${esc(e.t)}</b><p class="small muted">${esc(e.s)}</p></div></li>`).join('')}</ol>` : '<p class="muted">Nada ainda.</p>'}</section>
      <div class="stack gap14">
        <section class="panel"><div class="panel-h"><h2>Regras dos lembretes</h2><p>valem para todos os dias</p></div>
          <div class="stack gap14">
            <div class="rule"><div><b>Início da operação</b><p class="small muted">A partir desta data o app cria os checklists de cada dia</p></div><input class="inp w-auto" type="date" id="r-inicio" data-rule="inicio" data-kind="str" value="${r.inicio || ''}"></div>
            <div class="rule"><div><b>Antes dos checklists dela</b><p class="small muted">Avisar quantos minutos antes da janela abrir</p></div><div class="affix w-num"><input type="number" id="r-antes" data-rule="antes" value="${r.antes}" min="0"><span>min</span></div></div>
            <div class="rule"><div><b>Escalar atraso aos sócios</b><p class="small muted">Se o checklist continuar atrasado depois de</p></div><div class="affix w-num"><input type="number" id="r-escalar" data-rule="escalar" value="${r.escalar}" min="5"><span>min</span></div></div>
            <div class="rule"><div><b>Prazo para conferir</b><p class="small muted">Depois que a pessoa conclui, a gerente confere em até</p></div><div class="affix w-num"><input type="number" id="r-conferir" data-rule="conferir" value="${r.conferir}" min="5"><span>min</span></div></div>
            <div class="rule"><div><b>Meta de conformidade</b><p class="small muted">Abaixo disso o número fica âmbar ou vermelho</p></div><div class="affix w-num"><input type="number" id="r-meta" data-rule="meta" data-kind="pct" value="${Math.round(r.meta * 100)}" min="50" max="100"><span>%</span></div></div>
            <label class="toggle"><input type="checkbox" id="r-rondas" data-rule="rondas" data-kind="bool" ${r.rondas ? 'checked' : ''}><span><b>Rondas surpresa</b><span>Duas por dia, em horário sorteado pelo sistema. A equipe não sabe quando.</span></span></label>
            <div class="rule"><div><b>Resumo no WhatsApp dos sócios</b><p class="small muted">Horário de envio</p></div><input class="inp w-auto" type="time" id="r-resumo" data-rule="resumo" data-kind="str" value="${r.resumo}"></div>
          </div></section>
        <section class="panel"><div class="panel-h"><h2>Lembretes fixos</h2><p>além dos automáticos</p></div>
          <div class="stack gap6">${S.reminders.map(x => `<div class="rem ${x.on ? '' : 'off'}"><span class="num"><b>${x.at}</b></span><span class="grow">${esc(x.text)}</span>${vis(S.remDone[x.id]) ? chip('feito ' + hm(S.remDone[x.id]), 'good') : toMin(x.at) <= NOW() && x.on ? chip('pendente', 'warn') : ''}
            <label class="toggle sm" title="Ativo"><input type="checkbox" id="rem-${x.id}" data-rem="${x.id}" ${x.on ? 'checked' : ''}><span class="sr">Ativo</span></label></div>`).join('')}</div>
          <form class="row gap6 add-rem" data-form="rem"><label class="sr" for="nr-at">Hora</label><input class="inp w-auto" type="time" id="nr-at" value="16:00" required><label class="sr" for="nr-t">Lembrete</label><input class="inp grow" id="nr-t" placeholder="Ex.: Conferir o estoque de lâminas" required><button class="btn sm primary">Adicionar</button></form></section>
      </div>
    </div>`;
}

/* ---------- Biblioteca de POPs ---------- */
function pgPops(){
  if (S.ui.pop) {
    const p = pop(S.ui.pop);
    return `<div class="row"><button class="btn sm" data-act="popClose">${icon('voltar', 'ni xs')}Biblioteca</button></div>
      ${ph(eyebrow(), `${p.id} · ${esc(p.title)}`, '', `<button class="btn" data-act="bump" data-id="${p.id}">Publicar nova versão</button>`)}
      <section class="panel">${popBody(p, me())}</section>
      <p class="small muted">Publicar nova versão pede que todos do cargo leiam de novo e confirmem no app. No sistema real, aqui também se edita o texto de cada passo.</p>`;
  }
  const byArea = {}; S.pops.forEach(p => (byArea[p.area] ??= []).push(p));
  return `${ph(eyebrow(), 'Biblioteca de POPs', `POP HYPE versão 1.0, outubro de 2026. ${S.pops.length} seções, do abrir ao fechar. A equipe assina o termo de ciência de cada versão no app.`)}
    <section class="panel cultura"><div class="panel-h"><h2>Cultura HYPE</h2><p>por que fazemos as coisas do jeito HYPE</p></div>
      <div class="grid cols-eq"><div class="stack gap4"><p class="eyebrow">Missão</p><p>${esc(CULTURA.missao)}</p></div><div class="stack gap4"><p class="eyebrow">Visão</p><p>${esc(CULTURA.visao)}</p></div></div>
      <div class="valores">${CULTURA.valores.map(([n, d, f], k) => `<div class="valor"><span class="cid">0${k + 1}</span><b>${n}</b><span class="small">${esc(d)}</span><span class="small muted">"${esc(f)}"</span></div>`).join('')}</div></section>
    <details class="panel newpop"><summary>Novo POP</summary>
      <form class="stack gap8" data-form="pop"><div class="form-grid">
        <div class="field span2"><label for="np-t">Título</label><input class="inp" id="np-t" required placeholder="Ex.: Atendimento de criança"></div>
        <div class="field"><label for="np-a">Área</label><select class="inp" id="np-a">${Object.entries(AREAS).map(([k, l]) => `<option value="${k}">${l}</option>`).join('')}</select></div>
        <div class="field"><label for="np-r">Quem faz</label><select class="inp" id="np-r"><option value="barbeiro">Barbeiros</option><option value="atendente">Atendentes</option><option value="gerente">Gerente</option><option value="todos">Todos</option></select></div>
        <div class="field"><label for="np-f">Quando</label><input class="inp" id="np-f" placeholder="Ex.: A cada cliente"></div></div>
        <div class="field"><label for="np-o">Objetivo</label><input class="inp" id="np-o" placeholder="O que esse procedimento garante?"></div>
        <div class="field"><label for="np-s">Passo a passo, um por linha. Comece com ! os passos críticos.</label><textarea class="inp" id="np-s" rows="5" placeholder="Receber a criança e o responsável pelo nome&#10;!Confirmar com o responsável o corte desejado"></textarea></div>
        <div><button class="btn primary">Publicar POP</button></div></form></details>
    <div class="grid pop-grid">${S.pops.map(p => {
      const ppl = popPeople(p), read = ppl.filter(x => (p.reads[x.id] || 0) >= p.version).length;
      return `<button class="pop-card" data-act="pop" data-id="${p.id}"><span class="row between nowrap"><span class="cid">${p.id} · ${AREAS[p.area]}</span>${chip('v' + p.version)}</span><b>${esc(p.title)}</b><span class="small muted">${esc(p.who)}</span><span class="small muted">${esc(p.freq)}</span>
        <span class="row between nowrap small"><span>${p.steps.length} passos${p.steps.some(s => s.crit) ? ` · ${p.steps.filter(s => s.crit).length} críticos` : ''}</span><span class="${read < ppl.length ? 'warn-t' : 'good-t'}">${read} de ${ppl.length} assinaram</span></span></button>`;
    }).join('')}</div>`;
}

/* ---------- Rotina ---------- */
function pgRotina(){
  const rows = S.tpls.flatMap(t => t.slots.map((s, k) => ({t, s, k}))).sort((a, b) => toMin(a.s[0]) - toMin(b.s[0]));
  const whoOpt = (cur, t) => t.each ? `<span class="muted">${Array.isArray(t.each) ? t.each.map(id => first(person(id))).join(' e ') : 'Cada barbeiro presente'}</span>` : t.also ? `<span>${[cur.s[2], ...t.also].map(id => first(person(id))).join(' e ')}</span>` : `<label class="sr" for="sw-${t.id}-${cur.k}">Responsável</label><select class="inp w-auto" id="sw-${t.id}-${cur.k}" data-slot="${t.id}|${cur.k}|2">${team().map(p => `<option value="${p.id}" ${cur.s[2] === p.id ? 'selected' : ''}>${esc(p.name)}</option>`).join('')}</select>`;
  return `${ph(eyebrow(), 'Rotina e checklists', 'A agenda fixa da semana. Toda madrugada o sistema cria os checklists do dia a partir daqui. Mudanças valem a partir de amanhã.')}
    <section class="panel"><div class="tw"><table class="t rot"><thead><tr><th>Janela</th><th>Checklist</th><th>POP</th><th>Responsável</th><th>Dias</th><th class="num">Itens</th><th>Conferência</th></tr></thead><tbody>
      ${rows.map(r => `<tr><td class="nowrap"><label class="sr" for="ss-${r.t.id}-${r.k}">Início</label><input class="inp time" type="time" id="ss-${r.t.id}-${r.k}" data-slot="${r.t.id}|${r.k}|0" value="${r.s[0]}"> às <label class="sr" for="sd-${r.t.id}-${r.k}">Prazo</label><input class="inp time" type="time" id="sd-${r.t.id}-${r.k}" data-slot="${r.t.id}|${r.k}|1" value="${r.s[1]}"></td>
        <td><b>${esc(r.t.title)}</b>${r.t.kind === 'ronda' ? ` ${chip('ronda', 'acc')}` : ''}</td><td><button class="chip linkchip" data-act="pop" data-id="${r.t.pop}">${r.t.pop}</button></td><td>${whoOpt(r, r.t)}</td>
        <td class="small">${r.t.days.length === 6 ? 'seg a sáb' : r.t.days.map(d => WEEK[d]).join(', ')}${r.t.every2 ? ', quinzenal' : ''}</td>
        <td class="num">${r.t.items.length}${r.t.items.some(i => i.photo) ? ` <span class="small muted">· ${r.t.items.filter(i => i.photo).length} com foto</span>` : ''}</td>
        <td>${r.t.verify ? chip('gerente confere', 'good') : chip(r.t.kind === 'ronda' ? 'é a própria conferência' : 'sem conferência')}</td></tr>`).join('')}
    </tbody></table></div></section>
    <div class="grid cols-eq">
      <section class="panel"><div class="panel-h"><h2>Turnos e folgas</h2><p>POP, pág. 6</p></div><div class="tw"><table class="t"><thead><tr><th>Profissional</th><th>Turno</th><th>Folga</th></tr></thead><tbody>${ESCALA.turnos.map(([id, t, f]) => `<tr><td><span class="who-cell">${av(person(id))}${esc(person(id).name)}</span></td><td class="small">${esc(t)}</td><td class="small">${esc(f)}</td></tr>`).join('')}</tbody></table></div>
        <p class="small muted pager-info">${esc(ESCALA.horario)} ${esc(ESCALA.posicoes)}</p></section>
      <section class="panel"><div class="panel-h"><h2>Rodízios</h2><p>viram checklist nos dias certos</p></div><div class="tw"><table class="t"><thead><tr><th>Tarefa</th><th>Quando</th><th>Quem</th></tr></thead><tbody>${ESCALA.rodizios.map(r => `<tr><td>${esc(r[0])}</td><td class="small nowrap">${esc(r[1])}</td><td class="small">${esc(r[2])}</td></tr>`).join('')}</tbody></table></div></section>
    </div>
    <section class="panel"><div class="panel-h"><h2>Reuniões</h2><p>POP-10 · a gerente registra que aconteceu e quem esteve</p></div><div class="tw"><table class="t"><thead><tr><th>Dia</th><th>Horário</th><th>Reunião</th><th>Frequência</th></tr></thead><tbody>${ESCALA.reunioes.map(r => `<tr><td>${r[0]}</td><td class="nowrap num">${r[1]}</td><td>${esc(r[2])}</td><td class="small">${esc(r[3])}</td></tr>`).join('')}</tbody></table></div></section>
    <section class="panel" id="itens"><div class="panel-h"><h2>Itens de cada checklist</h2><p>Marque quais itens exigem foto. A pessoa só consegue marcar o item tirando a foto.</p></div><div class="grid cols-eq">${S.tpls.map(t => `<div class="tpl-box"><div class="row between nowrap"><b>${esc(t.title)}</b><span class="cid">${t.pop}</span></div><ol class="steps sm">${t.items.map(it => `<li><span>${esc(it.t)}${it.crit ? ' <span class="tag crit">crítico</span>' : ''}</span><label class="ph-toggle ${it.photo ? 'on' : ''}" for="ph-${t.id}-${it.id}"><input type="checkbox" id="ph-${t.id}-${it.id}" data-photo="${t.id}|${it.id}" ${it.photo ? 'checked' : ''}>${icon('camera', 'ni xs')}foto</label></li>`).join('')}</ol></div>`).join('')}</div></section>`;
}
