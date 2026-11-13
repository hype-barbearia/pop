/* =========================================================
   Dados: Supabase (login, leitura, ações e tempo real)
   ========================================================= */
const sb = supabase.createClient(HYPE_CONFIG.url, HYPE_CONFIG.key, {auth:{persistSession:true, autoRefreshToken:true, detectSessionInUrl:true}});
const UI_KEY = 'hype-pop-ui';
const uiLoad = () => { try { return JSON.parse(localStorage.getItem(UI_KEY)) || {}; } catch (e) { return {}; } };
const uiSave = () => { try { const {view, tab, f, mode} = S.ui; localStorage.setItem(UI_KEY, JSON.stringify({view, tab, f, mode})); } catch (e) {} };
const save = uiSave;

const PHOTO_URL = {};
const hmT = t => t ? t.slice(0, 5) : '';

/* Erro do Supabase vira mensagem legível */
function check(res){ if (res.error) throw new Error(res.error.message || 'Erro ao falar com o servidor.'); return res.data; }

async function carregar(){
  setToday();
  const d30 = isoMinus(30);
  await sb.rpc('garantir_dia');
  const q = await Promise.all([
    sb.from('pessoas').select('*').eq('ativo', true).order('ordem'),
    sb.from('pops').select('*').eq('ativo', true).order('ordem'),
    sb.from('pop_leituras').select('pop_id,pessoa_id,versao'),
    sb.from('rotinas').select('*').eq('ativo', true).order('ordem'),
    sb.from('rotina_janelas').select('*').order('inicio'),
    sb.from('rotina_itens').select('*').eq('ativo', true).order('ordem'),
    sb.from('execucoes').select('*').eq('data', TODAY_ISO),
    sb.from('execucao_itens').select('*, execucoes!inner(data)').eq('execucoes.data', TODAY_ISO),
    sb.from('cobrancas').select('*, execucoes!inner(data)').eq('execucoes.data', TODAY_ISO).order('em'),
    sb.from('ocorrencias').select('*').gte('data', d30).order('em', {ascending:false}),
    sb.from('ocorrencia_acoes').select('*').order('em'),
    sb.from('lembretes').select('*').order('hora'),
    sb.from('lembretes_feitos').select('*').eq('data', TODAY_ISO),
    sb.from('regras').select('*').maybeSingle(),
    sb.rpc('historico', {dias:28}),
  ]);
  const [pe, po, le, ro, ja, it, ex, ei, co, oc, oa, lb, lf, rg, hi] = q.map(check);

  const people = pe.map(p => ({id:p.id, name:p.nome, role:p.papel, label:p.rotulo, turno:p.turno || '', folga:p.folga, socio:p.socio, hue:p.cor, email:p.email || ''}));
  const pops = po.map(p => {
    const reads = {}; le.filter(r => r.pop_id === p.id).forEach(r => reads[r.pessoa_id] = Math.max(reads[r.pessoa_id] || 0, r.versao));
    return {id:p.id, title:p.titulo, area:p.area, roles:p.cargos, who:p.quem, owner:p.dono, freq:p.frequencia, objective:p.objetivo, materials:p.materiais || [], steps:p.passos || [],
      quality:p.qualidade || [], errors:p.erros || [], tables:p.tabelas, guide:p.guia, version:p.versao, updated:p.atualizado, approved:p.aprovado_por || 'Sócios', reads};
  });
  const janelas = Object.fromEntries(ja.map(j => [j.id, j]));
  const tpls = ro.map(r => ({id:r.id, title:r.titulo, pop:r.pop_id, kind:r.tipo, verify:r.conferir, days:r.dias, each:r.cada || r.cada_papel || null, also:r.junto, every2:r.quinzenal,
    items:it.filter(i => i.rotina_id === r.id).map(i => ({id:i.id, t:i.texto, photo:i.foto, crit:i.critico})),
    slots:ja.filter(j => j.rotina_id === r.id).map(j => [hmT(j.inicio), hmT(j.prazo), j.responsavel, j.id])}));
  const inst = ex.filter(x => tpls.some(t => t.id === x.rotina_id)).map(x => {
    const checks = {};
    ei.filter(c => c.execucao_id === x.id).forEach(c => checks[c.item_id] = {at:minOf(c.marcado_em), ok:c.ok, photo:c.foto_path || undefined, note:c.obs || ''});
    return {id:x.id, key:`${x.rotina_id}.${x.pessoa_id}.${hmT(janelas[x.janela_id]?.inicio).replace(':', '')}`, tpl:x.rotina_id, who:x.pessoa_id,
      start:minOf(x.inicio), due:minOf(x.prazo), checks, doneAt:minOf(x.concluida_em),
      ver:x.conferido_em ? {at:minOf(x.conferido_em), res:x.conferido_resultado, note:x.conferido_obs || '', by:x.conferido_por} : null,
      redo:x.refazer_em ? {at:minOf(x.refazer_em), note:x.refazer_obs || ''} : null};
  });
  const occ = oc.map(o => ({id:'OC-' + o.id, num:o.id, at:minOf(o.em), day:o.data !== TODAY_ISO ? dLabelISO(o.data) : null, who:o.pessoa_id, src:o.origem, inst:o.execucao_id,
    title:o.titulo, desc:o.descricao || '', status:o.status, pop:o.pop_id,
    actions:oa.filter(a => a.ocorrencia_id === o.id).map(a => { const iso = recife(Date.parse(a.em)).toISOString().slice(0, 10); return {at:minOf(a.em), day:iso !== TODAY_ISO ? dLabelISO(iso) : null, by:a.por, t:a.texto}; })}));
  const reminders = lb.filter(l => l.dias.includes(TODAY_WD) || !l.ativo).map(l => ({id:l.id, at:hmT(l.hora), text:l.texto, on:l.ativo}));
  const remDone = Object.fromEntries(lf.map(l => [l.lembrete_id, minOf(l.em)]));
  const nudges = co.map(c => ({inst:c.execucao_id, at:minOf(c.em), by:c.por}));
  const r = rg || {};
  const rules = {antes:r.antes ?? 10, escalar:r.escalar ?? 30, conferir:r.conferir ?? 30, meta:Number(r.meta ?? .9), rondas:r.rondas_surpresa ?? true, resumo:hmT(r.resumo) || '21:00', inicio:r.inicio_operacao || null};

  const ui = S?.ui || {...{view:'painel', tab:'hoje', f:{}, mode:'app'}, ...uiLoad(), open:null, pop:null, nao:null, more:false, selP:null};
  S = {people, pops, tpls, inst, occ, occ30:{}, reminders, remDone, nudges, rules, hist:hi || [], histDays:null, ui};
  S.ui.now = nowMin();
  await assinarFotos();
}

