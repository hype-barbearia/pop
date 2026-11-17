/* =========================================================
   Administração: tudo editável pelo Victor
   Rotinas (nome, POP, dias, quem faz, janelas, itens), agenda avulsa,
   lembretes, POPs (área, cargos, preços, indicações) e textos da casa.
   ========================================================= */
const CARGOS = [['barbeiro','Barbeiros'], ['atendente','Atendentes'], ['gerente','Gerente'], ['todos','Toda a equipe']];
const diasBox = (name, sel, base = DOW) => `<span class="dias-box">${base.map(x => `<label class="toggle sm"><input type="checkbox" name="${name}" value="${x}" ${sel.includes(x) ? 'checked' : ''}><span>${WEEK[x]}</span></label>`).join('')}</span>`;
const linhasTab = rows => (rows || []).map(r => r.join(' | ')).join('\n');
const parseTab = (txt, n) => txt.split('\n').map(l => l.trim()).filter(Boolean).map(l => { const c = l.split('|').map(x => x.trim()); while (c.length < n) c.push(''); return c.slice(0, n); });

/* ---------- Rotina: editor completo ---------- */
function modoRotina(t){ return Array.isArray(t.each) ? 'lista' : t.each ? 'cargo' : t.rodizio ? 'revezamento' : 'fixo'; }
function editorRotina(t){
  if (!t) return '';
  const modo = S.ui.rotModo || modoRotina(t), janelas = t.slots;
  const itens = [...t.items].sort((a, b) => a.ordem - b.ordem);
  return `<section class="panel editor" id="editor-rotina"><div class="panel-h"><h2>Editar: ${esc(t.title)}</h2><button class="btn sm" data-act="rotEditar" data-v="">Fechar</button></div>
    <form class="stack gap10" data-form="rotEdit" data-id="${t.id}">
      <div class="form-grid">
        <div class="field span2"><label for="re-t">Nome do checklist</label><input class="inp" id="re-t" value="${esc(t.title)}" required></div>
        <div class="field"><label for="re-pop">POP</label><select class="inp" id="re-pop">${S.pops.map(p => `<option value="${p.id}" ${p.id === t.pop ? 'selected' : ''}>${p.id} · ${esc(p.title)}</option>`).join('')}</select></div>
        <div class="field"><label for="re-tipo">Tipo</label><select class="inp" id="re-tipo"><option value="check" ${t.kind !== 'ronda' ? 'selected' : ''}>Checklist (Feito / Não deu)</option><option value="ronda" ${t.kind === 'ronda' ? 'selected' : ''}>Ronda (Conforme / Não conforme)</option></select></div>
      </div>
      <fieldset class="dias"><legend class="small muted">Dias da semana</legend>${diasBox('re-dia', t.days)}</fieldset>
      <div class="form-grid">
        <div class="field"><label for="re-modo">Quem faz</label><select class="inp" id="re-modo" data-rotmodo="1">
          ${[['fixo','Uma pessoa fixa por horário'], ['revezamento','Revezamento (escala por dia)'], ['lista','Cada pessoa de uma lista'], ['cargo','Todos de um cargo que estiverem no dia']].map(([k, l]) => `<option value="${k}" ${modo === k ? 'selected' : ''}>${l}</option>`).join('')}</select></div>
        ${modo === 'cargo' ? `<div class="field"><label for="re-cargo">Cargo</label><select class="inp" id="re-cargo">${CARGOS.slice(0, 3).map(([k, l]) => `<option value="${k}" ${t.each === k ? 'selected' : ''}>${l}</option>`).join('')}</select></div>` : ''}
      </div>
      ${modo === 'lista' ? `<fieldset class="dias"><legend class="small muted">Pessoas (cada uma recebe o seu checklist)</legend>${team().map(p => `<label class="toggle sm"><input type="checkbox" name="re-cada" value="${p.id}" ${Array.isArray(t.each) && t.each.includes(p.id) ? 'checked' : ''}><span>${esc(p.name)}</span></label>`).join('')}</fieldset>` : ''}
      ${modo === 'fixo' || modo === 'revezamento' ? `<fieldset class="dias"><legend class="small muted">Faz junto (pode marcar o mesmo checklist)</legend>${team().map(p => `<label class="toggle sm"><input type="checkbox" name="re-junto" value="${p.id}" ${(t.also || []).includes(p.id) ? 'checked' : ''}><span>${esc(p.name)}</span></label>`).join('')}</fieldset>` : ''}
      <div class="row gap14">
        <label class="toggle"><input type="checkbox" id="re-conf" ${t.verify ? 'checked' : ''}><span><b>A gerente confere</b></span></label>
        <label class="toggle"><input type="checkbox" id="re-folga" ${t.ignoraFolga ? 'checked' : ''}><span><b>Acontece mesmo na folga</b><span>Para reuniões.</span></span></label>
      </div>
      <div><button class="btn primary">Salvar checklist</button></div>
    </form>
    <p class="day-h">Horários</p>
    <div class="stack gap6">${janelas.map(([ini, fim, resp, jid, jd]) => `<div class="jan-row">
      <span class="row nowrap gap6"><label class="sr" for="ji-${jid}">Início</label><input class="inp time" type="time" id="ji-${jid}" data-jan="${jid}|inicio" value="${ini}"> às <label class="sr" for="jf-${jid}">Prazo</label><input class="inp time" type="time" id="jf-${jid}" data-jan="${jid}|prazo" value="${fim}"></span>
      ${modo === 'fixo' || modo === 'revezamento' ? `<span class="row nowrap gap6"><label class="small muted" for="jr-${jid}">${modo === 'revezamento' ? 'Padrão' : 'Quem'}</label><select class="inp w-auto sm-sel" id="jr-${jid}" data-jan="${jid}|responsavel">${pessoaOpts(resp || '', 'Ninguém')}</select></span>` : ''}
      <span class="row nowrap gap6"><span class="small muted">Só em</span>${t.days.map(x => `<label class="toggle sm"><input type="checkbox" data-jandia="${jid}|${x}" ${!jd || jd.includes(x) ? 'checked' : ''}><span>${WEEK[x]}</span></label>`).join('')}</span>
      <button class="linkbtn small" data-act="janDel" data-id="${jid}">Remover horário</button></div>`).join('') || '<p class="small muted">Nenhum horário fixo. Use a Agenda para marcar datas avulsas.</p>'}
      <div><button class="btn sm" data-act="janAdd" data-id="${t.id}">Incluir outro horário</button></div></div>
    <p class="day-h">Itens</p>
    <ol class="steps sm">${itens.map((it, k) => `<li><span><label class="sr" for="ite-${it.id}">Texto</label><input class="inp it-in" id="ite-${it.id}" data-item="${it.id}" value="${esc(it.t)}"></span>
      <span class="row nowrap gap6"><label class="ph-toggle ${it.photo ? 'on' : ''}"><input type="checkbox" data-photo="${t.id}|${it.id}" ${it.photo ? 'checked' : ''}>${icon('camera', 'ni xs')}foto</label>
        <label class="ph-toggle ${it.crit ? 'on crit' : ''}"><input type="checkbox" data-crit="${it.id}" ${it.crit ? 'checked' : ''}>crítico</label>
        <button class="linkbtn small" data-act="itemMove" data-id="${it.id}" data-v="-1" ${k === 0 ? 'disabled' : ''} aria-label="Subir">↑</button><button class="linkbtn small" data-act="itemMove" data-id="${it.id}" data-v="1" ${k === itens.length - 1 ? 'disabled' : ''} aria-label="Descer">↓</button>
        <button class="linkbtn small" data-act="itemDel" data-id="${it.id}">Retirar</button></span></li>`).join('')}</ol>
    <form class="row gap6" data-form="item" data-id="${t.id}"><label class="sr" for="ni2-${t.id}">Novo item</label><input class="inp grow" id="ni2-${t.id}" placeholder="Novo item" required><button class="btn sm">Incluir</button></form>
    <p class="small muted">Mudanças nos horários e itens valem a partir de amanhã. O que já foi criado para hoje continua como está.</p></section>`;
}

