/* Hype POP · página de teste visual (sem internet, dados de exemplo, hora parada às 15:40)
   Uso: node tests/mock.js victor   → gera dist/mock-victor.html para abrir no navegador.
   Perfis: victor, robson, jessica, breno, magda... (qualquer id da equipe) */
const fs = require('fs'), path = require('path');
const {RAIZ, ARQUIVOS, dados, SUPABASE_FALSO, codigoApp} = require('./ambiente');

const who = process.argv[2] || 'breno';
let html = fs.readFileSync(path.join(RAIZ, 'index.html'), 'utf8');
html = html.replace('<link rel="stylesheet" href="css/app.css">', `<style>\n${fs.readFileSync(path.join(RAIZ, 'css/app.css'), 'utf8')}\n</style>`);
html = html.replace(/<script src="https:\/\/cdn[^"]+"><\/script>/, `<script>\n${SUPABASE_FALSO}\nwindow.supabase = criarSupabaseFalso(${JSON.stringify(dados())}, ${JSON.stringify(who)});\n</script>`);
const scripts = ARQUIVOS.map(f => `<script src="js/${f}.js"></script>`);
scripts.forEach(tag => { if (!html.includes(tag)) throw new Error('index.html sem ' + tag); });
html = html.replace(scripts[0], `<script>\n${codigoApp().replace(/<\/script>/g, '<\\/script>')}\n</script>`);
scripts.slice(1).forEach(tag => { html = html.replace(tag + '\n', '').replace(tag, ''); });
fs.mkdirSync(path.join(RAIZ, 'dist'), {recursive:true});
fs.writeFileSync(path.join(RAIZ, 'dist', `mock-${who}.html`), html);
console.log(`dist/mock-${who}.html`);
