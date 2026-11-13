-- Hype POP · 002 · dados iniciais do documento "HYPE Cultura e POP" v1.0 (outubro de 2026)
-- Idempotente: pode rodar de novo sem duplicar.

insert into pessoas (id, nome, papel, rotulo, turno, folga, socio, cor, ordem) values
  ('victor', 'Victor', 'socio', 'Sócio majoritário · liderança estratégica', null, null, false, 30, 0),
  ('jessica', 'Jessica', 'gerente', 'Gerente · líder da gerência', 'agenda, recepção e rotina', null, false, 40, 1),
  ('robson', 'Robson', 'barbeiro', 'Sócio técnico · barbeiro', 'sem horário fixo', 1, true, 28, 2),
  ('breno', 'Breno', 'barbeiro', 'Barbeiro de abertura', 'abertura, 08:50', 3, false, 345, 3),
  ('daniel', 'Daniel', 'barbeiro', 'Barbeiro de abertura', 'abertura, 08:50', 3, false, 145, 4),
  ('durval', 'Durval', 'barbeiro', 'Barbeiro de fechamento', 'fechamento, 10:50', 2, false, 205, 5),
  ('heberth', 'Heberth', 'barbeiro', 'Barbeiro de fechamento', 'fechamento, 10:50', 2, false, 262, 6),
  ('magda', 'Magda', 'atendente', 'Atendente de abertura', 'abertura, 08:30', null, false, 320, 7),
  ('suellen', 'Suellen', 'atendente', 'Atendente de fechamento', 'fechamento, até 20:00', null, false, 180, 8)
on conflict (id) do nothing;

