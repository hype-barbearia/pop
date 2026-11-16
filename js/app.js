/* =========================================================
   App de celular: gerente, barbeiros e atendentes
   ========================================================= */
const TABS = {
  gerente:[['agora','Agora','sino'], ['equipe','Equipe','equipe'], ['ocorrencias','Ocorrências','alerta'], ['pops','POPs','livro']],
  equipe:[['hoje','Hoje','check'], ['pops','POPs','livro'], ['hist','Histórico','hist']],
};
const greet = () => NOW() < 12 * 60 ? 'Bom dia' : NOW() < 18 * 60 ? 'Boa tarde' : 'Boa noite';

function renderPhone(p){
  const isG = p.role === 'gerente', tabs = TABS[isG ? 'gerente' : 'equipe'];
  let body;
  if (S.ui.open && inst(S.ui.open)) body = scInst(p);
  else if (S.ui.pop) body = scPop(p);
  else body = ({agora:gAgora, equipe:gEquipe, ocorrencias:gOcc, pops:mPops, hoje:eHoje, hist:eHist}[S.ui.tab] || (isG ? gAgora : eHoje))(p);
  const feedN = isG ? gerenteFeed().filter(f => f.k === 'bad' || f.k === 'warn').length : 0;
  const myReads = pendingReads(p.id).length;
  return `<div class="phone">
    <div class="p-top">${av(p, true)}<div class="grow"><b>${esc(p.name)}</b><span>${roleL(p)} · ${esc(p.turno)}</span></div>${p.socio ? `<button class="btn sm" data-act="asSocio">Painel dos sócios</button>` : ''}<div class="p-clock"><b class="num">${hm(NOW())}</b><span>${DIA_CURTO}</span></div></div>
    <div class="p-body">${body}</div>
    <nav class="tabbar" aria-label="Abas">${tabs.map(([k, l, ic]) => { const n = k === 'agora' ? feedN : k === 'pops' ? myReads : 0;
      return `<button class="${S.ui.tab === k && !S.ui.open && !S.ui.pop ? 'on' : ''}" data-act="tab" data-v="${k}"><span class="tab-ic">${icon(ic)}${n ? `<span class="count bad">${n}</span>` : ''}</span>${l}</button>`; }).join('')}</nav></div>`;
}

const backBtn = () => `<button class="back" data-act="close">${icon('voltar', 'ni xs')}Voltar</button>`;

function scInst(p){
  const i = inst(S.ui.open), t = tpl(i.tpl), mode = mine(i, p.id) ? 'exec' : p.role === 'gerente' ? 'verify' : 'view';
  return `${backBtn()}<div><p class="eyebrow">${t.kind === 'ronda' ? 'Ronda' : 'Checklist'} · ${t.pop}</p><h1 class="p-title">${esc(t.title)}</h1></div>${instBody(i, mode)}`;
}
function scPop(p){
  const x = pop(S.ui.pop);
  return `${backBtn()}<div><p class="eyebrow">${x.id}</p><h1 class="p-title">${esc(x.title)}</h1></div>${popBody(x, p)}`;
}

/* ---------- Gerente: Agora ---------- */
function gAgora(p){
  const d = dayStats(), feed = gerenteFeed(), mine = S.inst.filter(i => i.who === p.id).sort((a, b) => a.start - b.start);
  const late = feed.filter(f => f.k === 'bad').length, conf = S.inst.filter(needsVer).length;
  const fixed = S.reminders.filter(r => r.on).sort((a, b) => toMin(a.at) - toMin(b.at));
  return `<div class="hero"><div class="ring-wrap">${ring(d.rate, 92)}<div class="stack gap4"><b class="big2">${greet()}, ${esc(first(p))}</b>
      <span class="small muted">Conformidade da loja hoje: ${d.ok} de ${d.due} no prazo.</span><span class="small">${late ? `<b class="bad-t">${late} ${late === 1 ? 'atraso' : 'atrasos'}</b> · ` : ''}${conf} para conferir</span></div></div></div>
    ${avisoPush()}${avisoInicio()}${avisoFechado()}<section class="stack gap8"><h2 class="sec-h">Lembretes agora</h2>${feed.length ? feed.map(feedCard).join('') : '<p class="callout good"><b>Nada pendente.</b> A loja está no padrão.</p>'}</section>
    <section class="stack gap8"><h2 class="sec-h">Seus checklists de hoje</h2>${mine.map(i => instCard(i, {who:false})).join('')}</section>
    <section class="card"><h3>Lembretes fixos</h3>${fixed.map(r => { const done = vis(S.remDone[r.id]), due = toMin(r.at) <= NOW();
      return `<div class="rem"><span class="num"><b>${r.at}</b></span><span class="grow">${esc(r.text)}</span>${done ? chip('feito ' + hm(S.remDone[r.id]), 'good') : due ? `<button class="btn sm primary" data-act="remDone" data-id="${r.id}">Feito</button>` : chip('mais tarde')}</div>`; }).join('')}</section>`;
}
function feedCard(f){
  const acts = [f.nudge ? `<button class="btn sm no" data-act="nudge" data-id="${f.nudge}">Cobrar agora</button>` : '', f.open ? `<button class="btn sm" data-act="open" data-id="${f.open}">Abrir</button>` : '',
    f.rem ? `<button class="btn sm primary" data-act="remDone" data-id="${f.rem}">Marcar como feito</button>` : '', f.occ ? `<button class="btn sm" data-act="tab" data-v="ocorrencias">Tratar</button>` : '',
    f.tab ? `<button class="btn sm" data-act="tab" data-v="${f.tab}">Ver equipe</button>` : ''].join('');
  return `<div class="notif ${f.k}"><span class="nd"></span><div class="grow stack gap4"><b>${esc(f.title)}</b><p class="small muted">${esc(f.sub)}</p>${acts ? `<div class="row gap6">${acts}</div>` : ''}</div></div>`;
}

