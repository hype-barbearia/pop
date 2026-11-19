# Histórico de versões

Cada publicação é um commit na `main` (testado e publicado pelo GitHub Actions). Para voltar a uma versão: `git revert` do commit e push. Mudanças no banco estão em `supabase/migrations/`, com o número indicado.

## 19/11/2026 · ambiente de teste e versões (migração 025)
- Ambiente de teste em teste.pop.hypebarbearia.com, com banco próprio ("Hype POP Teste") montado pelas migrações e comparado com a produção objeto por objeto.
- Branch `teste` publica no teste; `main` publica na produção e cria uma tag `producao-…` por versão.
- Migração 025: 7 funções da produção que não estavam nas migrações agora estão; envio de notificações com endereço do projeto configurável.

## 19/11/2026 · tipos de atividade e cultura (migração 024)
- Tipos separados na Rotina: checklist, ronda, reunião, lembrete, instrução e cultura, com um quadro explicando cada um.
- Reunião (gestão, alinhamento, técnicas, one-on-ones): "Aconteceu / Não aconteceu" e campo de combinados e presença. No one-on-one, o resumo de cultura da semana ao lado de cada nome.
- Instrução ("como fazer") em cada item, editada no checklist; a pessoa lê e não marca.
- Cultura por exceção: padrões de comportamento em Informações da casa; a gerente e os sócios registram só o destaque ou o desvio, por pessoa. A pessoa vê os próprios registros no Perfil. "Sorriso e gentileza" e "Postura" saíram da ronda.
- Rotina: toda linha da tabela abre o editor completo ali mesmo.
- Semana de aprendizado até 28/11.

## 17/11/2026 · desempenho e manutenção (migração 023)
- Carregamento em duas partes: configuração relida no máximo a cada 60 s, histórico uma vez por dia; atualizações em tempo real com 18 consultas em vez de 33.
- Ações das ocorrências limitadas aos mesmos 30 dias das ocorrências.
- Banco: índices, regras de acesso calculadas uma vez por consulta, limpeza diária de registros técnicos.
- CSS sem as 240 regras que nenhuma tela usava (86 KB → 69 KB).
- Publicação: versão da cópia offline automática e conferência das listas de arquivos.
- Documentação do banco em `supabase/README.md`.

## 17/11/2026 · gestão e notas fiscais (migrações 020 a 022)
- Acesso DEV (`sistemas@`): ver como cada pessoa, diagnóstico, registro de acessos, liga/desliga de recursos e simulador.
- Painel de gestão redesenhado; tema claro, escuro ou automático.
- Notas fiscais em três passos, na gestão e no Perfil do barbeiro; lembrete enviado pela gestão.
- Login aceita o código do e-mail de qualquer tamanho.

## 17/11/2026 · lançamento da operação (migrações 014 a 019)
- Tudo editável pelo Victor; nova experiência visual e responsiva.
- Semana de aprendizado, pauta do alinhamento, reposição, registro de cliente, treino, conferência em lote, uso sem internet, aviso de privacidade.
- Modo TV para a reunião; publicação só depois dos testes.

## 16/11/2026 · operação real (migrações 007 a 013)
- Folgas, sábado, ausências, revezamentos, notificações no celular.
- Perfil do colaborador e notas fiscais quinzenais do Salão-Parceiro.
- Início da operação em 17/11/2026, 09:00.

## 13/11/2026 · primeira versão (migrações 001 a 006)
- App de POPs e checklists ligado ao Supabase, domínio pop.hypebarbearia.com e e-mail de acesso com a identidade da Hype.
