/* Hype POP · confere que as listas de arquivos do app estão iguais nos três lugares:
   index.html (o que o navegador carrega), sw.js (o que fica guardado para abrir sem internet)
   e tests/ambiente.js (o que os testes abrem). Um arquivo novo esquecido em um deles quebra a publicação. */
const fs = require('fs'), path = require('path');
const {RAIZ, ARQUIVOS} = require('./ambiente');
const ler = f => fs.readFileSync(path.join(RAIZ, f), 'utf8');
const index = [...ler('index.html').matchAll(/<script src="js\/([\w-]+)\.js"><\/script>/g)].map(m => m[1]);
const sw = JSON.parse(ler('sw.js').match(/\.\.\.(\[[^\]]+\])\.map\(f => `\.\/js\//)[1].replace(/'/g, '"'));
const erros = [];
if (index.join() !== ARQUIVOS.join()) erros.push(`tests/ambiente.js difere do index.html:\n  index: ${index}\n  testes: ${ARQUIVOS}`);
if (index.join() !== sw.join()) erros.push(`sw.js difere do index.html:\n  index: ${index}\n  sw: ${sw}`);
for (const f of index) if (!fs.existsSync(path.join(RAIZ, 'js', f + '.js'))) erros.push(`index.html carrega js/${f}.js, que não existe`);
for (const f of fs.readdirSync(path.join(RAIZ, 'js'))) if (!index.includes(f.replace(/\.js$/, ''))) erros.push(`js/${f} existe mas o index.html não carrega`);
// A configuração do teste precisa ter as mesmas chaves da produção (só os valores mudam)
const chaves = f => [...ler(f).match(/const HYPE_CONFIG = \{([\s\S]*?)\};/)[1].matchAll(/^\s*(\w+):/gm)].map(m => m[1]).join();
if (chaves('js/config.js') !== chaves('ambientes/teste/config.js')) erros.push(`ambientes/teste/config.js tem chaves diferentes de js/config.js: ${chaves('ambientes/teste/config.js')} / ${chaves('js/config.js')}`);
if (!/ambiente: 'teste'/.test(ler('ambientes/teste/config.js'))) erros.push('ambientes/teste/config.js precisa ter ambiente: \'teste\'');
if (/fwecscsvfxocgjspdsis/.test(ler('ambientes/teste/config.js'))) erros.push('ambientes/teste/config.js aponta para o banco de PRODUÇÃO');
// Histórico de versões: a página versoes.html e as etiquetas dependem deste formato
const {lerHistorico, maior} = require('../ferramentas/versao.js');
const hist = lerHistorico();
if (!hist.length) erros.push('CHANGELOG.md sem versões no formato "## vX.Y · DD/MM/AAAA · título"');
hist.forEach((h, k) => { if (!h.itens.length) erros.push(`CHANGELOG.md: ${h.versao} sem melhorias listadas`);
  if (k && !maior(hist[k - 1].versao, h.versao)) erros.push(`CHANGELOG.md: ${hist[k - 1].versao} deveria ser maior que ${h.versao} (a mais nova vem primeiro)`); });
if (erros.length) { console.log(erros.join('\n')); process.exit(1); }
console.log(`Listas de arquivos iguais (${index.length} scripts). Histórico com ${hist.length} versões, atual ${hist[0].versao}.`);