/* Fotos: links temporários para exibir */
async function assinarFotos(){
  const paths = S.inst.flatMap(i => Object.values(i.checks).map(c => c.photo).filter(Boolean)).filter(p => !PHOTO_URL[p]);
  if (!paths.length) return;
  const {data} = await sb.storage.from('fotos').createSignedUrls(paths, 6 * 3600);
  (data || []).forEach(d => { if (d.signedUrl) PHOTO_URL[d.path] = d.signedUrl; });
}

/* Reduz a foto da câmera antes de enviar (lado maior 1280 px, JPEG) */
async function comprimir(file){
  try {
    const bmp = await createImageBitmap(file), k = Math.min(1, 1280 / Math.max(bmp.width, bmp.height));
    const c = document.createElement('canvas'); c.width = Math.round(bmp.width * k); c.height = Math.round(bmp.height * k);
    c.getContext('2d').drawImage(bmp, 0, 0, c.width, c.height);
    return await new Promise(r => c.toBlob(b => r(b || file), 'image/jpeg', .8));
  } catch (e) { return file; }
}
async function enviarFoto(instId, itemId, file){
  const blob = await comprimir(file), path = `${TODAY_ISO}/${instId}/${itemId}-${Date.now()}.jpg`;
  check(await sb.storage.from('fotos').upload(path, blob, {contentType:'image/jpeg'}));
  return path;
}

/* Tempo real: qualquer mudança da equipe recarrega a tela */
let RT_TIMER, RT_CH;
function tempoReal(){
  if (RT_CH) return;
  RT_CH = sb.channel('hype-pop');
  ['execucoes','execucao_itens','cobrancas','ocorrencias','ocorrencia_acoes','lembretes_feitos','pop_leituras'].forEach(t =>
    RT_CH.on('postgres_changes', {event:'*', schema:'public', table:t}, () => { clearTimeout(RT_TIMER); RT_TIMER = setTimeout(recarregar, 700); }));
  RT_CH.subscribe();
}