insert into pops (id, titulo, area, cargos, quem, dono, frequencia, objetivo, materiais, passos, qualidade, erros, tabelas, guia, versao, atualizado, aprovado_por, ordem) values
  ('POP-00', 'Os 10 inegociáveis HYPE', 'cultura', '{"todos"}', 'Todos, todos os dias', 'Jessica', 'Sempre', 'Se você lembrar de apenas uma página do POP, que seja esta. É o que a gerência acompanha de perto.', '[]'::jsonb, '[{"t":"O cliente vem primeiro: ao chegar um cliente, qualquer outra tarefa para.","crit":true},{"t":"Sorriso e gentileza em todo contato: balcão, cadeira, lavatório e WhatsApp.","crit":true},{"t":"Benefícios sempre oferecidos: café coado, expresso, cappuccino, água e água com gás, servidos na bandeja.","crit":true},{"t":"Todo corte termina no lavatório: o barbeiro direciona e a atendente lava o cabelo.","crit":true},{"t":"Head Spa para 100%: oferecido a todo cliente que vai ao lavatório e realizado sempre que aceito.","crit":true},{"t":"Confirmou, agendou: horário confirmado entra na agenda na hora, com preferência de barbeiro perguntada.","crit":true},{"t":"Regra dos 15 minutos: encaixe só se o próximo esperar até 15 min. Atraso acima de 15 min perde o horário.","crit":true},{"t":"Comanda fechada na saída: nenhum cliente sai com comanda aberta.","crit":true},{"t":"Pontualidade e casa pronta: barbeiros de abertura às 08:50, barbeiros de fechamento às 10:50, sábado todos às 08:50. Bancada limpa antes de sair.","crit":true},{"t":"Postura profissional: foco total no cliente da cadeira, sem conversas paralelas, sem temas polêmicos ou promíscuos, sem falar mal da equipe. Nunca gritar.","crit":true}]'::jsonb, '[]'::jsonb, '[]'::jsonb, null, null, 1, 'out/2026', 'Jessica e Victor', 0),
  ('POP-01', 'Abertura', 'abertura', '{"atendente","barbeiro"}', 'Atendente de abertura (Magda) e barbeiros de abertura', 'Jessica', 'Diário, 08:30 às 09:00', 'A primeira impressão do dia é construída antes do primeiro cliente entrar.', '[]'::jsonb, '[{"t":"08:30: conferir o funcionamento dos ar-condicionados da recepção, da área de corte e do VIX do lavatório."},{"t":"Conferir se todas as luzes estão ligadas, incluindo as luzes amarelas do lavatório."},{"t":"Fazer a limpeza da barbearia: área interna e banheiros."},{"t":"Passar o café coado."},{"t":"Garantir que as playlists da recepção e do lavatório estejam tocando."},{"t":"08:50: barbeiros de abertura chegam e todos os barbeiros presentes retiram as grades."},{"t":"Os barbeiros de abertura ajudam a atendente na organização e conferência da abertura, exceto se já houver cliente para atender."},{"t":"10:50: chegada dos barbeiros de fechamento. Aos sábados, todos chegam às 08:50."},{"t":"11:30: ligar e conferir o VIX da área gourmet."}]'::jsonb, '[]'::jsonb, '[]'::jsonb, null, null, 1, 'out/2026', 'Jessica e Victor', 1),
  ('POP-02', 'Recepção', 'recepcao', '{"gerente","atendente"}', 'Gerente e atendentes', 'Jessica', 'Todo o expediente', 'Gerente e atendentes são a voz da HYPE no WhatsApp, no Direct e no balcão.', '[]'::jsonb, '[{"t":"Sempre fechar a comanda na saída do cliente. Comanda aberta é atendimento inacabado e erro de caixa no fim do dia.","crit":true},{"t":"Começar a responder todos os clientes às 09:00 (atendente de abertura)."},{"t":"Sempre responder o primeiro contato se identificando."},{"t":"Atenção focal ao WhatsApp e ao Direct durante a recepção."},{"t":"Fazer o plano dos clientes."},{"t":"Confirmar o agendamento com o cliente pelo WhatsApp 1 hora antes do atendimento."}]'::jsonb, '["Exemplo de primeiro contato: \"Olá! Aqui é a Jessica, da HYPE Barbearia. Como posso te ajudar hoje?\""]'::jsonb, '[]'::jsonb, null, null, 1, 'out/2026', 'Jessica e Victor', 2),
  ('POP-03', 'Agenda', 'agenda', '{"gerente","atendente"}', 'Gerente e atendentes', 'Jessica', 'Todo o expediente', 'A agenda é o coração da operação. Cada minuto mal controlado vira espera para alguém.', '[]'::jsonb, '[{"t":"Manter a lista de horário de chegada dos barbeiros: ela define a fila de atendimentos."},{"t":"Horário pedido e confirmado entra na agenda imediatamente. Tem prioridade sobre qualquer outra tarefa.","crit":true},{"t":"Sempre perguntar se o cliente tem preferência de barbeiro."},{"t":"Encaixe só se o próximo cliente esperar no máximo 15 minutos. Avaliar o cliente em atendimento, o próximo agendado e a capacidade técnica do barbeiro.","crit":true},{"t":"Cliente com mais de 15 minutos de atraso perde o horário: aguarda o próximo encaixe disponível ou reagenda.","crit":true},{"t":"Todo encaixe é comunicado obrigatoriamente ao barbeiro e à recepção."},{"t":"Se a resposta for não em qualquer etapa do encaixe, oferecer o próximo horário livre ou outro barbeiro disponível."}]'::jsonb, '["Comunique o atraso com gentileza: a regra existe para respeitar quem chegou no horário."]'::jsonb, '[]'::jsonb, null, null, 1, 'out/2026', 'Jessica e Victor', 3),
  ('POP-04', 'Atendimento: atendentes', 'atendimento', '{"atendente"}', 'Magda e Suellen', 'Jessica', 'A cada cliente e durante o expediente', 'O cliente sente a HYPE nos detalhes: o sorriso, a bandeja, o café no ponto, o Head Spa oferecido no momento certo.', '[]'::jsonb, '[{"t":"O cliente vem antes de tudo. Ao chegar um cliente, pare qualquer outra tarefa para atendê-lo.","crit":true},{"t":"Atender sempre com sorriso no rosto e gentileza."},{"t":"Oferecer todos os benefícios: café coado, expresso, cappuccino, água e água com gás. Servir sempre com a bandeja."},{"t":"Lavar o cabelo do cliente após todo serviço de corte e acabamento."},{"t":"Oferecer o Head Spa a todos os clientes que forem ao lavatório: 15 min (R$ 39,90) ou 30 min (R$ 66,90).","crit":true},{"t":"Dominar a tabela de preços dos produtos e serviços."},{"t":"Conferir com regularidade a sala de Spa (organização e limpeza) e os banheiros."},{"t":"Aguar as plantas às segundas e quintas, em revezamento."},{"t":"Limpar gradis e produtos às segundas, quartas e sextas, alternando."},{"t":"TV do Lounge, por padrão, nos jogos da ESPN pelo Disney+."},{"t":"Posição padrão: Magda no balcão do Lounge, Suellen no sofá da recepção."},{"t":"Cumprir o horário de almoço: abertura 12h às 13h, fechamento 14h às 15h."}]'::jsonb, '["Como oferecer o Head Spa: \"Já que você está aqui, gostaria de aproveitar e fazer o nosso Head Spa? É um momento de relaxamento para fechar o atendimento.\""]'::jsonb, '["Pressionar o cliente para aceitar o Head Spa."]'::jsonb, null, null, 1, 'out/2026', 'Jessica e Victor', 4),
  ('POP-05', 'Barbeiros: posturas gerais', 'barbeiros', '{"barbeiro"}', 'Breno, Daniel, Durval, Heberth e Robson', 'Robson (técnica) e Jessica (rotina)', 'Todo o expediente', 'O barbeiro HYPE é um artista técnico: entrega estética com estratégia e cuida do espaço como cuida do corte.', '[]'::jsonb, '[{"t":"Manter a bancada organizada ao longo do dia."},{"t":"Limpar e organizar a bancada antes de sair da barbearia.","crit":true},{"t":"Limpar a bancada infantil diariamente, em revezamento."},{"t":"Atenção constante ao cumprimento dos horários dos clientes."},{"t":"Dominar a tabela de preços dos produtos e serviços."},{"t":"Cliente chegou? Barbeiros sentados no sofá cedem o lugar imediatamente."},{"t":"Sem atendimento e com atendentes sobrecarregadas: se prontificar a servir água, água com gás e café coado."},{"t":"Videogame: seu cliente chegou, encerre na hora. Mais de um cliente no Lounge sem jogar, encerre na hora."},{"t":"Participar da reunião de técnicas com o Robson, a cada duas semanas, na segunda às 19h30."}]'::jsonb, '["O cliente recebe o mesmo resultado com qualquer barbeiro da casa."]'::jsonb, '[]'::jsonb, null, null, 1, 'out/2026', 'Jessica e Victor', 5),
  ('POP-06', 'Barbeiros: padrão de atendimento', 'barbeiros', '{"barbeiro"}', 'Breno, Daniel, Durval, Heberth e Robson', 'Robson', 'A cada cliente', 'Da cadeira ao lavatório, cada atendimento deixa no cliente a sensação de cuidado, relaxamento e renovação.', '[]'::jsonb, '[{"t":"Atender com sorriso no rosto e gentileza."},{"t":"Assim que o cliente sentar, perguntar se aceita um benefício: café, expresso, cappuccino, água ou água com gás."},{"t":"Manter um diálogo amistoso e interativo, sempre que o cliente estiver disposto."},{"t":"Ao finalizar todo corte e acabamento, direcionar o cliente ao lavatório.","crit":true},{"t":"Conduzir a conversa, de forma intencional, para entender alguma dor ou necessidade e apresentar a solução com produtos e serviços extras."},{"t":"1:1, foco total no cliente da cadeira. Conversa só com quem está sendo atendido, exceto quando o próprio cliente puxa conversa com outra pessoa.","crit":true}]'::jsonb, '[]'::jsonb, '["Puxar ou alimentar temas polêmicos.","Estimular temas promíscuos, mesmo que o cliente puxe o assunto.","Conversas paralelas durante o atendimento.","Falar mal da equipe para os clientes.","Discutir problemas operacionais na frente dos clientes.","Gritar na barbearia."]'::jsonb, null, null, 1, 'out/2026', 'Jessica e Victor', 6),
  ('POP-07', 'Preços, Linha HYPE Premium e indicações', 'vendas', '{"todos"}', 'Gerente, atendentes e barbeiros', 'Robson (produtos) e Jessica', 'Sempre', 'Saber o preço na ponta da língua e o que cada ativo faz transmite segurança e autoridade. Vender na HYPE é resolver um problema do cliente.', '[]'::jsonb, '[{"t":"Perceba: observe pele, couro cabeludo, cabelo, barba, nariz, orelha e sobrancelha."},{"t":"Pergunte: descubra o que o cliente usa hoje e o que o incomoda."},{"t":"Explique: conte o que o ativo faz. Ex.: \"a niacinamida do Balm equilibra a pele e reduz a vermelhidão\"."},{"t":"Mostre: use o produto na finalização e deixe o cliente sentir o resultado."},{"t":"Ofereça: indique o produto ou o combo, sem insistir depois de um \"não\".","crit":true}]'::jsonb, '[]'::jsonb, '["Empurrar produto ou serviço.","Indicar sem ter percebido uma necessidade."]'::jsonb, '[["Cabelo",[["Corte","R$ 75,00"],["Acabamento","R$ 30,00"],["Penteado","R$ 29,90"],["Hidratação capilar","R$ 30,00"],["Botox capilar","a partir de R$ 129,90"],["Camuflagem dos fios brancos","R$ 50,00"],["Reflexo (luzes)","a partir de R$ 129,90"],["Platinado (Nevou)","a partir de R$ 199,90"]]],["Barba",[["Barba","R$ 55,00"],["Barboterapia","R$ 79,90"],["Hidratação de barba","R$ 30,00"],["Pigmentação de barba","R$ 35,00"]]],["Detalhes e combos",[["Sobrancelha","R$ 29,90"],["Depilação nariz","R$ 29,90"],["Depilação orelha","R$ 34,90"],["Cabelo e barba","R$ 110,00"],["Depilação nariz e orelha","R$ 50,00"]]],["Head Spa",[["Head Spa 15 min","R$ 39,90"],["Head Spa 30 min","R$ 66,90"]]],["Linha HYPE Premium",[["Shampoo Ice Cold · 290 ml","R$ 89,00"],["Condicionador Ice Cold · 290 ml","R$ 89,90"],["Leave-in · 140 ml","R$ 99,90"],["Cera Matte · 100 g","R$ 110,00"],["Cera Brilho · 100 g","R$ 110,00"],["Cera em Pó · 5 g","R$ 110,00"],["Balm para barba · 140 ml","R$ 99,90"],["Óleo para barba · 30 ml","R$ 89,90"],["Combo Shampoo + Condicionador Ice","R$ 160,00"],["Combo Balm + Óleo","R$ 169,00"]]]]'::jsonb, '[["Fios aparentes no nariz ou na orelha","Depilação nariz / orelha · combo (R$ 50,00)",""],["Sobrancelha sem forma ou com fios longos","Sobrancelha",""],["Fios brancos que incomodam","Camuflagem dos fios brancos",""],["Barba ressecada, áspera ou rebelde","Hidratação de barba · Barboterapia","Combo Balm + Óleo"],["Barba opaca, sem brilho ou com frizz","Hidratação de barba","Óleo para barba"],["Falhas ou pouca densidade na barba","Pigmentação de barba","Balm para barba"],["Couro cabeludo oleoso ou com caspa","Head Spa","Shampoo Ice Cold"],["Fios fracos ou com queda","Hidratação capilar · Head Spa","Shampoo Ice Cold"],["Cabelo ressecado, opaco ou com frizz","Hidratação capilar · Botox capilar","Leave-in · Combo Shampoo + Condicionador"],["Cliente tenso, cansado ou estressado","Head Spa 15 ou 30 min","Shampoo + Condicionador Ice"],["Corte e barba no mesmo dia","Combo cabelo e barba (economia de R$ 20,00)","Cera do estilo do corte"],["Evento, foto ou ocasião especial","Penteado","Cera Brilho · Matte · Pó"],["Vontade de mudar o visual","Reflexo (luzes) · Platinado (Nevou)","Leave-in · Condicionador Ice"]]'::jsonb, 1, 'out/2026', 'Jessica e Victor', 7),
  ('POP-08', 'A jornada do cliente', 'jornada', '{"todos"}', 'Toda a equipe, cada etapa com um responsável', 'Jessica', 'A cada cliente', 'O cliente sai sentindo cuidado, relaxamento e renovação, e com vontade de voltar.', '[]'::jsonb, '[{"t":"Primeiro contato (recepção): responder se identificando, perguntar preferência de barbeiro, colocar na agenda na hora."},{"t":"Chegada (atendentes e barbeiros): sorriso e boas-vindas, barbeiros cedem o sofá, videogame encerrado se necessário."},{"t":"Espera no Lounge (atendentes): oferecer todos os benefícios, servidos na bandeja, TV na ESPN."},{"t":"Na cadeira (barbeiro): perguntar se aceita um benefício, diálogo amistoso, entender necessidades."},{"t":"Fim do corte (barbeiro): direcionar ao lavatório após todo corte e acabamento."},{"t":"Lavatório (atendentes): lavar o cabelo, oferecer o Head Spa a 100%, realizar se aceito."},{"t":"Produtos e extras (barbeiro e recepção): indicar o serviço extra ou o produto HYPE Premium para a necessidade identificada."},{"t":"Saída (recepção): fechar a comanda e despedida cordial.","crit":true}]'::jsonb, '[]'::jsonb, '[]'::jsonb, null, null, 1, 'out/2026', 'Jessica e Victor', 8),
  ('POP-09', 'Fechamento', 'fechamento', '{"atendente","barbeiro"}', 'Atendente de fechamento (Suellen) e barbeiros', 'Jessica', 'Diário, 20:00 (sábado 18:00)', 'Fechar bem é abrir bem no dia seguinte. A casa fica pronta para a equipe da manhã.', '[]'::jsonb, '[{"t":"Deixar copa, lavatório e salão limpos e organizados."},{"t":"Deixar a cafeteira limpa e pronta para passar o café pela manhã."},{"t":"Emitir o relatório da maquineta e grampear as vias de pagamento do dia."},{"t":"Barbeiros: limpar e organizar a própria bancada antes de sair."},{"t":"Fechar as grades conforme a escala: seg, qua e sex Durval e Heberth; ter, qui e sáb Breno e Daniel."},{"t":"Antes de apagar as luzes, todas as comandas do dia fechadas e conferidas com o relatório da maquineta.","crit":true}]'::jsonb, '[]'::jsonb, '[]'::jsonb, null, null, 1, 'out/2026', 'Jessica e Victor', 9),
  ('POP-10', 'Rotina de reuniões', 'gestao', '{"todos"}', 'Toda a equipe', 'Jessica e Robson', 'Semanal e quinzenal', 'Encontros fixos para alinhar a equipe, padronizar a técnica e acompanhar cada profissional de perto.', '[]'::jsonb, '[{"t":"Segunda, 14:00 às 15:00: reunião de gestão (semanal)."},{"t":"Segunda, 19:00 às 19:30: alinhamento semanal."},{"t":"Segunda, 19:30 às 20:30: técnicas com Robson, a cada duas semanas, logo após o alinhamento."},{"t":"Terça: one-on-ones de 30 min com Breno 09:00, Magda 09:30, Daniel 10:00, Heberth 10:30 e Suellen 11:00."},{"t":"Quarta: one-on-ones com Durval 09:00 e Jessica 09:30."},{"t":"Pontualidade como em qualquer atendimento.","crit":true}]'::jsonb, '["Próximas reuniões de técnicas: 16/11, 30/11 e 14/12."]'::jsonb, '[]'::jsonb, null, null, 1, 'out/2026', 'Jessica e Victor', 10)
