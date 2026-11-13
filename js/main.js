/* =========================================================
   Entrada, renderização, eventos e ações
   ========================================================= */
const me = () => person(S.ui.user);
const socioView = () => { const p = me(); return p && (p.role === 'socio' || (p.socio && S.ui.mode === 'socio')); };
const typing = () => document.activeElement?.matches?.('input:not([type=checkbox]),textarea,select');
let PENDING = false, TICK;

function topRight(){
  const p = me(); if (!p) return '';
  return `${p.socio ? `<button class="btn sm" data-act="modo">${S.ui.mode === 'socio' ? 'Meu app de barbeiro' : 'Painel dos sócios'}</button>` : ''}
    <span class="who">${av(p)}<b>${esc(p.name)}</b></span><button class="linkbtn" data-act="sair">Sair</button>`;
}

function render(){
  PENDING = false;
  $('#top-right').innerHTML = topRight();
  const app = $('#app'), p = me();
  if (socioView()) { app.className = 'admin'; app.innerHTML = renderSocio(); }
  else { app.className = 'phoneview'; app.innerHTML = renderPhone(p); }
  const i = S.ui.open && inst(S.ui.open), sp = socioView();
  $('#modal').innerHTML = sp && i ? modal(`${tpl(i.tpl).title}`, `${tpl(i.tpl).kind === 'ronda' ? 'Ronda' : 'Checklist'} · ${tpl(i.tpl).pop}`, instBody(i, 'view'))
    : sp && S.ui.pop && S.ui.view !== 'pops' && pop(S.ui.pop) ? modal(`${pop(S.ui.pop).id} · ${esc(pop(S.ui.pop).title)}`, 'Procedimento', popBody(pop(S.ui.pop), p)) : '';
}
const modal = (title, eb, body) => `<div class="modal" role="dialog" aria-modal="true" aria-labelledby="m-t" data-act="close"><div class="modal-in" data-stop="1">
  <div class="row between nowrap"><div><p class="eyebrow">${eb}</p><h2 id="m-t">${title}</h2></div><button class="btn sm" data-act="close">Fechar</button></div>${body}</div></div>`;

/* ---------- Telas de acesso ---------- */
function tela(html){ $('#top-right').innerHTML = ''; $('#modal').innerHTML = ''; const a = $('#app'); a.className = 'gate'; a.innerHTML = `<div class="gate-in">${html}</div>`; }
function telaLogin(enviado){
  tela(enviado ? `<h1>Confira seu e-mail</h1><p class="muted">Enviamos um link de acesso para <b>${esc(enviado)}</b>. Abra o e-mail neste aparelho e toque no link.</p>
      <form class="stack gap8" data-form="otp"><label for="otp">Ou digite o código de 6 números que veio no e-mail</label><input class="inp code-in" id="otp" inputmode="numeric" autocomplete="one-time-code" maxlength="6" placeholder="000000">
      <button class="btn primary big">Entrar com o código</button></form><button class="linkbtn" data-act="voltarLogin">Usar outro e-mail</button>`
    : `<p class="eyebrow">Hype POP</p><h1>Entrar</h1><p class="muted">Use o e-mail que você passou para a gerência. Vamos mandar um link de acesso, sem senha.</p>
      <form class="stack gap8" data-form="login"><label for="email">Seu e-mail</label><input class="inp" id="email" type="email" autocomplete="email" required placeholder="nome@exemplo.com">
      <button class="btn primary big">Receber o link de acesso</button></form>`);
}
function telaSemCadastro(email){
  tela(`<h1>E-mail sem cadastro</h1><p class="muted"><b>${esc(email)}</b> ainda não está na equipe da Hype POP. Peça a um sócio para cadastrar este e-mail na tela Equipe.</p><button class="btn" data-act="sair">Sair e usar outro e-mail</button>`);
}
function telaErro(e){ tela(`<h1>Não foi possível carregar</h1><p class="muted">${esc(e.message)}</p><button class="btn primary" data-act="tentar">Tentar de novo</button>`); }