/* ---------- Gerente: Equipe ---------- */
function gEquipe(p){
  const ppl = team().filter(x => x.id !== p.id), pr = pendingReads();
  return `<div><p class="eyebrow">Equipe hoje</p><h1 class="p-title">Quem fez o quê</h1></div>
    ${pr.length ? `<div class="notice warn"><span><b>${pr.length} termos de ciência pendentes:</b> ${(() => { const by = {}; pr.forEach(x => by[first(x.who)] = (by[first(x.who)] || 0) + 1); return Object.entries(by).map(([n, c]) => `${esc(n)} (${c})`).join(', '); })()}. Cobre na reunião ou no WhatsApp.</span></div>` : ''}
    ${ppl.map(x => { const d = dayStats(i => i.who === x.id), list = S.inst.filter(i => i.who === x.id).sort((a, b) => a.start - b.start);
      return `<section class="card"><div class="row between nowrap"><div class="row nowrap gap8">${av(x)}<div><b>${esc(x.name)}</b><p class="small muted">${roleL(x)} · ${esc(x.turno)}</p></div></div>${d.atrasado ? chip(d.atrasado + ' atrasado', 'bad') : chip(`${d.ok} de ${d.due} no prazo`, rateKind(d.rate))}</div>
        <div class="stack gap6">${list.map(i => instCard(i, {who:false})).join('') || '<p class="small muted">Nenhum checklist hoje.</p>'}</div></section>`; }).join('')}
    ${blocoAusencias()}`;
}

/* ---------- Gerente: Ocorrências ---------- */
function gOcc(p){
  const list = S.occ.filter(occVis).sort((a, b) => (a.status === 'resolvida') - (b.status === 'resolvida'));
  return `<div><p class="eyebrow">Ocorrências</p><h1 class="p-title">O que saiu do padrão</h1></div>
    ${formOcorrencia(true)}
    ${list.map(o => occCard(o, {edit:canManage()})).join('') || '<p class="muted small">Nenhuma ocorrência nos últimos 30 dias.</p>'}`;
}

/* ---------- POPs (todos) ---------- */
function mPops(p){
  const mineF = x => x.roles.includes('todos') || x.roles.includes(p.role);
  const mine = S.pops.filter(mineF), other = S.pops.filter(x => !mineF(x));
  const card = x => { const pend = popPeople(x).some(y => y.id === p.id) && (x.reads[p.id] || 0) < x.version;
    return `<button class="pop-row" data-act="pop" data-id="${x.id}"><span class="cid">${x.id}</span><span class="grow"><b>${esc(x.title)}</b><span class="sub">${esc(x.freq)}</span></span>${pend ? chip('ler v' + x.version, 'warn') : chip('v' + x.version)}</button>`; };
  return `<div><p class="eyebrow">Procedimentos</p><h1 class="p-title">POPs da Hype</h1></div>
    <section class="stack gap6"><h2 class="sec-h">Do seu cargo</h2>${mine.map(card).join('')}</section>
    ${other.length ? `<section class="stack gap6"><h2 class="sec-h">Outros cargos</h2>${other.map(card).join('')}</section>` : ''}`;
}