on conflict (id) do nothing;

insert into rotinas (id, titulo, pop_id, tipo, conferir, dias, cada, cada_papel, junto, quinzenal, ordem) values
  ('ABR', 'Abertura da barbearia', 'POP-01', 'check', true, '{"1","2","3","4","5","6"}', null, null, null, false, 0),
  ('BIN', 'Chegada e grades', 'POP-01', 'check', true, '{"1","2","3","4","5","6"}', '{"breno","daniel"}', null, null, false, 1),
  ('REC', 'Recepção aberta', 'POP-02', 'check', true, '{"1","2","3","4","5","6"}', null, null, null, false, 2),
  ('PLA', 'Plantas aguadas', 'POP-04', 'check', true, '{"1","4"}', null, null, null, false, 3),
  ('GRD', 'Gradis e produtos limpos', 'POP-04', 'check', true, '{"1","3","5"}', null, null, null, false, 4),
  ('BIF', 'Chegada do fechamento', 'POP-01', 'check', true, '{"1","2","3","4","5","6"}', '{"durval","heberth"}', null, null, false, 5),
  ('AMB', 'Conferência de banheiros e Spa', 'POP-04', 'check', true, '{"1","2","3","4","5","6"}', null, null, null, false, 6),
  ('GOU', 'VIX da área gourmet', 'POP-01', 'check', false, '{"1","2","3","4","5","6"}', null, null, null, false, 7),
  ('RON', 'Ronda dos inegociáveis', 'POP-00', 'ronda', false, '{"1","2","3","4","5","6"}', null, null, null, false, 8),
  ('INF', 'Bancada infantil', 'POP-05', 'check', true, '{"1","2","3","4","5","6"}', null, null, null, false, 9),
  ('FEC', 'Fechamento da barbearia', 'POP-09', 'check', true, '{"1","2","3","4","5","6"}', null, null, null, false, 10),
  ('BFE', 'Bancada limpa antes de sair', 'POP-05', 'check', true, '{"1","2","3","4","5","6"}', null, 'barbeiro', null, false, 11),
  ('GRA', 'Grades fechadas', 'POP-09', 'check', true, '{"2","4","6"}', null, null, '{"daniel"}', false, 12),
  ('GRB', 'Grades fechadas', 'POP-09', 'check', true, '{"1","3","5"}', null, null, '{"heberth"}', false, 13),
  ('GES', 'Reunião de gestão', 'POP-10', 'check', false, '{"1"}', null, null, null, false, 14),
  ('ALI', 'Alinhamento semanal', 'POP-10', 'check', false, '{"1"}', null, null, null, false, 15),
  ('TEC', 'Reunião de técnicas', 'POP-10', 'check', false, '{"1"}', null, null, null, true, 16),
  ('O1T', 'One-on-ones de terça', 'POP-10', 'check', false, '{"2"}', null, null, null, false, 17),
  ('O1Q', 'One-on-ones de quarta', 'POP-10', 'check', false, '{"3"}', null, null, null, false, 18)
