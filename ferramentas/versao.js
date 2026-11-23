/* Hype POP · ficha da versão publicada
   Lê o CHANGELOG.md e grava <pasta>/versao.json com o ambiente, a versão atual (a primeira do histórico),
   o commit, a data da publicação e o histórico completo. A página versoes.html lê esse arquivo
   nos dois sites (teste e produção) para mostrar o que está em cada um.
   Uso: node ferramentas/versao.js <pasta do site> <producao|teste> */
const fs = require('fs'), path = require('path'), {execSync} = require('child_process');
const RAIZ = path.join(__dirname, '..');

function lerHistorico(texto = fs.readFileSync(path.join(RAIZ, 'CHANGELOG.md'), 'utf8')){
  const out = []; let atual = null;
  for (const linha of texto.split('\n')) {
    const h = linha.match(/^## (v\d+\.\d+) · (\d\d)\/(\d\d)\/(\d{4}) · (.+?)\s*$/);
    if (h) {
      const mig = h[5].match(/\((migraç(?:ão|ões) [^)]+)\)\s*$/);
      atual = {versao:h[1], data:`${h[4]}-${h[3]}-${h[2]}`, titulo:h[5].replace(/\s*\(migraç[^)]*\)\s*$/, ''), banco:mig ? mig[1] : null, itens:[]};
      out.push(atual); continue;
    }
    if (/^## /.test(linha)) { atual = null; continue; }
    if (atual && /^- /.test(linha)) atual.itens.push(linha.slice(2).trim());
    else if (atual && /^\s+\S/.test(linha) && atual.itens.length) atual.itens[atual.itens.length - 1] += ' ' + linha.trim();
  }
  return out;
}
const num = v => v.slice(1).split('.').map(Number);
const maior = (a, b) => { const [x1, y1] = num(a), [x2, y2] = num(b); return x1 !== x2 ? x1 > x2 : y1 > y2; };

module.exports = {lerHistorico, maior};

if (require.main === module) {
  const [pasta, ambiente] = process.argv.slice(2);
  if (!pasta || !['producao', 'teste'].includes(ambiente)) { console.error('Uso: node ferramentas/versao.js <pasta> <producao|teste>'); process.exit(1); }
  const historico = lerHistorico();
  if (!historico.length) { console.error('CHANGELOG.md sem versões no formato "## vX.Y · DD/MM/AAAA · título"'); process.exit(1); }
  const git = c => { try { return execSync(c, {cwd:RAIZ}).toString().trim(); } catch (e) { return null; } };
  const commit = process.env.GITHUB_SHA || git('git rev-parse HEAD');
  const ficha = {ambiente, versao:historico[0].versao, commit, commit_curto:commit ? commit.slice(0, 7) : null,
    mensagem:git('git log -1 --format=%s'), publicado_em:new Date().toISOString(), historico};
  fs.writeFileSync(path.join(pasta, 'versao.json'), JSON.stringify(ficha, null, 1));
  console.log(`${ambiente}: ${ficha.versao} (${ficha.commit_curto}), ${historico.length} versões no histórico`);
}
