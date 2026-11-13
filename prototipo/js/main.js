/* =========================================================
   Renderização, eventos e ações
   ========================================================= */
S = load();

function render(){
  const u = S.ui.user, p = person(u) || person('socios');
  $('#who').innerHTML = `<option value="socios">Sócios · painel (Victor e Robson)</option><option value="jessica">Jessica · gerente</option>
    <optgroup label="Barbeiros">${S.people.filter(x => x.role === 'barbeiro').map(x => `<option value="${x.id}">${esc(x.name)}${x.socio ? ' · sócio' : ''}</option>`).join('')}</optgroup>
    <optgroup label="Atendentes">${S.people.filter(x => x.role === 'atendente').map(x => `<option value="${x.id}">${esc(x.name)} · ${x.turno.split(',')[0]}</option>`).join('')}</optgroup>`;
  $('#who').value = p.id;
  const opts = []; for (let m = 8 * 60 + 15; m <= 21 * 60 + 15; m += 15) opts.push(m);
  if (!opts.includes(NOW())) { opts.push(NOW()); opts.sort((a, b) => a - b); }
  $('#clock').innerHTML = opts.map(m => `<option value="${m}">${hm(m)}</option>`).join('');
  $('#clock').value = NOW();
  const app = $('#app');
  if (p.role === 'socio') { app.className = 'admin'; app.innerHTML = renderSocio(); }
  else { app.className = 'phoneview'; app.innerHTML = renderPhone(p); }
  // Na visão dos sócios, execução e POP abrem em janela
  const i = S.ui.open && inst(S.ui.open), sp = p.role === 'socio';
  $('#modal').innerHTML = sp && i ? modal(`${tpl(i.tpl).title}`, `${tpl(i.tpl).kind === 'ronda' ? 'Ronda' : 'Checklist'} · ${tpl(i.tpl).pop}`, instBody(i, 'view'))
    : sp && S.ui.pop && S.ui.view !== 'pops' ? modal(`${pop(S.ui.pop).id} · ${esc(pop(S.ui.pop).title)}`, 'Procedimento', popBody(pop(S.ui.pop), p)) : '';
}
const modal = (title, eb, body) => `<div class="modal" role="dialog" aria-modal="true" aria-labelledby="m-t" data-act="close"><div class="modal-in" data-stop="1">
  <div class="row between nowrap"><div><p class="eyebrow">${eb}</p><h2 id="m-t">${title}</h2></div><button class="btn sm" data-act="close">Fechar</button></div>${body}</div></div>`;

/* Ao agir numa execução, descarta o que o exemplo tinha gravado para depois da hora simulada */
function touch(i){
  const n = NOW();
  i.checks = Object.fromEntries(Object.entries(i.checks).filter(([, c]) => c.at <= n));
  if (i.doneAt > n) i.doneAt = null;
  if (i.ver && i.ver.at > n) i.ver = null;
  S.nudges = S.nudges.filter(x => x.inst !== i.id || x.at <= n);
  return i;
}
function commit(msg){ save(); render(); if (msg) toast(msg); }