on conflict (id) do nothing;

insert into rotina_janelas (rotina_id, inicio, prazo, responsavel)
select v.* from (values
  ('ABR', time '08:30', time '09:00', 'magda'),
  ('BIN', time '08:50', time '09:00', null::text),
  ('REC', time '09:00', time '09:15', 'magda'),
  ('PLA', time '10:00', time '12:00', 'magda'),
  ('GRD', time '10:00', time '12:00', 'suellen'),
  ('BIF', time '10:50', time '11:00', null::text),
  ('AMB', time '11:00', time '11:30', 'magda'),
  ('AMB', time '14:00', time '14:30', 'magda'),
  ('AMB', time '17:00', time '17:30', 'suellen'),
  ('GOU', time '11:30', time '11:45', 'magda'),
  ('RON', time '12:00', time '12:30', 'jessica'),
  ('RON', time '16:30', time '17:00', 'jessica'),
  ('INF', time '19:40', time '20:10', 'daniel'),
  ('FEC', time '20:00', time '20:30', 'suellen'),
  ('BFE', time '20:00', time '20:20', null::text),
  ('GRA', time '20:20', time '20:40', 'breno'),
  ('GRB', time '20:20', time '20:40', 'durval'),
  ('GES', time '14:00', time '15:00', 'jessica'),
  ('ALI', time '19:00', time '19:30', 'jessica'),
  ('TEC', time '19:30', time '20:30', 'robson'),
  ('O1T', time '09:00', time '11:30', 'jessica'),
  ('O1Q', time '09:00', time '10:00', 'jessica')
) v(rotina_id, inicio, prazo, responsavel)
where not exists (select 1 from rotina_janelas j where j.rotina_id = v.rotina_id and j.inicio = v.inicio);

