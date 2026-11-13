"""Junta index.html + css + js em um arquivo único: dist/index.html (página completa, para abrir ou fazer deploy) e dist/artifact.html (para publicar como Artifact)."""
import re, pathlib
root = pathlib.Path(__file__).parent
html = (root / 'index.html').read_text(encoding='utf-8')
html = html.replace('<link rel="stylesheet" href="css/app.css">', '<style>\n' + (root / 'css/app.css').read_text(encoding='utf-8') + '\n</style>')
html = re.sub(r'<script src="(js/[^"]+)"></script>', lambda m: '<script>\n' + (root / m.group(1)).read_text(encoding='utf-8') + '\n</script>', html)
dist = root / 'dist'
dist.mkdir(exist_ok=True)
# artifact.html: conteúdo da página (o Artifact adiciona doctype, head e viewport)
(dist / 'artifact.html').write_text(html, encoding='utf-8')
# index.html: página completa, abre direto no navegador e serve para deploy (Cloudflare Pages)
head = '<!doctype html>\n<html lang="pt-BR">\n<head>\n<meta charset="utf-8">\n<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">\n'
full = html.replace('</style>', '</style>\n</head>\n<body>', 1)
(dist / 'index.html').write_text(head + full + '\n</body>\n</html>\n', encoding='utf-8')
print('dist/index.html e dist/artifact.html', len(html) // 1024, 'KB')