const A = {
  reset(){ try { localStorage.removeItem(KEY); } catch (e) {} S = seed(); HIST = null; commit('Exemplo restaurado.'); },
  plus(){ S.ui.now = Math.min(S.ui.now + 15, 21 * 60 + 30); commit(); },
  nav(d){ S.ui.view = d.v; S.ui.more = false; S.ui.pop = null; S.ui.open = null; commit(); window.scrollTo(0, 0); },
  asSocio(){ S.ui.user = 'socios'; S.ui.view = 'painel'; S.ui.open = null; S.ui.pop = null; commit(); window.scrollTo(0, 0); },
  more(){ S.ui.more = !S.ui.more; commit(); },
  tab(d){ S.ui.tab = d.v; S.ui.open = null; S.ui.pop = null; S.ui.nao = null; commit(); window.scrollTo(0, 0); },
  f(d){ S.ui.f[d.k] = d.v; commit(); },
  selP(d){ S.ui.selP = d.v || null; commit(); },
  open(d){ S.ui.open = d.id; S.ui.nao = null; commit(); if (person(S.ui.user).role !== 'socio') window.scrollTo(0, 0); },
  close(){ S.ui.open = null; S.ui.nao = null; if (person(S.ui.user).role !== 'socio' || S.ui.view !== 'pops') S.ui.pop = null; commit(); },
  pop(d){ if (person(S.ui.user).role === 'socio') { S.ui.open = null; } else { S.ui.open = null; } S.ui.pop = d.id; commit(); if (person(S.ui.user).role !== 'socio') window.scrollTo(0, 0); },
  popClose(){ S.ui.pop = null; commit(); },
  check(d){ const i = touch(inst(d.id)), it = tpl(i.tpl).items.find(x => x.id === d.it); i.checks[it.id] = {at:NOW(), ok:true, photo:it.photo || undefined}; commit(it.photo ? 'Foto registrada com a hora.' : ''); },
  uncheck(d){ delete touch(inst(d.id)).checks[d.it]; commit(); },
  nao(d){ S.ui.nao = d.id + '|' + d.it; commit(); setTimeout(() => $('#nao-note')?.focus(), 0); },
  naoCancel(){ S.ui.nao = null; commit(); },
  naoSave(d){
    const note = $('#nao-note').value.trim();
    if (!note) { toast('Escreva o motivo. A gerente precisa dele para tratar a ocorrência.'); $('#nao-note').focus(); return; }
    const i = touch(inst(d.id)), t = tpl(i.tpl), it = t.items.find(x => x.id === d.it), ronda = t.kind === 'ronda';
    i.checks[it.id] = {at:NOW(), ok:false, note};
    S.occ.unshift({id:nextOcc(), at:NOW(), who:ronda ? null : i.who, src:ronda ? 'Ronda da gerente' : 'Checklist', inst:i.id, pop:t.pop, title:it.t + (ronda ? ': não conforme' : ': não feito'), desc:note, status:'aberta', actions:[]});
    S.ui.nao = null; commit('Registrado. A ocorrência foi aberta para a gerente.');
  },
  finish(d){ const i = touch(inst(d.id)); i.doneAt = NOW(); i.redo = null; S.ui.open = null;
    commit(i.doneAt > i.due ? `Checklist concluído com ${mins(i.doneAt - i.due)} de atraso.` : `Checklist concluído no prazo.${tpl(i.tpl).verify ? ' A gerente vai conferir.' : ''}`); },
  verify(d){
    const i = touch(inst(d.id)), note = ($('#ver-note')?.value || '').trim();
    if (d.v !== 'ok' && !note) { toast('Escreva a observação para a pessoa saber o que ajustar.'); $('#ver-note')?.focus(); return; }
    if (d.v === 'refazer') { i.redo = {at:NOW(), note}; i.doneAt = null; i.checks = Object.fromEntries(Object.entries(i.checks).filter(([, c]) => c.at <= NOW() && !c.photo)); i.ver = null; S.ui.open = null; commit(`Pedido de refazer enviado para ${first(person(i.who))}.`); return; }
    i.ver = {at:NOW(), res:d.v, note, by:'jessica'}; S.ui.open = null; commit(d.v === 'ok' ? 'Conferido.' : 'Conferido com ressalva.');
  },
  nudge(d){ const i = inst(d.id); S.nudges = S.nudges.filter(x => x.inst !== i.id || x.at <= NOW()); S.nudges.push({inst:i.id, at:NOW(), by:'jessica'}); commit(`Lembrete enviado para ${first(person(i.who))} no app e no WhatsApp.`); },
  remDone(d){ S.remDone[d.id] = NOW(); commit('Lembrete marcado como feito.'); },
  read(d){ const p = pop(d.id); p.reads[S.ui.user] = p.version; commit(`Leitura do ${p.id} versão ${p.version} confirmada.`); },
  bump(d){ const p = pop(d.id); p.version++; p.updated = '10/11/2026'; commit(`${p.id} agora está na versão ${p.version}. ${popPeople(p).length} pessoas precisam ler de novo.`); },
  occAct(d, solve){
    const o = S.occ.find(x => x.id === d.id), el = $('#oa-' + d.id), t = (el?.value || '').trim();
    if (!t && !solve) { toast('Escreva a ação tomada.'); el?.focus(); return; }
    if (t) o.actions.push({at:NOW(), by:S.ui.user === 'socios' ? 'socios' : 'jessica', t});
    o.status = solve ? 'resolvida' : 'tratamento'; commit(solve ? `${o.id} resolvida.` : 'Ação registrada.');
  },
  occSolve(d){ A.occAct(d, true); },
};

