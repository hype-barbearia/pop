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
| Banco, regras de acesso e funções | Supabase, projeto "Hype Barbearia" · `supabase/` (ver [supabase/README.md](supabase/README.md)) |
| Hospedagem | GitHub Pages, publicado pelo GitHub Actions depois dos testes (`.github/workflows/publicar.yml`) |
| Protótipo navegável com dados fictícios | `prototipo/` |

- Login por **link mágico** no e-mail. Só entra quem tem o e-mail cadastrado em `pessoas` (tela Equipe, para os sócios).
- Toda madrugada (00:05 em Recife) o banco cria os checklists do dia a partir da rotina. O app também garante isso ao abrir.
- Antes da **data de início da operação** (Gerente e lembretes → Regras) nenhum checklist é criado.
- Fotos ficam no bucket privado `fotos` do Supabase Storage.
- As ações da equipe passam por funções do banco (`marcar_item`, `concluir`, `conferir`, `cobrar` e outras), que conferem quem pode fazer o quê.

## O que o sistema faz (versão de 16/11/2026)

- **Checklists do dia** criados toda madrugada, respeitando folga, sábado (08:50 e fechamento às 18h), dias sem expediente, ausências com substituto e a escala dos revezamentos.
- **Notificações no celular** (Web Push): hora do checklist, atraso para a pessoa e para a gerente, escalonamento aos sócios, cobrança na hora, conferência pendente, lembretes fixos, aviso da ronda e resumo do dia às 21h. No iPhone o app precisa estar na Tela de Início.
- **Funciona sem internet** para marcar itens e concluir: as marcações ficam guardadas e saem quando a conexão volta. Foto precisa de internet.
- **Victor** edita tudo: equipe, e-mails, folgas, POPs (com versões guardadas), itens dos checklists, rotinas novas, escala dos revezamentos e regras. **Robson** vê tudo e não altera. **Jessica** confere, cobra, faz as rondas, trata ocorrências e registra ausências e dias fechados.
- **Ocorrências** com quem resolve, prazo e foto. A equipe também pode avisar a gerência de um problema.
- **Relatórios** por mês, por pessoa e por checklist, com planilha CSV.
- **Fotos** com mais de 90 dias são apagadas toda madrugada.
- **Erros** que aparecem no celular de alguém ficam registrados na tabela `erros_app`.

- **Perfil** para cada pessoa: dados, e-mail, folga, termos assinados e notificações. Para os barbeiros parceiros, as **notas fiscais quinzenais do Salão-Parceiro**: do dia 1 ao 15, nota até o dia 16; do dia 16 ao fim do mês, nota até o dia 1º. A gestão informa o valor de cada barbeiro em **Notas fiscais**, ele recebe o aviso, emite a NFS-e para a Hype e envia número e arquivo. A gestão confere e aceita ou recusa com motivo. Também há o comprovante mensal do DAS do MEI (vence dia 20).

- **Tudo editável pelo Victor:** nome, POP, tipo, dias, quem faz (fixo, revezamento, lista ou cargo), horários (incluir, remover, dias específicos), itens (texto, foto, crítico, ordem) e conferência de cada checklist; **agenda avulsa** para o que não tem horário fixo (como a reunião de técnicas); lembretes (hora, texto, dias, apagar); POPs (texto, área, quem assina, preços, indicações, arquivar); **Informações da casa** (cultura, horário, posições, reuniões, áreas); pessoas (cargo, função, turno, folga, parceiro, e-mail); regras e início da operação.

Peças no Supabase: função `notificar` (Edge Function), seis tarefas automáticas `hype_pop_*` (lista e horários em [supabase/README.md](supabase/README.md)), buckets privados `fotos` e `documentos`, chaves das notificações em `privado.config`.

## Publicar uma mudança

Edite os arquivos e faça push para `main`. O GitHub testa e publica sozinho em cerca de um minuto; se um teste falhar, a versão no ar continua a mesma. Registre a mudança em [CHANGELOG.md](CHANGELOG.md).

Arquivo novo em `js/`: inclua nos três lugares (`index.html`, lista `ARQUIVOS` do `sw.js` e de `tests/ambiente.js`); `tests/coerencia.js` barra a publicação se faltar em algum. A versão da cópia offline (`CACHE` no `sw.js`) é trocada sozinha pelo commit a cada publicação.

Mudança no banco: crie um arquivo novo em `supabase/migrations/` e aplique no Supabase (SQL Editor ou MCP).

## Configuração única