/* ---------- Agenda avulsa (ex.: reunião de técnicas com horário variável) ---------- */
function blocoAgenda(){
  const fut = S.agenda.filter(a => a.data >= TODAY_ISO), tit = id => S.allTpls.find(t => t.id === id)?.title || id;
  return `<section class="panel" id="agenda"><div class="panel-h"><h2>Agenda avulsa</h2><p>checklists em data e hora marcadas</p></div>
    <p class="small muted">Para o que não tem horário fixo, como a reunião de técnicas do Robson. Cada agendamento vira um checklist naquele dia, com aviso no celular.</p>
    ${fut.length ? `<div class="stack gap6">${fut.map(a => `<div class="rem"><span class="num"><b>${dLabelISO(a.data)}</b> ${hmT(a.inicio)}–${hmT(a.prazo)}</span><span class="grow">${esc(tit(a.rotina_id))} · ${esc(person(a.pessoa_id)?.name || a.pessoa_id)}${a.obs ? ` · ${esc(a.obs)}` : ''}</span>${canEdit() ? `<button class="linkbtn small" data-act="desagendar" data-id="${a.id}">Desmarcar</button>` : ''}</div>`).join('')}</div>` : '<p class="small muted">Nada agendado.</p>'}
    ${canEdit() ? `<form class="stack gap8 mini-form" data-form="agendar"><div class="form-grid">
      <div class="field span2"><label for="ag-r">Checklist</label><select class="inp" id="ag-r">${S.allTpls.filter(t => t.active).map(t => `<option value="${t.id}" ${t.id === 'TEC' ? 'selected' : ''}>${esc(t.title)}</option>`).join('')}</select></div>
      <div class="field"><label for="ag-d">Data</label><input class="inp" type="date" id="ag-d" value="${TODAY_ISO}" required></div>
      <div class="field"><label for="ag-i">Início</label><input class="inp" type="time" id="ag-i" value="19:30" required></div>
      <div class="field"><label for="ag-f">Prazo</label><input class="inp" type="time" id="ag-f" value="20:30" required></div>
      <div class="field"><label for="ag-p">Responsável</label><select class="inp" id="ag-p">${pessoaOpts('robson')}</select></div>
      <div class="field span2"><label for="ag-o">Observação</label><input class="inp" id="ag-o" placeholder="Ex.: técnica de degradê"></div></div>
      <div><button class="btn sm primary">Agendar</button></div></form>` : ''}</section>`;
}