let STARTING = false;
async function iniciar(){
  if (STARTING) return; STARTING = true;
  try { await iniciar_(); } finally { STARTING = false; }
}
async function iniciar_(){
  const {data:{session}} = await sb.auth.getSession();
  if (!session) { telaLogin(); return; }
  tela('<p class="muted">Carregando a operação de hoje…</p>');
  try { await carregar(); } catch (e) { telaErro(e); return; }
  const email = (session.user.email || '').toLowerCase(), p = S.people.find(x => x.email.toLowerCase() === email);
  if (!p) { telaSemCadastro(session.user.email); return; }
  S.ui.user = p.id;
  if (p.role === 'gerente' && !['agora','equipe','ocorrencias','pops'].includes(S.ui.tab)) S.ui.tab = 'agora';
  if (p.role !== 'gerente' && !['hoje','pops','hist'].includes(S.ui.tab)) S.ui.tab = 'hoje';
  render(); tempoReal();
  clearInterval(TICK); TICK = setInterval(tick, 30000);
}
async function recarregar(force){
  if (!S?.ui?.user) return;
  try { await carregar(); } catch (e) { toast(esc(e.message)); return; }
  if (!force && typing()) { PENDING = true; return; }
  render();
}
function tick(){
  const d = recife().toISOString().slice(0, 10);
  if (d !== TODAY_ISO) { recarregar(); return; }
  S.ui.now = nowMin();
  if (typing()) { PENDING = true; return; }
  render();
}
document.addEventListener('focusout', () => setTimeout(() => { if (PENDING && !typing()) render(); }, 50));
sb.auth.onAuthStateChange(ev => setTimeout(() => {
  if (ev === 'SIGNED_IN' && !S?.ui?.user && !STARTING) iniciar();
  if (ev === 'SIGNED_OUT') { S = null; clearInterval(TICK); telaLogin(); }
}, 0));

/* ---------- Ações ---------- */
async function run(fn, msg){
  try { await fn(); await recarregar(true); if (msg) toast(msg); }
  catch (e) { toast(esc(e.message)); }
}
const rpc = (f, a) => sb.rpc(f, a).then(check);
let FOTO = null;