/* ---------- Equipe: Hoje ---------- */
function eHoje(p){
  const list = S.inst.filter(i => mine(i, p.id)).sort((a, b) => a.start - b.start), d = dayStats(i => mine(i, p.id));
  const nextI = list.find(i => !isDone(i)), pr = pendingReads(p.id);
  const nds = list.filter(i => !isDone(i) && nudgesOf(i.id).length), redo = list.filter(i => i.redo && vis(i.redo.at) && !isDone(i));
  const prog_ = list.length ? list.filter(isDone).length / list.length : 0;
  return `<div class="hero"><div class="ring-wrap">${ring(prog_, 92, `${list.filter(isDone).length}/${list.length}`, true)}<div class="stack gap4"><b class="big2">${greet()}, ${esc(first(p))}</b>
      <span class="small muted">${!list.length ? 'Nenhum checklist para você hoje.' : d.due ? `${d.ok} de ${d.due} no prazo até agora.` : 'Seu primeiro checklist ainda não venceu.'}</span>
      ${list.length ? `<span class="small">${nextI ? `Próximo: <b>${esc(tpl(nextI.tpl).title)}</b> às ${hm(nextI.start)}` : 'Tudo feito por hoje.'}</span>` : ''}</div></div></div>
    ${redo.map(i => `<button class="notice bad" data-act="open" data-id="${i.id}"><span><b>Refazer: ${esc(tpl(i.tpl).title)}.</b> ${esc(i.redo.note)}</span><span>Abrir</span></button>`).join('')}
    ${nds.map(i => `<button class="notice bad" data-act="open" data-id="${i.id}"><span><b>${esc(first(person(nudgesOf(i.id).slice(-1)[0].by)))} te lembrou às ${hm(nudgesOf(i.id).slice(-1)[0].at)}:</b> ${esc(tpl(i.tpl).title)} das ${hm(i.start)} ${status(i) === 'atrasado' ? 'está atrasado' : 'está aberto'}.</span><span>Abrir</span></button>`).join('')}
    ${pr.length > 2 ? `<button class="notice warn" data-act="tab" data-v="pops"><span><b>${pr.length} POPs para assinar.</b> Leia cada um e assine o termo de ciência.</span><span>Ler</span></button>` : pr.map(x => `<button class="notice warn" data-act="pop" data-id="${x.pop.id}"><span><b>POP para assinar:</b> ${x.pop.id} ${esc(x.pop.title)}, versão ${x.pop.version}.</span><span>Ler</span></button>`).join('')}
    ${avisoPush()}${avisoInicio()}${avisoFechado()}${fila().length ? `<div class="notice warn"><span><b>${fila().length} ${fila().length === 1 ? 'marcação' : 'marcações'} esperando internet.</b> Elas são enviadas sozinhas quando a conexão voltar.</span></div>` : ''}<section class="stack gap8"><h2 class="sec-h">Sua rotina de hoje</h2>${list.length ? list.map(i => instCard(i, {who:false})).join('') : '<p class="muted small">Nenhum checklist para você hoje.</p>'}</section>
    <p class="small muted center">Os POPs que você faz a cada cliente, como o atendimento na cadeira, são avaliados nas rondas da gerente.</p>
    ${formOcorrencia(false).replace('class="panel"', 'class="card"').replace('Registrar ocorrência', 'Avisar a gerência de um problema')}`;
}

/* ---------- Equipe: Histórico ---------- */
function eHist(p){
  const a = histAgg(x => x.byP[p.id]), s = streak(p.id), occ = S.occ.filter(o => (o.who === p.id || o.by === p.id) && occVis(o));
  const sem = history().slice(-6).map(d => d.byP[p.id]).filter(Boolean), semana = sem.length >= 3 && sem.every(x => x.ok === x.exp);
  const h = history().slice(-10).reverse();
  return `<div><p class="eyebrow">Seu histórico</p><h1 class="p-title">Últimas 4 semanas</h1></div>
    <div class="split"><div><span class="l">No prazo</span><span class="v ${rateKind(a.rate)}-t">${rateTxt(a.rate)}</span></div><div><span class="l">Com atraso</span><span class="v">${a.late}</span></div><div><span class="l">Não feitos</span><span class="v">${a.miss}</span></div></div>
    ${semana ? `<div class="callout good"><b>Semana perfeita!</b> Todos os seus checklists dos últimos dias de trabalho foram feitos no prazo.</div>` : ''}
    <section class="card"><h3>Sequência de dias perfeitos</h3><p class="pos-big">${s} ${s === 1 ? 'dia' : 'dias'}</p><p class="small muted">Dias seguidos com todos os checklists no prazo. Meta da casa: ${pct(S.rules.meta)} no mês.</p>${dots(p.id)}</section>
    <section class="card"><h3>Dia a dia</h3><div class="feed">${h.map(d => { const x = d.byP[p.id]; if (!x) return '';
      return `<div class="feed-i"><div><b>${WEEK[d.wd]}, ${d.label}</b><span>${x.exp} checklists</span></div><div class="r">${x.ok === x.exp ? chip('tudo no prazo', 'good') : chip(`${x.ok} de ${x.exp} no prazo`, x.miss ? 'bad' : 'warn')}</div></div>`; }).join('')}</div></section>
    <section class="card"><h3>Ocorrências com você ou registradas por você</h3>${occ.length ? occ.map(o => occCard(o)).join('') : '<p class="small muted">Nenhuma. Continue assim.</p>'}</section>`;
}