/* ---------- Lembretes fixos editáveis ---------- */
function editorLembretes(){
  const todos = S.allReminders || S.reminders;
  return `<div class="stack gap6">${todos.map(x => `<div class="rem lem-ed ${x.on ? '' : 'off'}">
      <label class="sr" for="lh-${x.id}">Hora</label><input class="inp time" type="time" id="lh-${x.id}" data-lem="${x.id}|hora" value="${x.at}">
      <label class="sr" for="lt-${x.id}">Texto</label><input class="inp grow" id="lt-${x.id}" data-lem="${x.id}|texto" value="${esc(x.text)}">
      <span class="row nowrap gap6">${DOW.map(d => `<label class="toggle sm"><input type="checkbox" data-lemdia="${x.id}|${d}" ${(x.days || DOW).includes(d) ? 'checked' : ''}><span>${WEEK[d]}</span></label>`).join('')}</span>
      ${vis(S.remDone[x.id]) ? chip('feito ' + hm(S.remDone[x.id]), 'good') : ''}
      <label class="toggle sm" title="Ativo"><input type="checkbox" data-rem="${x.id}" ${x.on ? 'checked' : ''}><span>ativo</span></label>
      <button class="linkbtn small" data-act="lemDel" data-id="${x.id}">Apagar</button></div>`).join('')}</div>`;
}

