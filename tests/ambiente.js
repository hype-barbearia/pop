/* Hype POP · ambiente de teste sem internet
   Monta um Supabase falso com os dados de tests/fixture.json e um dia de checklists de exemplo.
   Usado pelos testes automáticos (tests/smoke.js) e pelas telas de conferência visual (tests/mock.js). */
const fs = require('fs'), path = require('path');
const RAIZ = path.join(__dirname, '..');
const ARQUIVOS = ['config', 'core', 'consts', 'engine', 'data', 'ui', 'socio', 'app', 'main', 'admin', 'ux', 'recursos', 'tv', 'dev', 'simulador', 'gestao', 'notas'];
const HORA_FIXA = 15 * 60 + 40; // as telas de teste ficam paradas às 15:40

function hojeRecife(){ return new Date(Date.now() - 3 * 3600e3).toISOString().slice(0, 10); }

/* Dados de exemplo: um dia em andamento, com feitos, atrasados, abertos e agendados */
function dados(){
  const db = JSON.parse(fs.readFileSync(path.join(__dirname, 'fixture.json'), 'utf8')), hoje = hojeRecife();
  const ts = (h, m) => new Date(Date.UTC(+hoje.slice(0, 4), +hoje.slice(5, 7) - 1, +hoje.slice(8, 10), h + 3, m)).toISOString();
  const jan = {}; db.rotina_janelas.forEach(j => { jan[j.rotina_id] ??= j.id; });
  db.execucoes = []; db.execucao_itens = [];
  const add = (id, rot, who, a, b, done = null, itens = 0, falha = false) => {
    db.execucoes.push({id, data:hoje, rotina_id:rot, janela_id:jan[rot] ?? null, pessoa_id:who, inicio:ts(...a), prazo:ts(...b), concluida_em:done ? ts(...done) : null,
      conferido_em:null, conferido_resultado:null, refazer_em:null, agendamento_id:null, sorteada:null});
    db.rotina_itens.filter(i => i.rotina_id === rot).slice(0, itens).forEach((i, k) => db.execucao_itens.push({execucao_id:id, item_id:i.id, ok:!(falha && k === 1),
      marcado_em:ts(a[0], a[1] + 2), foto_path:null, obs:falha && k === 1 ? 'Acabou o produto' : null, por:who, execucoes:{data:hoje}}));
  };
  add('e1', 'BIN', 'breno', [8, 50], [9, 0], [8, 56], 4);
  add('e2', 'AMB', 'breno', [14, 0], [14, 30], null, 1);
  add('e3', 'ABR', 'breno', [15, 30], [16, 10], null, 3);
  add('e4', 'INF', 'breno', [19, 40], [20, 10]);
  add('e5', 'BFE', 'breno', [20, 0], [20, 20]);
  add('e6', 'ABR', 'magda', [8, 30], [9, 0], [9, 6], 8);
  add('e7', 'RON', 'jessica', [12, 0], [12, 30], [12, 20], 10);
  add('e8', 'AMB', 'magda', [11, 0], [11, 30], [11, 20], 4, true);
  add('e9', 'FEC', 'suellen', [20, 0], [20, 30]);
  add('e10', 'RON', 'jessica', [16, 30], [17, 0]);
  return db;
}

/* Código do Supabase falso (vira texto para ir dentro da página de teste) */
const SUPABASE_FALSO = `function criarSupabaseFalso(DB, WHO){
  const q = t => { const o = {_s:false}; ['select','eq','gte','lte','order','limit','is','in','or','range','neq'].forEach(k => o[k] = () => o);
    o.maybeSingle = () => { o._s = true; return o; }; o.single = o.maybeSingle; o.update = () => o; o.insert = () => o; o.upsert = () => o; o.delete = () => o;
    o.then = (r, j) => Promise.resolve({data:o._s ? DB[t] : (DB[t] || []), error:null}).then(r, j); return o; };
  const rpc = f => Promise.resolve({data:(DB._rpc && DB._rpc[f]) || (f === 'historico' || f === 'relatorio' ? [] : 0), error:null});
  return {createClient:() => ({from:q, rpc,
    storage:{from:() => ({createSignedUrls:async () => ({data:[]}), upload:async () => ({data:{}, error:null}), remove:async () => ({data:[], error:null})})},
    auth:{getSession:async () => ({data:{session:{user:{email:'t.' + WHO + '@exemplo.invalid'}}}}), onAuthStateChange(){}, signOut(){}, signInWithOtp:async () => ({}), verifyOtp:async () => ({})},
    channel:() => ({on(){ return this; }, subscribe(){}})})};
}`;

/* Código do app com a hora fixa */
function codigoApp(){
  return ARQUIVOS.map(f => {
    let s = fs.readFileSync(path.join(RAIZ, 'js', f + '.js'), 'utf8');
    if (f === 'core') {
      const antes = 'const nowMin = () => { const d = recife(); return d.getUTCHours() * 60 + d.getUTCMinutes(); };';
      if (!s.includes(antes)) throw new Error('core.js: nowMin mudou; atualize tests/ambiente.js');
      s = s.replace(antes, `const nowMin = () => ${HORA_FIXA};`);
    }
    return `/* ${f}.js */\n${s}`;
  }).join('\n');
}

module.exports = {RAIZ, ARQUIVOS, dados, SUPABASE_FALSO, codigoApp, hojeRecife};
