/* Hype POP · teste automático de todas as telas, para cada tipo de acesso
   Uso: node tests/smoke.js   (sai com erro se alguma tela quebrar)
   Roda sozinho no GitHub antes de publicar. */
const vm = require('vm');
const {dados, SUPABASE_FALSO, codigoApp} = require('./ambiente');

const PERFIS = ['victor', 'robson', 'jessica', 'breno', 'magda', 'sistemas'];
let falhas = 0;
const ok = (cond, msg) => { if (!cond) { falhas++; console.log('  ✗ ' + msg); } };

async function testar(who){
  // Navegador falso: o suficiente para o app montar as telas em texto
  const els = {};
  const el = () => ({innerHTML:'', value:'', className:'', hidden:true, dataset:{}, style:{}, files:null, addEventListener(){}, classList:{toggle(){}, add(){}, remove(){}, contains:() => false},
    focus(){}, click(){}, remove(){}, querySelector:() => null, querySelectorAll:() => [], appendChild(){}, offsetWidth:0});
  const ls = {};
  const ctx = {
    console, setTimeout:(f) => 0, clearTimeout(){}, setInterval:() => 0, clearInterval(){}, Promise, Date, Math, JSON, Object, Array, String, Number, Boolean, RegExp, Error, Map, Set, Intl, URL, Blob:function(){},
    navigator:{onLine:true, userAgent:'node', vibrate(){}}, fetch:async () => ({headers:{get:() => 'teste'}}), caches:{keys:async () => []}, matchMedia:() => ({matches:false}),
    localStorage:{getItem:k => ls[k] ?? null, setItem:(k, v) => { ls[k] = String(v); }, removeItem:k => { delete ls[k]; }},
    location:{origin:'https://exemplo.invalid', pathname:'/', href:'https://exemplo.invalid/'},
    document:{querySelectorAll:() => [], getElementById:() => null, querySelector:s => (s.startsWith('.') || s.startsWith('details') || s.startsWith('input[')) ? null : (els[s] ??= el()),
      addEventListener(){}, createElement:el, activeElement:null, body:{appendChild(){}, prepend(){}, classList:{toggle(){}, add(){}, remove(){}}}},
    window:{scrollTo(){}, addEventListener(){}},
  };
  ctx.sessionStorage = ctx.localStorage; ctx.globalThis = ctx; ctx.self = ctx;
  vm.createContext(ctx);
  vm.runInContext(SUPABASE_FALSO + `\nvar supabase = criarSupabaseFalso(${JSON.stringify(dados())}, ${JSON.stringify(who)});`, ctx);
  vm.runInContext(codigoApp(), ctx, {filename:'app.js'});
  const html = () => ctx.document.querySelector('#app').innerHTML;
  const r = code => vm.runInContext(code, ctx);

  await r('iniciar_()');
  const telas = [];
  const ver = (nome, fn, espera) => {
    try { r(fn); r('render()'); const h = html(); telas.push(`${nome}:${h.length}`); ok(h.length > 200, `${who}/${nome}: tela vazia`);
      if (espera) ok(h.includes(espera), `${who}/${nome}: faltou "${espera}"`); }
    catch (e) { falhas++; console.log(`  ✗ ${who}/${nome}: ${e.message}`); }
  };
  if (r('S.ui.dev')) {
    // Acesso DEV: painel, diagnóstico, hora simulada e "ver como" cada pessoa, sem gravar nada
    ver('dev-painel', ``, 'Painel de desenvolvimento');
    await r('A.devDiag()'); ver('dev-diagnostico', ``, 'Tarefas automáticas');
    ver('dev-hora', `A.devHora({v:'08:30'})`, 'simulando 08:30');
    for (const [id, mode, espera] of [['victor', null, 'Para definir'], ['robson', 'app', 'Robson'], ['robson', 'socio', 'Painel'], ['jessica', null, 'Jessica'], ['breno', null, 'Breno'], ['magda', null, 'Magda']])
      ver(`dev-ver-${id}${mode ? '-' + mode : ''}`, `A.devHoraReal(); A.devVer({id:'${id}', mode:${JSON.stringify(mode)}})`, espera);
    let gravou = false; ctx.__gravou = () => { gravou = true; };
    await r(`run(async () => { __gravou(); })`); ok(!gravou, 'sistemas: o DEV conseguiu gravar vendo como outra pessoa');
    ver('dev-treino', `A.devVer({id:'breno'}); A.treino(); A.check({id:'TREINO', it:'T1'})`, 'Feito às');
    ver('dev-volta', `A.devVer({id:''})`, 'Ver o app como');
    ok(!r(`team().some(p => p.role === 'dev')`), 'sistemas: o DEV apareceu na lista da equipe');
  } else if (r('socioView()')) {
    for (const v of ['painel', 'definir', 'hoje', 'ocorrencias', 'relatorios', 'equipe', 'notas', 'gerente', 'pops', 'rotina', 'info'])
      ver(v, `S.ui.view='${v}'; S.ui.open=null; S.ui.pop=null; S.ui.rotEdit=null;`);
    ver('definir-conteudo', `S.ui.view='definir'`, 'POPs para revisar');
    ver('relatorios-pauta', `S.ui.view='relatorios'`, 'Pauta do alinhamento');
    ver('ocorrencias-reposicao', `S.ui.view='ocorrencias'`, 'Álcool 70%');
    ver('rotina-editor', `S.ui.view='rotina'; S.ui.rotEdit='AMB'`, 'foto de referência');
    ver('pop-editor', `S.ui.rotEdit=null; S.ui.view='pops'; S.ui.pop='POP-07'; S.ui.popEdit='POP-07'`);
    ver('conflitos', `S.ui.pop=null; S.ui.popEdit=null; S.ui.view='painel'; if (!Array.isArray(conflitos())) throw new Error('conflitos() não é lista')`);
    if (r(`canEdit()`)) {
      ver('copia', `S.ui.view='info'`, 'Baixar cópia dos dados');
      ver('modo-tv', `S.ui.view='tv'`, 'Iniciar apresentação');
      // Todos os slides ligados, com dados de uma semana de exemplo
      ver('modo-tv-slides', `const c = tvCfg(); Object.keys(c.on).forEach(k => c.on[k] = true); c.nomes = true; c.recado = 'Boa semana!';
        const p = tvPeriodo('passada'), linha = (pid, rot) => ({pessoa_id:pid, rotina_id:rot, previstos:5, no_prazo:4, atraso:1, nao_feito:0, itens_nao:1});
        const tot = [linha('breno','BIN'), linha('magda','ABR'), linha('jessica','RON')];
        const sl = tvSlides(c, {p, dias:[p.de, p.ate], tot, falhas:[{texto:'Copa organizada', rotina:'Banheiros', pop_id:'POP-04', falhas:3}], porDia:[tot, []]});
        if (sl.length !== 11 || sl.some(x => !x.includes('tvs'))) throw new Error('slides: ' + sl.length);`);
    }
  } else {
    const ger = r(`me().role === 'gerente'`);
    for (const t of (ger ? ['agora', 'equipe', 'ocorrencias', 'pops', 'perfil'] : ['hoje', 'pops', 'hist', 'perfil']))
      ver(t, `S.ui.tab='${t}'; S.ui.open=null; S.ui.pop=null;`);
    ver('registrar', `S.ui.tab='${ger ? 'agora' : 'hoje'}'`, 'Falta material ou produto');
    ver('privacidade-perfil', `S.ui.tab='perfil'`, 'Privacidade');
    if (r(`S.inst.some(i => mine(i, S.ui.user))`)) ver('checklist', `S.ui.tab='${ger ? 'agora' : 'hoje'}'; S.ui.open=S.inst.find(i => mine(i, S.ui.user)).id`);
    if (ger) {
      ver('lote', `S.ui.open=null; S.ui.lote=true`, 'Conferência rápida');
      ver('verificar', `S.ui.lote=false; S.ui.open=S.inst.find(i => needsVer(i)).id`, 'Conferência');
    }
    // Treino: abre, marca, registra um "não deu" e conclui sem tocar no servidor
    ver('treino', `S.ui.open=null; S.ui.lote=false; A.treino()`, 'Checklist de treino');
    ver('treino-marca', `A.check({id:'TREINO', it:'T1'})`, 'Feito às');
    ver('treino-fim', `TREINO.checks.T2={at:NOW(),ok:true}; TREINO.checks.T3={at:NOW(),ok:false,note:'teste'}; A.finish({id:'TREINO'})`);
    ok(r(`TREINO === null && S.inst.every(i => i.id !== 'TREINO')`), `${who}/treino: deixou rastro nos números`);
  }
  console.log(`${falhas ? '✗' : '✓'} ${who}: ${r('S.inst.length')} checklists · ${telas.join(' ')}`);
}

(async () => {
  for (const who of PERFIS) await testar(who);
  if (falhas) { console.log(`\n${falhas} problema(s).`); process.exit(1); }
  console.log('\nTodas as telas abriram sem erro.');
})().catch(e => { console.error(e); process.exit(1); });