/* ---------- POP: área, cargos, preços e indicações ---------- */
function editorPopExtras(p){
  return `<div class="form-grid">
      <div class="field"><label for="ep-area">Área</label><select class="inp" id="ep-area">${Object.entries(AREAS).map(([k, l]) => `<option value="${k}" ${p.area === k ? 'selected' : ''}>${esc(l)}</option>`).join('')}</select></div></div>
    <fieldset class="dias"><legend class="small muted">Quem precisa ler e assinar</legend>${CARGOS.map(([k, l]) => `<label class="toggle sm"><input type="checkbox" name="ep-cargo" value="${k}" ${p.roles.includes(k) ? 'checked' : ''}><span>${l}</span></label>`).join('')}</fieldset>
    <div class="field"><label for="ep-tab">Tabela de preços (opcional). Comece cada grupo com ## e use uma linha por item: Nome | Preço</label><textarea class="inp mono" id="ep-tab" rows="${p.tables ? 10 : 3}">${esc((p.tables || []).map(([g, rows]) => `## ${g}\n${linhasTab(rows)}`).join('\n'))}</textarea></div>
    <div class="field"><label for="ep-guia">Guia de indicações (opcional). Uma linha por sinal: Sinal percebido | Serviço | Produto</label><textarea class="inp mono" id="ep-guia" rows="${p.guide ? 8 : 3}">${esc(linhasTab(p.guide))}</textarea></div>
    <div class="row gap6"><button type="button" class="btn sm no" data-act="popArquivar" data-id="${p.id}">Arquivar este POP</button><span class="small muted">Arquivado, ele sai da biblioteca e do app da equipe.</span></div>`;
}
function popExtras(){
  if (!$('#ep-area')) return null;
  const tabTxt = $('#ep-tab').value.trim(), grupos = [];
  tabTxt.split('\n').forEach(l => { l = l.trim(); if (!l) return; if (l.startsWith('##')) grupos.push([l.replace(/^#+/, '').trim(), []]); else { if (!grupos.length) grupos.push(['Preços', []]); grupos[grupos.length - 1][1].push(parseTab(l, 2)[0]); } });
  const guia = parseTab($('#ep-guia').value, 3);
  const cargos = [...document.querySelectorAll('input[name=ep-cargo]:checked')].map(x => x.value);
  return {area:$('#ep-area').value, cargos:cargos.length ? cargos : ['todos'], tabelas:grupos.length ? grupos : null, guia:guia.length ? guia : null};
}

/* ---------- Informações da casa ---------- */
function pgInfo(){
  const ed = canEdit(), d = ed ? '' : 'disabled';
  return `${ph(eyebrow(), 'Informações da casa', 'Cultura, horário, posições, reuniões e áreas dos POPs. O que estiver aqui aparece na biblioteca, na rotina e no app da equipe.')}
    ${roNote()}
    <form class="panel stack gap8" data-form="info-cultura"><div class="panel-h"><h2>Cultura HYPE</h2></div>
      <div class="field"><label for="in-missao">Missão</label><textarea class="inp" id="in-missao" rows="3" ${d}>${esc(CULTURA.missao)}</textarea></div>
      <div class="field"><label for="in-visao">Visão</label><textarea class="inp" id="in-visao" rows="2" ${d}>${esc(CULTURA.visao)}</textarea></div>
      <div class="field"><label for="in-valores">Valores, um por linha: Nome | O que significa | Frase-guia</label><textarea class="inp mono" id="in-valores" rows="5" ${d}>${esc(linhasTab(CULTURA.valores))}</textarea></div>
      ${ed ? '<div><button class="btn primary">Salvar cultura</button></div>' : ''}</form>
    <form class="panel stack gap8" data-form="info-escala"><div class="panel-h"><h2>Funcionamento e reuniões</h2></div>
      <div class="field"><label for="in-hor">Horário de funcionamento</label><input class="inp" id="in-hor" value="${esc(ESCALA.horario)}" ${d}></div>
      <div class="field"><label for="in-pos">Posições padrão</label><input class="inp" id="in-pos" value="${esc(ESCALA.posicoes)}" ${d}></div>
      <div class="field"><label for="in-reu">Reuniões, uma por linha: Dia | Horário | Reunião | Frequência</label><textarea class="inp mono" id="in-reu" rows="6" ${d}>${esc(linhasTab(ESCALA.reunioes))}</textarea></div>
      <p class="small muted">Este quadro é informativo. Os checklists das reuniões estão em Rotina e checklists, e as de horário variável, na Agenda avulsa.</p>
      ${ed ? '<div><button class="btn primary">Salvar</button></div>' : ''}</form>
    <form class="panel stack gap8" data-form="info-areas"><div class="panel-h"><h2>Áreas dos POPs</h2></div>
      <div class="field"><label for="in-areas">Uma por linha: código | Nome. O código não muda depois de usado.</label><textarea class="inp mono" id="in-areas" rows="8" ${d}>${esc(Object.entries(AREAS).map(([k, l]) => `${k} | ${l}`).join('\n'))}</textarea></div>
      ${ed ? '<div><button class="btn primary">Salvar áreas</button></div>' : ''}</form>`;
}
const salvarTexto = (chave, valor, msg) => run(async () => check(await sb.from('config_textos').upsert({chave, valor, atualizado_em:new Date().toISOString(), por:S.ui.user})), msg);

/* ---------- Ações ---------- */
Object.assign(A, {
  rotEditar(d){ S.ui.rotEdit = d.v || null; S.ui.rotModo = null; render(); if (d.v) setTimeout(() => $('#editor-rotina')?.scrollIntoView({block:'start'}), 30); },
  janAdd(d){ run(async () => check(await sb.from('rotina_janelas').insert({rotina_id:d.id, inicio:'09:00', prazo:'09:30'})), 'Horário incluído. Ajuste início, prazo e responsável.'); },
  janDel(d){ if (!confirmar(null, `jan-${d.id}`, 'Toque de novo em Remover horário para confirmar.')) return;
    upd('rotina_janelas', {ativo:false}, 'id', +d.id, 'Horário removido. Vale a partir de amanhã; o histórico continua.'); },
  itemMove(d){
    const t = S.allTpls.find(x => x.items.some(i => i.id === d.id)), its = [...t.items].sort((a, b) => a.ordem - b.ordem), k = its.findIndex(i => i.id === d.id), j = k + +d.v;
    if (j < 0 || j >= its.length) return;
    run(async () => { check(await sb.from('rotina_itens').update({ordem:its[j].ordem}).eq('id', its[k].id)); check(await sb.from('rotina_itens').update({ordem:its[k].ordem}).eq('id', its[j].id)); });
  },
  desagendar(d){ run(() => rpc('desagendar', {ag:+d.id}), 'Agendamento desmarcado.'); },
  lemDel(d){ if (!confirmar(null, `lem-${d.id}`, 'Toque de novo em Apagar para confirmar.')) return; run(async () => check(await sb.from('lembretes').delete().eq('id', +d.id)), 'Lembrete apagado.'); },
  popArquivar(d){ if (!confirmar(null, `arq-${d.id}`, 'Toque de novo para arquivar este POP.')) return; S.ui.pop = null; S.ui.popEdit = null; upd('pops', {ativo:false}, 'id', d.id, 'POP arquivado.'); },
});

document.addEventListener('change', e => {
  const el = e.target;
  if (el.dataset.rotmodo) { S.ui.rotModo = el.value; render(); return; }
  if (el.dataset.jan) { const [jid, campo] = el.dataset.jan.split('|'); upd('rotina_janelas', {[campo]:el.value || null}, 'id', +jid, 'Horário atualizado. Vale a partir de amanhã.'); return; }
  if (el.dataset.jandia) { const [jid] = el.dataset.jandia.split('|'), t = S.allTpls.find(x => x.slots.some(s => String(s[3]) === jid));
    const marcados = [...document.querySelectorAll(`input[data-jandia^="${jid}|"]:checked`)].map(x => +x.dataset.jandia.split('|')[1]);
    const dias = marcados.length === t.days.length ? null : marcados.length ? marcados : [0];
    upd('rotina_janelas', {dias}, 'id', +jid, 'Dias do horário atualizados.'); return; }
  if (el.dataset.crit) { upd('rotina_itens', {critico:el.checked}, 'id', el.dataset.crit, el.checked ? 'Item marcado como crítico.' : 'Item deixou de ser crítico.'); return; }
  if (el.dataset.lem) { const [id, campo] = el.dataset.lem.split('|'), v = el.value.trim(); if (!v) return; upd('lembretes', {[campo]:v}, 'id', +id, 'Lembrete atualizado.'); return; }
  if (el.dataset.lemdia) { const [id] = el.dataset.lemdia.split('|'), dias = [...document.querySelectorAll(`input[data-lemdia^="${id}|"]:checked`)].map(x => +x.dataset.lemdia.split('|')[1]);
    if (!dias.length) { toast('Escolha pelo menos um dia. Para parar o lembrete, desmarque "ativo".'); el.checked = true; return; }
    upd('lembretes', {dias}, 'id', +id, 'Dias do lembrete atualizados.'); return; }
});

document.addEventListener('submit', e => {
  const f = e.target.dataset.form; if (!f) return;
  if (f === 'rotEdit') { e.preventDefault();
    const id = e.target.dataset.id, modo = $('#re-modo').value, dias = [...document.querySelectorAll('input[name=re-dia]:checked')].map(x => +x.value);
    if (!dias.length) { toast('Escolha pelo menos um dia.'); return; }
    const cada = [...document.querySelectorAll('input[name=re-cada]:checked')].map(x => x.value), junto = [...document.querySelectorAll('input[name=re-junto]:checked')].map(x => x.value);
    if (modo === 'lista' && !cada.length) { toast('Escolha pelo menos uma pessoa da lista.'); return; }
    S.ui.rotModo = null;
    upd('rotinas', {titulo:$('#re-t').value.trim(), pop_id:$('#re-pop').value, tipo:$('#re-tipo').value, dias, conferir:$('#re-conf').checked, ignora_folga:$('#re-folga').checked,
      cada:modo === 'lista' ? cada : null, cada_papel:modo === 'cargo' ? $('#re-cargo').value : null, rodizio:modo === 'revezamento',
      junto:(modo === 'fixo' || modo === 'revezamento') && junto.length ? junto : null}, 'id', id, 'Checklist salvo. Vale a partir de amanhã.');
  }
  if (f === 'agendar') { e.preventDefault();
    run(() => rpc('agendar', {rotina:$('#ag-r').value, data:$('#ag-d').value, inicio:$('#ag-i').value, prazo:$('#ag-f').value, pessoa:$('#ag-p').value, obs:$('#ag-o').value.trim() || null}), 'Agendado. A pessoa recebe o aviso no horário.'); }
  if (f === 'info-cultura') { e.preventDefault();
    salvarTexto('cultura', {missao:$('#in-missao').value.trim(), visao:$('#in-visao').value.trim(), valores:parseTab($('#in-valores').value, 3)}, 'Cultura salva.'); }
  if (f === 'info-escala') { e.preventDefault();
    salvarTexto('escala', {horario:$('#in-hor').value.trim(), posicoes:$('#in-pos').value.trim(), reunioes:parseTab($('#in-reu').value, 4)}, 'Informações salvas.'); }
  if (f === 'info-areas') { e.preventDefault();
    const o = {}; parseTab($('#in-areas').value, 2).forEach(([k, l]) => { const c = k.toLowerCase().normalize('NFD').replace(/[^a-z0-9]/g, ''); if (c && l) o[c] = l; });
    const usados = [...new Set(S.pops.map(p => p.area))].filter(a => !o[a]);
    if (usados.length) { toast(`Não dá para tirar áreas em uso: ${usados.join(', ')}.`); return; }
    salvarTexto('areas', o, 'Áreas salvas.'); }
}, true);
