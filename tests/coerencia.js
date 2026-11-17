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
if (erros.length) { console.log(erros.join('\n')); process.exit(1); }
console.log(`Listas de arquivos iguais (${index.length} scripts).`);