document.addEventListener('click', e => {
  const el = e.target.closest('[data-act]'); if (!el) return;
  if ((el.classList.contains('modal') || el.classList.contains('sheet')) && e.target.closest('[data-stop]')) return;
  const f = A[el.dataset.act]; if (f) { e.preventDefault(); f(el.dataset, el); }
});
document.addEventListener('keydown', e => { if (e.key === 'Escape' && (S.ui.open || S.ui.more || (S.ui.pop && S.ui.view !== 'pops'))) { S.ui.more = false; A.close(); } });

document.addEventListener('change', e => {
  const el = e.target;
  if (el.id === 'who') { S.ui.user = el.value; const p = person(el.value); S.ui.tab = p.role === 'gerente' ? 'agora' : 'hoje'; S.ui.open = null; S.ui.pop = null; S.ui.nao = null; commit(); window.scrollTo(0, 0); return; }
  if (el.id === 'clock') { S.ui.now = +el.value; S.ui.nao = null; commit(); return; }
  if (el.dataset.f) { S.ui.f[el.dataset.f] = el.value; commit(); return; }
  if (el.dataset.rule) { const k = el.dataset.rule, kind = el.dataset.kind; let v = kind === 'bool' ? el.checked : kind === 'str' ? el.value : +el.value;
    if (kind === 'pct') v = clamp(v, 50, 100) / 100; if (kind !== 'bool' && kind !== 'str' && isNaN(v)) return; S.rules[k] = v; commit('Regra atualizada.'); return; }
  if (el.dataset.rem) { const r = S.reminders.find(x => x.id === el.dataset.rem); r.on = el.checked; commit(r.on ? 'Lembrete ativado.' : 'Lembrete pausado.'); return; }
  if (el.dataset.photo) { const [tid, iid] = el.dataset.photo.split('|'), it = tpl(tid).items.find(x => x.id === iid); it.photo = el.checked; commit(el.checked ? `Foto obrigatória em "${it.t}".` : `"${it.t}" não exige mais foto.`); return; }
  if (el.dataset.slot) { const [tid, k, f] = el.dataset.slot.split('|'); tpl(tid).slots[+k][+f] = el.value; commit('Rotina atualizada. Vale a partir de amanhã.'); return; }
});

document.addEventListener('submit', e => {
  const f = e.target.dataset.form; if (!f) return; e.preventDefault();
  if (f === 'rem') { const at = $('#nr-at').value, t = $('#nr-t').value.trim(); if (!at || !t) return;
    S.reminders.push({id:'R' + Date.now(), at, text:t, on:true}); S.reminders.sort((a, b) => toMin(a.at) - toMin(b.at)); commit('Lembrete adicionado para a gerente.'); }
  if (f === 'occ') { const t = $('#no-t').value.trim(); if (!t) return;
    S.occ.unshift({id:nextOcc(), at:NOW(), who:$('#no-w').value, src:$('#no-s').value, title:t, desc:$('#no-d').value.trim() || 'Sem detalhes.', status:'aberta', actions:[]}); commit('Ocorrência registrada.'); }
  if (f === 'pop') { const t = $('#np-t').value.trim(); if (!t) return;
    const n = Math.max(...S.pops.map(p => +p.id.slice(4))) + 1, id = 'POP-' + String(n).padStart(2, '0'), role = $('#np-r').value;
    const steps = $('#np-s').value.split('\n').map(x => x.trim()).filter(Boolean).map(x => x.startsWith('!') ? {t:x.slice(1).trim(), crit:true} : {t:x});
    S.pops.push({id, title:t, area:$('#np-a').value, roles:[role], who:{barbeiro:'Barbeiros', atendente:'Atendentes', gerente:'Gerente', todos:'Toda a equipe'}[role], freq:$('#np-f').value.trim() || 'Quando acontecer',
      version:1, updated:'10/11/2026', approved:'Sócios', objective:$('#np-o').value.trim() || 'A definir.', materials:[], quality:[], errors:[], reads:{}, steps:steps.length ? steps : [{t:'A definir.'}]});
    S.ui.pop = id; commit(`${id} publicado. A equipe recebe o aviso para ler.`); }
});

render();