const A = {
  sair(){ sb.auth.signOut(); },
  tentar(){ iniciar(); },
  voltarLogin(){ telaLogin(); },
  modo(){ S.ui.mode = S.ui.mode === 'socio' ? 'app' : 'socio'; S.ui.open = null; S.ui.pop = null; uiSave(); render(); window.scrollTo(0, 0); },
  nav(d){ S.ui.view = d.v; S.ui.more = false; S.ui.pop = null; S.ui.open = null; uiSave(); render(); window.scrollTo(0, 0); },
  more(){ S.ui.more = !S.ui.more; render(); },
  tab(d){ S.ui.tab = d.v; S.ui.open = null; S.ui.pop = null; S.ui.nao = null; uiSave(); render(); window.scrollTo(0, 0); },
  f(d){ S.ui.f[d.k] = d.v; uiSave(); render(); },
  selP(d){ S.ui.selP = d.v || null; render(); },
  open(d){ S.ui.open = d.id; S.ui.nao = null; render(); if (!socioView()) window.scrollTo(0, 0); },
  close(){ S.ui.open = null; S.ui.nao = null; if (!socioView() || S.ui.view !== 'pops') S.ui.pop = null; render(); },
  pop(d){ S.ui.open = null; S.ui.pop = d.id; render(); if (!socioView()) window.scrollTo(0, 0); },
  popClose(){ S.ui.pop = null; render(); },
  check(d){
    const it = tpl(inst(d.id).tpl).items.find(x => x.id === d.it);
    if (it.photo) { FOTO = {id:d.id, it:d.it}; const c = $('#cam'); c.value = ''; c.click(); return; }
    run(() => rpc('marcar_item', {e:d.id, item:d.it, feito:true}));
  },
  uncheck(d){ run(() => rpc('desmarcar_item', {e:d.id, item:d.it})); },
  nao(d){ S.ui.nao = d.id + '|' + d.it; render(); setTimeout(() => $('#nao-note')?.focus(), 0); },
  naoCancel(){ S.ui.nao = null; render(); },
  naoSave(d){
    const note = $('#nao-note').value.trim();
    if (!note) { toast('Escreva o motivo. A gerente precisa dele para tratar a ocorrência.'); $('#nao-note').focus(); return; }
    S.ui.nao = null; run(() => rpc('marcar_item', {e:d.id, item:d.it, feito:false, nota:note}), 'Registrado. A ocorrência foi aberta para a gerente.');
  },
  finish(d){
    const i = inst(d.id), late = NOW() > i.due; S.ui.open = null;
    run(() => rpc('concluir', {e:d.id}), late ? `Checklist concluído com ${mins(NOW() - i.due)} de atraso.` : `Checklist concluído no prazo.${tpl(i.tpl).verify ? ' A gerente vai conferir.' : ''}`);
  },
  verify(d){
    const note = ($('#ver-note')?.value || '').trim();
    if (d.v !== 'ok' && !note) { toast('Escreva a observação para a pessoa saber o que ajustar.'); $('#ver-note')?.focus(); return; }
    const who = first(person(inst(d.id).who)); S.ui.open = null;
    run(() => rpc('conferir', {e:d.id, resultado:d.v, nota:note || null}), d.v === 'refazer' ? `Pedido de refazer enviado para ${who}.` : d.v === 'ok' ? 'Conferido.' : 'Conferido com ressalva.');
  },
  nudge(d){ const who = first(person(inst(d.id).who)); run(() => rpc('cobrar', {e:d.id}), `Lembrete registrado. ${who} vê o aviso no app.`); },
  remDone(d){ run(() => rpc('lembrete_feito', {l:+d.id}), 'Lembrete marcado como feito.'); },
  read(d){ const p = pop(d.id); run(() => rpc('assinar_pop', {pop:d.id}), `Termo de ciência do ${p.id} assinado.`); },
  bump(d){ const p = pop(d.id); run(async () => check(await sb.from('pops').update({versao:p.version + 1, atualizado:dLabelISO(TODAY_ISO) + '/' + TODAY_ISO.slice(0, 4)}).eq('id', p.id)),
    `${p.id} agora está na versão ${p.version + 1}. A equipe precisa assinar de novo.`); },
  occAct(d, solve){
    const o = S.occ.find(x => x.id === d.id), el = $('#oa-' + d.id), t = (el?.value || '').trim();
    if (!t && !solve) { toast('Escreva a ação tomada.'); el?.focus(); return; }
    run(() => rpc('registrar_acao', {oc:o.num, texto:t, resolver:!!solve}), solve ? `${o.id} resolvida.` : 'Ação registrada.');
  },
  occSolve(d){ A.occAct(d, true); },
  copiar(){ const t = $('#wa-text')?.innerText || ''; navigator.clipboard?.writeText(t).then(() => toast('Resumo copiado. Cole no WhatsApp dos sócios.'), () => toast('Não deu para copiar. Selecione o texto e copie.')); },
};

document.addEventListener('click', e => {
  const el = e.target.closest('[data-act]'); if (!el) return;
  if ((el.classList.contains('modal') || el.classList.contains('sheet')) && e.target.closest('[data-stop]')) return;
  const f = A[el.dataset.act]; if (f) { e.preventDefault(); f(el.dataset, el); }
});
document.addEventListener('keydown', e => { if (e.key === 'Escape' && S?.ui && (S.ui.open || S.ui.more || (S.ui.pop && S.ui.view !== 'pops'))) { S.ui.more = false; A.close(); } });

