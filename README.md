# Hype POP

**App no ar:** https://pop.hypebarbearia.com (também em https://hype-barbearia.github.io/pop/)

Sistema de Procedimentos Operacionais Padrão da Hype Barbearia. Reúne os POPs da casa, transforma a rotina em checklists com horário e responsável e mostra aos sócios, de longe, se a operação está rodando como foi definido.

- **Sócios** (Victor, e Robson pelo botão "Painel dos sócios"): painel do dia, linha do tempo, ocorrências, equipe, gerente, biblioteca de POPs e rotina.
- **Gerente** (Jessica): lembretes do momento, cobrança de atrasos, conferência dos checklists, rondas dos 10 inegociáveis e ocorrências.
- **Equipe**: checklists do dia com foto quando exigido, POPs do cargo com termo de ciência e histórico pessoal.

A base dos POPs é o documento "HYPE Cultura e POP" v1.0 (outubro de 2026). A concepção completa está em [docs/CONCEITO.md](docs/CONCEITO.md).

## Como funciona

| Parte | Onde |
|---|---|
| App (HTML, CSS e JavaScript, sem build) | `index.html`, `css/`, `js/` |
| Banco, regras de acesso e funções | Supabase, projeto "Hype Barbearia" · `supabase/migrations/` |
| Hospedagem | GitHub Pages, direto da branch `main` |
| Protótipo navegável com dados fictícios | `prototipo/` |

- Login por **link mágico** no e-mail. Só entra quem tem o e-mail cadastrado em `pessoas` (tela Equipe, para os sócios).
- Toda madrugada (00:05 em Recife) o banco cria os checklists do dia a partir da rotina. O app também garante isso ao abrir.
- Antes da **data de início da operação** (Gerente e lembretes → Regras) nenhum checklist é criado.
- Fotos ficam no bucket privado `fotos` do Supabase Storage.
- As ações da equipe passam por funções do banco (`marcar_item`, `concluir`, `conferir`, `cobrar` e outras), que conferem quem pode fazer o quê.

## Publicar uma mudança

Edite os arquivos e faça push para `main`. O GitHub Pages publica sozinho em cerca de um minuto.

Mudança no banco: crie um arquivo novo em `supabase/migrations/` e aplique no Supabase (SQL Editor ou MCP).

## Configuração única

1. **GitHub Pages**: já ativo, publicando a branch `main` na raiz.
2. **Supabase → Authentication → URL Configuration**: em Site URL e Redirect URLs, coloque o endereço do GitHub Pages (`https://pop.hypebarbearia.com/`).
3. **Supabase → Authentication → Emails → SMTP**: configure um SMTP próprio (ex.: Resend). O e-mail padrão do Supabase só envia para membros da organização e tem limite baixo por hora.
4. **Modelo do e-mail "Magic Link"**: inclua `{{ .Token }}` para a pessoa poder digitar o código de 6 números quando o link abrir fora do app instalado.
5. **E-mails da equipe**: o primeiro sócio é cadastrado direto no banco; depois ele cadastra os outros na tela Equipe.