insert into rotina_itens (id, rotina_id, ordem, texto, foto, critico) values
  ('ABR.i1', 'ABR', 1, 'Ar-condicionados da recepção, área de corte e VIX do lavatório funcionando', false, true),
  ('ABR.i2', 'ABR', 2, 'Todas as luzes ligadas, incluindo as amarelas do lavatório', false, false),
  ('ABR.i3', 'ABR', 3, 'Limpeza da área interna', false, false),
  ('ABR.i4', 'ABR', 4, 'Limpeza dos banheiros', true, false),
  ('ABR.i5', 'ABR', 5, 'Sala de Spa organizada', true, false),
  ('ABR.i6', 'ABR', 6, 'Café coado passado', false, false),
  ('ABR.i7', 'ABR', 7, 'Playlists da recepção e do lavatório tocando', false, false),
  ('ABR.i8', 'ABR', 8, 'TV do Lounge na ESPN (Disney+)', false, false),
  ('BIN.i1', 'BIN', 1, 'Chegada às 08:50', false, true),
  ('BIN.i2', 'BIN', 2, 'Grades retiradas', false, false),
  ('BIN.i3', 'BIN', 3, 'Bancada organizada', false, false),
  ('BIN.i4', 'BIN', 4, 'Ajuda à atendente na conferência da abertura (se não houver cliente)', false, false),
  ('REC.i1', 'REC', 1, 'Respostas do WhatsApp e Direct iniciadas às 09:00', false, true),
  ('REC.i2', 'REC', 2, 'Lista de chegada dos barbeiros atualizada', false, false),
  ('REC.i3', 'REC', 3, 'Confirmações de 1 hora antes programadas para a manhã', false, false),
  ('PLA.i1', 'PLA', 1, 'Plantas aguadas', false, false),
  ('GRD.i1', 'GRD', 1, 'Gradis limpos', false, false),
  ('GRD.i2', 'GRD', 2, 'Produtos da vitrine limpos e alinhados', false, false),
  ('BIF.i1', 'BIF', 1, 'Chegada às 10:50', false, true),
  ('BIF.i2', 'BIF', 2, 'Bancada organizada', false, false),
  ('BIF.i3', 'BIF', 3, 'Chegada avisada à recepção para a lista de chegada', false, false),
  ('AMB.i1', 'AMB', 1, 'Banheiros conferidos: papel, sabonete, lixo e piso', false, false),
  ('AMB.i2', 'AMB', 2, 'Sala de Spa limpa e organizada', false, false),
  ('AMB.i3', 'AMB', 3, 'Lounge organizado e bandejas limpas', false, false),
  ('AMB.i4', 'AMB', 4, 'Copa organizada', false, false),
  ('GOU.i1', 'GOU', 1, 'VIX da área gourmet ligado e conferido', false, false),
  ('RON.i1', 'RON', 1, 'Cliente vem primeiro: ninguém esperando sem atendimento', false, false),
  ('RON.i2', 'RON', 2, 'Sorriso e gentileza no balcão, na cadeira e no lavatório', false, false),
  ('RON.i3', 'RON', 3, 'Benefícios oferecidos e servidos na bandeja', false, false),
  ('RON.i4', 'RON', 4, 'Todo corte terminando no lavatório', false, false),
  ('RON.i5', 'RON', 5, 'Head Spa oferecido no lavatório', false, false),
  ('RON.i6', 'RON', 6, 'Agenda em dia, com preferência de barbeiro perguntada', false, false),
  ('RON.i7', 'RON', 7, 'Regra dos 15 minutos respeitada', false, false),
  ('RON.i8', 'RON', 8, 'Nenhuma comanda aberta de cliente que já saiu', false, false),
  ('RON.i9', 'RON', 9, 'Bancadas organizadas', false, false),
  ('RON.i10', 'RON', 10, 'Postura: foco no cliente, sem conversa paralela, sem gritar', false, false),
  ('INF.i1', 'INF', 1, 'Bancada infantil limpa e organizada', false, false),
  ('FEC.i1', 'FEC', 1, 'Todas as comandas fechadas', false, true),
  ('FEC.i2', 'FEC', 2, 'Relatório da maquineta emitido', false, false),
  ('FEC.i3', 'FEC', 3, 'Vias de pagamento grampeadas', true, false),
  ('FEC.i4', 'FEC', 4, 'Comandas conferidas com o relatório da maquineta', false, true),
  ('FEC.i5', 'FEC', 5, 'Copa limpa e organizada', false, false),
  ('FEC.i6', 'FEC', 6, 'Lavatório limpo e organizado', false, false),
  ('FEC.i7', 'FEC', 7, 'Salão limpo e organizado', false, false),
  ('FEC.i8', 'FEC', 8, 'Cafeteira limpa e pronta para a manhã', false, false),
  ('FEC.i9', 'FEC', 9, 'Banheiros conferidos', false, false),
  ('BFE.i1', 'BFE', 1, 'Bancada limpa e organizada', true, false),
  ('GRA.i1', 'GRA', 1, 'Grades fechadas', false, false),
  ('GRB.i1', 'GRB', 1, 'Grades fechadas', false, false),
  ('GES.i1', 'GES', 1, 'Reunião feita com Victor e Robson', false, false),
  ('GES.i2', 'GES', 2, 'Combinados registrados', false, false),
  ('ALI.i1', 'ALI', 1, 'Reunião feita no horário', false, false),
  ('ALI.i2', 'ALI', 2, 'Presença registrada', false, false),
  ('ALI.i3', 'ALI', 3, 'Combinados registrados', false, false),
  ('TEC.i1', 'TEC', 1, 'Reunião feita', false, false),
  ('TEC.i2', 'TEC', 2, 'Presença dos barbeiros registrada', false, false),
  ('TEC.i3', 'TEC', 3, 'Técnica do dia registrada', false, false),
  ('O1T.i1', 'O1T', 1, 'Breno', false, false),
  ('O1T.i2', 'O1T', 2, 'Magda', false, false),
  ('O1T.i3', 'O1T', 3, 'Daniel', false, false),
  ('O1T.i4', 'O1T', 4, 'Heberth', false, false),
  ('O1T.i5', 'O1T', 5, 'Suellen', false, false),
  ('O1Q.i1', 'O1Q', 1, 'Durval', false, false),
  ('O1Q.i2', 'O1Q', 2, 'Jessica, com a sociedade', false, false)
on conflict (id) do nothing;

insert into lembretes (hora, texto)
select v.* from (values
  (time '09:00', 'Conferir se as respostas do WhatsApp e do Direct começaram'),
  (time '12:00', 'Almoço da Magda: cobrir o balcão do Lounge até 13h'),
  (time '14:00', 'Almoço da Suellen: cobrir o sofá da recepção até 15h'),
  (time '19:30', 'Conferir comandas abertas antes do fechamento')
) v(hora, texto)
where not exists (select 1 from lembretes l where l.texto = v.texto);

insert into regras (id) values (1) on conflict (id) do nothing;