const upd = (table, values, col, val, msg) => run(async () => check(await sb.from(table).update(values).eq(col, val)), msg);
document.addEventListener('change', e => {
  const el = e.target;
  if (el.id === 'cam') {
    const file = el.files?.[0], f = FOTO; FOTO = null; if (!file || !f) return;
    toast('Enviando a foto…');
    run(async () => { const path = await enviarFoto(f.id, f.it, file); await rpc('marcar_item', {e:f.id, item:f.it, feito:true, foto:path}); }, 'Foto registrada com a hora.');
    return;
  }
  if (el.dataset.f) { S.ui.f[el.dataset.f] = el.value; uiSave(); render(); return; }
  if (el.dataset.rule) {
    const k = el.dataset.rule, kind = el.dataset.kind; let v = kind === 'bool' ? el.checked : kind === 'str' ? el.value : +el.value;
    if (kind === 'pct') v = clamp(v, 50, 100) / 100; if (kind !== 'bool' && kind !== 'str' && isNaN(v)) return;
    const col = {antes:'antes', escalar:'escalar', conferir:'conferir', meta:'meta', rondas:'rondas_surpresa', resumo:'resumo', inicio:'inicio_operacao'}[k];
    if (kind === 'str' && !v) v = null;
    upd('regras', {[col]:v}, 'id', 1, 'Regra atualizada.'); return;
  }
  if (el.dataset.rem) { upd('lembretes', {ativo:el.checked}, 'id', +el.dataset.rem, el.checked ? 'Lembrete ativado.' : 'Lembrete pausado.'); return; }
  if (el.dataset.slot) {
    const [tid, k, f] = el.dataset.slot.split('|'), jid = tpl(tid).slots[+k][3];
    upd('rotina_janelas', {[['inicio','prazo','responsavel'][+f]]:el.value}, 'id', jid, 'Rotina atualizada. Vale a partir de amanhã.'); return;
  }
  if (el.dataset.photo) { const [, iid] = el.dataset.photo.split('|'); upd('rotina_itens', {foto:el.checked}, 'id', iid, el.checked ? 'Foto obrigatória neste item.' : 'Este item não exige mais foto.'); return; }
  if (el.dataset.email) { const v = el.value.trim().toLowerCase() || null; upd('pessoas', {email:v}, 'id', el.dataset.email, v ? `Acesso liberado para ${v}.` : 'Acesso removido.'); return; }
});

document.addEventListener('submit', async e => {
  const f = e.target.dataset.form; if (!f) return; e.preventDefault();
  if (f === 'login') {
    const email = $('#email').value.trim().toLowerCase(); if (!email) return;
    const btn = e.target.querySelector('button'); btn.disabled = true; btn.textContent = 'Enviando…';
    const {error} = await sb.auth.signInWithOtp({email, options:{emailRedirectTo:location.origin + location.pathname}});
    if (error) { btn.disabled = false; btn.textContent = 'Receber o link de acesso'; toast(esc(error.message.includes('rate') ? 'Muitos pedidos seguidos. Espere alguns minutos e tente de novo.' : error.message)); return; }
    sessionStorage.setItem('hype-email', email); telaLogin(email); return;
  }
  if (f === 'otp') {
    const token = $('#otp').value.trim(), email = sessionStorage.getItem('hype-email'); if (!token || !email) return;
    const {error} = await sb.auth.verifyOtp({email, token, type:'email'});
    if (error) toast('Código inválido ou vencido. Peça um novo link.'); return;
  }
  if (f === 'rem') { const at = $('#nr-at').value, t = $('#nr-t').value.trim(); if (!at || !t) return;
    run(async () => check(await sb.from('lembretes').insert({hora:at, texto:t})), 'Lembrete adicionado para a gerente.'); }
  if (f === 'occ') { const t = $('#no-t').value.trim(); if (!t) return;
    run(() => rpc('abrir_ocorrencia', {titulo:t, pessoa:$('#no-w').value, origem:$('#no-s').value, descricao:$('#no-d').value.trim() || null, pop:null}), 'Ocorrência registrada.'); }
  if (f === 'pop') { const t = $('#np-t').value.trim(); if (!t) return;
    const n = Math.max(...S.pops.map(p => +p.id.slice(4) || 0)) + 1, id = 'POP-' + String(n).padStart(2, '0'), role = $('#np-r').value;
    const steps = $('#np-s').value.split('\n').map(x => x.trim()).filter(Boolean).map(x => x.startsWith('!') ? {t:x.slice(1).trim(), crit:true} : {t:x});
    S.ui.pop = id;
    run(async () => check(await sb.from('pops').insert({id, titulo:t, area:$('#np-a').value, cargos:[role], quem:{barbeiro:'Barbeiros', atendente:'Atendentes', gerente:'Gerente', todos:'Toda a equipe'}[role],
      frequencia:$('#np-f').value.trim() || 'Quando acontecer', objetivo:$('#np-o').value.trim() || 'A definir.', passos:steps.length ? steps : [{t:'A definir.'}],
      atualizado:dLabelISO(TODAY_ISO) + '/' + TODAY_ISO.slice(0, 4), aprovado_por:me().name, ordem:n})), `${id} publicado. A equipe vê o aviso para assinar.`); }
});

iniciar();
