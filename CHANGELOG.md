# Histórico de versões

Cada versão tem um número (v1.0, v1.1...). Ela entra primeiro no **teste** (branch `teste`, teste.pop.hypebarbearia.com) e, depois de aprovada, vai para a **produção** (branch `main`, pop.hypebarbearia.com), onde ganha a etiqueta `vX.Y` no GitHub. A página **/versoes.html** de cada site mostra qual versão está em cada ambiente.

Formato de cada versão (a página lê este arquivo): `## vX.Y · DD/MM/AAAA · título (migração NNN)`, seguido das melhorias em linhas começando com `- `. Mudanças no banco ficam em `supabase/migrations/`, com o número indicado.

## v1.7 · 23/11/2026 · Página de versões
- Página /versoes.html em cada site: mostra a versão que está na produção e a que está no teste, e as melhorias de cada versão, marcando o que já foi para a equipe e o que ainda está só no teste.
- Cada publicação grava a ficha da versão (número, commit, data); a produção ganha a etiqueta `vX.Y` no GitHub.
- README: o que conferir no site de teste antes de promover para a produção.

## v1.6 · 19/11/2026 · Ambiente de teste e versões (migração 025)
- Ambiente de teste em teste.pop.hypebarbearia.com, com banco próprio ("Hype POP Teste") montado pelas migrações e comparado com a produção objeto por objeto.
- Branch `teste` publica no teste; `main` publica na produção e cria uma tag `producao-…` por versão.
- Migração 025: 7 funções da produção que não estavam nas migrações agora estão; envio de notificações com endereço do projeto configurável.

## v1.5 · 19/11/2026 · Tipos de atividade e cultura (migração 024)
- Tipos separados na Rotina: checklist, ronda, reunião, lembrete, instrução e cultura, com um quadro explicando cada um.
- Reunião (gestão, alinhamento, técnicas, one-on-ones): "Aconteceu / Não aconteceu" e campo de combinados e presença. No one-on-one, o resumo de cultura da semana ao lado de cada nome.
- Instrução ("como fazer") em cada item, editada no checklist; a pessoa lê e não marca.
- Cultura por exceção: padrões de comportamento em Informações da casa; a gerente e os sócios registram só o destaque ou o desvio, por pessoa. A pessoa vê os próprios registros no Perfil. "Sorriso e gentileza" e "Postura" saíram da ronda.
- Rotina: toda linha da tabela abre o editor completo ali mesmo.
- Semana de aprendizado até 28/11.

## v1.4 · 17/11/2026 · Desempenho e manutenção (migração 023)
- Carregamento em duas partes: configuração relida no máximo a cada 60 s, histórico uma vez por dia; atualizações em tempo real com 18 consultas em vez de 33.
- Ações das ocorrências limitadas aos mesmos 30 dias das ocorrências.
- Banco: índices, regras de acesso calculadas uma vez por consulta, limpeza diária de registros técnicos.
- CSS sem as 240 regras que nenhuma tela usava (86 KB → 69 KB).
- Publicação: versão da cópia offline automática e conferência das listas de arquivos.
- Documentação do banco em `supabase/README.md`.

## v1.3 · 17/11/2026 · Gestão e notas fiscais (migrações 020 a 022)
- Acesso DEV (`sistemas@`): ver como cada pessoa, diagnóstico, registro de acessos, liga/desliga de recursos e simulador.
- Painel de gestão redesenhado; tema claro, escuro ou automático.
- Notas fiscais em três passos, na gestão e no Perfil do barbeiro; lembrete enviado pela gestão.
- Login aceita o código do e-mail de qualquer tamanho.

## v1.2 · 17/11/2026 · Lançamento da operação (migrações 014 a 019)
- Tudo editável pelo Victor; nova experiência visual e responsiva.
- Semana de aprendizado, pauta do alinhamento, reposição, registro de cliente, treino, conferência em lote, uso sem internet, aviso de privacidade.
- Modo TV para a reunião; publicação só depois dos testes.

## v1.1 · 16/11/2026 · Operação real (migrações 007 a 013)
- Folgas, sábado, ausências, revezamentos, notificações no celular.
- Perfil do colaborador e notas fiscais quinzenais do Salão-Parceiro.
- Início da operação em 17/11/2026, 09:00.

## v1.0 · 13/11/2026 · Primeira versão (migrações 001 a 006)
- App de POPs e checklists ligado ao Supabase, domínio pop.hypebarbearia.com e e-mail de acesso com a identidade da Hype.