1. **GitHub Pages**: já ativo, com origem "GitHub Actions" (o workflow `publicar.yml`).
2. **Supabase → Authentication → URL Configuration**: em Site URL e Redirect URLs, coloque o endereço do GitHub Pages (`https://pop.hypebarbearia.com/`).
3. **Supabase → Authentication → Emails → SMTP**: configure um SMTP próprio (ex.: Resend). O e-mail padrão do Supabase só envia para membros da organização e tem limite baixo por hora.
4. **Modelo do e-mail "Magic Link"**: inclua `{{ .Token }}` para a pessoa poder digitar o código de 6 números quando o link abrir fora do app instalado.
5. **E-mails da equipe**: o primeiro sócio é cadastrado direto no banco; depois ele cadastra os outros na tela Equipe.

## Testes e publicação

- `node tests/coerencia.js` confere que a lista de scripts é a mesma no `index.html`, no `sw.js` e nos testes.
- `node tests/smoke.js` abre todas as telas de todos os tipos de acesso (sócio, Robson, gerente, barbeiro, atendente) com dados de exemplo e falha se alguma quebrar.
- `node tests/mock.js victor` gera `dist/mock-victor.html` para conferir o visual no navegador, sem internet (hora parada às 15:40).
- No GitHub, `.github/workflows/publicar.yml` roda os testes a cada envio para a `main` e só publica em pop.hypebarbearia.com se passarem.
- `supabase/migrations/018_funcoes_completas.sql` guarda a versão final, inteira, das funções que foram ajustadas por troca de texto.

## Recursos de 17/11/2026

- Semana de aprendizado (Gerente e lembretes): até a data definida, atraso não escala aos sócios e não entra na média.
- Pauta automática do alinhamento de segunda (Relatórios e app da gerente), com o que mais falhou, atrasos, clientes, reposição e POPs pendentes.
- POPs para revisar (Para definir): item com 3 ou mais "não feito" em 14 dias.
- Registrar: problema, falta de material (lista de reposição da gerente) e elogio ou reclamação de cliente.
- Status da equipe: quem já entrou, quem ativou as notificações e quem leu o aviso de privacidade.
- Foto de referência por item ("como deve ficar"), editada em Rotina e checklists; não é apagada pela limpeza de 90 dias.
- Checklist de treino no primeiro acesso, só no aparelho, sem entrar nos números.
- Conferência em lote para a gerente, com as fotos lado a lado.
- O app abre sem internet com os dados do dia guardados no aparelho; o cache é apagado ao sair.
- Aviso de privacidade (LGPD) com registro de ciência, também no Perfil.
- Cópia de segurança dos dados em arquivo (Informações da casa, só o Victor).
- Alerta de saúde do sistema aos sócios (09:10, 15:10 e 20:10): dia sem checklists, tarefas automáticas com falha, avisos presos e erros do app.

## Acesso DEV

- `sistemas@hypebarbearia.com` entra como perfil `dev` (migração 020): lê tudo, como os sócios, e não altera nada de gestão.
- Painel DEV: "ver como" qualquer pessoa (o app exatamente como ela vê, com os dados reais, só leitura), hora simulada, diagnóstico do sistema (tarefas automáticas, avisos, acessos e erros), aviso de teste no aparelho e limpeza do app no aparelho.
- O DEV não entra em rotinas, listas da equipe, status nem números.
- Registro de acessos (migração 021): cada visão aberta pelo DEV e cada simulador ficam gravados; os sócios veem em Equipe e ausências.
- Recursos (liga/desliga): Liberado, Só DEV ou Desligado, por recurso (`recurso('chave')` no app). Só o DEV altera.
- Simulador (`js/simulador.js`): dia fictício com a rotina, as pessoas e os POPs reais; as ações funcionam, mas tudo fica na memória do aparelho.

## Desempenho e manutenção (17/11/2026)

- **Carregamento em duas partes** (`buscar()` em `js/data.js`): o que muda durante o dia (checklists, ocorrências, notas, reposição) é relido a cada atualização; a configuração (pessoas, POPs, rotinas, regras, textos) é relida no máximo a cada 60 s ou logo depois de uma ação do próprio usuário; o histórico de 4 semanas, uma vez por dia; a geração do dia, uma vez por dia por sessão. As atualizações em tempo real passaram de 33 para 18 consultas.
- **Ações das ocorrências**: só as dos últimos 30 dias, como as próprias ocorrências (antes vinham todas, desde o início).
- **Banco** (migração 023): índices para as buscas por dia, checklist e pessoa; regras de acesso calculadas uma vez por consulta; limpeza diária de registros técnicos.
- **CSS**: 240 regras que não eram usadas por nenhuma tela foram retiradas (86 KB → 69 KB), conferido elemento por elemento em 184 telas.
