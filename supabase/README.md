# Banco de dados (Supabase · projeto "Hype Barbearia")

## Como o banco está organizado

| Grupo | Tabelas |
|---|---|
| Pessoas e acesso | `pessoas`, `ausencias`, `privacidade_aceite`, `push_inscricoes`, `dev_acessos`, `recursos` |
| POPs | `pops`, `pop_versoes`, `pop_leituras` |
| Rotina (o que deve acontecer) | `rotinas`, `rotina_janelas`, `rotina_itens`, `rotina_agendamentos`, `rodizio_escala`, `lembretes`, `regras`, `dias_fechados` |
| Operação (o que aconteceu) | `execucoes`, `execucao_itens`, `cobrancas`, `lembretes_feitos`, `ocorrencias`, `ocorrencia_acoes`, `reposicao`, `resumos` |
| Notas fiscais | `nf_valores`, `documentos_fiscais` |
| Cultura | `cultura_padroes`, `cultura_registros` (desvio ou destaque por pessoa; a gestão vê todos, cada pessoa vê os seus) |
| Textos e técnica | `config_textos`, `definicoes`, `notificacoes`, `erros_app` |

- **Leitura:** regras de acesso (RLS) com as funções `eu()`, `sou_membro()`, `sou_socio()`, `sou_gestor()`, `ve_tudo()` e `sou_dev()`. Desde a 023 elas aparecem como `(select sou_socio())`: o resultado é o mesmo, mas o banco calcula uma vez por consulta e não uma vez por linha.
- **Escrita:** a equipe grava só por funções do banco (`marcar_item`, `concluir`, `conferir`, `cobrar`, `lembrar_nf`...), que conferem quem pode fazer o quê. Edição direta de tabela só para o sócio que edita (políticas `socio_insere`, `socio_altera`, `socio_apaga`).

## Tarefas automáticas (pg_cron, horário UTC; Recife = UTC−3)

| Tarefa | Quando | O que faz |
|---|---|---|
| `hype_pop_gerar_dia` | 03:05 (00:05 Recife) | Cria os checklists do dia a partir da rotina |
| `hype_pop_notificar` | a cada 2 min | Avisos do momento (hora, atraso, cobrança, conferência) e envio pela função `notificar` |
| `hype_pop_fiscal` | 13:05 (10:05 Recife) | Lembretes das notas fiscais |
| `hype_pop_limpeza` | 06:30 (03:30 Recife) | Apaga fotos com mais de 90 dias (exceto fotos de referência) |
| `hype_pop_saude` | 09:10, 15:10, 20:10 Recife | Alerta de saúde do sistema aos sócios |
| `hype_pop_limpeza_dados` | 06:40 (03:40 Recife) | `limpar_registros_tecnicos()`: histórico do agendador > 14 dias, avisos enviados > 60 dias, avisos nunca enviados > 7 dias, erros do app > 180 dias |

A `limpeza_dados` não apaga nada da operação (checklists, ocorrências, notas, POPs): só registros técnicos.

## Migrações

Cada mudança no banco é um arquivo novo e numerado em `migrations/`, aplicado no Supabase (SQL Editor ou MCP) e enviado ao GitHub no mesmo commit do app que depende dele. Nunca edite um arquivo já aplicado: crie o próximo número.

| Arquivo | Situação |
|---|---|
| 001 a 005, 007 a 010, 012 a 017, 019 a 024 | Aplicadas (aparecem no histórico de migrações do Supabase; de 016 em diante, sem o número no nome) |
| 006, 011 | Dados (primeiro sócio, CNPJ), aplicados direto pelo SQL Editor |
| 010b, 012b | Correções pequenas aplicadas só no banco; o efeito está consolidado na 018 |
| 018 | **Referência**, não precisa rodar: guarda a versão final, inteira, das funções alteradas por troca de texto nas 008, 010, 014, 016 e 017. Rodar de novo não muda nada |

Para recriar o banco do zero: rode as migrações em ordem numérica (a 018 depois da 017 deixa as funções na versão final).

## Funções e envio

- `functions/notificar`: Edge Function que envia as notificações (Web Push). Chamada pelo banco via `pg_net`.
- `templates/`: modelo do e-mail de acesso (código e link) com a identidade da Hype.
- Chaves das notificações ficam em `privado.config`, fora do alcance do app.
