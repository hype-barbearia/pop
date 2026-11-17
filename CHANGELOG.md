# Histórico de versões

Cada publicação é um commit na `main` (testado e publicado pelo GitHub Actions). Para voltar a uma versão: `git revert` do commit e push. Mudanças no banco estão em `supabase/migrations/`, com o número indicado.

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
