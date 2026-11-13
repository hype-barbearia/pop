/* =========================================================
   Dados do protótipo
   POPs, equipe, escala, rodízios e reuniões vêm do documento
   "HYPE Cultura e POP" v1.0 (outubro de 2026).
   Os registros do dia (horários, ocorrências, números) são fictícios.
   ========================================================= */
const SEED_V = 8;
const ROLE = {socio:'Sócio', gerente:'Gerente', barbeiro:'Barbeiro', atendente:'Atendente'};
const AREAS = {
  cultura:'Inegociáveis', abertura:'Abertura', recepcao:'Recepção', agenda:'Agenda', atendimento:'Atendimento',
  barbeiros:'Barbeiros', vendas:'Preços e indicações', jornada:'Jornada do cliente', fechamento:'Fechamento', gestao:'Reuniões',
};

/* Cultura HYPE (complemento do POP) */
const CULTURA = {
  missao:'Oferecer a cada cliente uma experiência de cuidado, relaxamento e renovação, com atenção a cada detalhe, domínio técnico e soluções reais para o seu cabelo, barba e pele.',
  visao:'Ser a barbearia referência em qualidade e satisfação dos clientes na Zona Norte do Recife.',
  valores:[
    ['Cooperação', 'Jogamos juntos e cobrimos uns aos outros.', 'Sem cliente na cadeira? Olhe ao redor.'],
    ['Posicionamento', 'Somos autoridade no que fazemos.', 'Quem domina o assunto não precisa convencer: o cliente confia.'],
    ['Atenção', 'Fazemos o cliente se sentir cuidado.', 'Lembrar o nome de todos os clientes atendidos.'],
    ['Intenção', 'Todo atendimento resolve algo.', 'Não vendemos serviços. Resolvemos problemas.'],
  ],
};

/* Escala, rodízios e reuniões (POP, págs. 6 e 17) */
const ESCALA = {
  horario:'Segunda a sexta, 09h às 20h. Sábado, 09h às 18h, e todos os barbeiros chegam às 08:50.',
  posicoes:'Posição padrão: Magda no balcão do Lounge, Suellen no sofá da recepção.',
  turnos:[['breno','Abertura · 08:50','Quarta'], ['daniel','Abertura · 08:50','Quarta'], ['durval','Fechamento · 10:50','Terça'], ['heberth','Fechamento · 10:50','Terça'],
    ['robson','Sem horário fixo, em geral da abertura ao fechamento','Segunda'], ['magda','Abertura · almoço 12h às 13h','A definir'], ['suellen','Fechamento · almoço 14h às 15h','A definir']],
  rodizios:[['Retirada das grades, 08:50','Diário','Barbeiros presentes'], ['Fechamento das grades','Seg · Qua · Sex','Durval e Heberth'], ['Fechamento das grades','Ter · Qui · Sáb','Breno e Daniel'],
    ['Limpeza da bancada infantil','Diário','Barbeiros, em revezamento (escala por dia a definir)'], ['Aguar as plantas','Seg · Qui','Atendentes, em revezamento (escala por dia a definir)'], ['Limpeza dos gradis e produtos','Seg · Qua · Sex','Atendentes, alternando (escala por dia a definir)'],
    ['Reunião de técnicas','Seg · quinzenal','Robson']],
  reunioes:[['Segunda','14:00 às 15:00','Gestão','Semanal'], ['Segunda','19:00 às 19:30','Alinhamento semanal','Semanal'], ['Segunda','19:30 às 20:30','Técnicas com Robson','Quinzenal: 19/10, 02/11, 16/11, 30/11 e 14/12'],
    ['Terça','09:00 às 11:30','One-on-ones de 30 min: Breno 09:00, Magda 09:30, Daniel 10:00, Heberth 10:30, Suellen 11:00','Semanal. A definir: terça é a folga do Heberth'],
    ['Quarta','09:00 às 10:00','One-on-ones de 30 min: Durval 09:00, Jessica 09:30','Semanal']],
};

function seed(){
  const people = [
    {id:'socios',  name:'Victor',  role:'socio',     label:'Sócio majoritário · liderança estratégica', hue:30},
    {id:'jessica', name:'Jessica', role:'gerente',   label:'Gerente · líder da gerência',  hue:40,  turno:'agenda, recepção e rotina'},
    {id:'robson',  name:'Robson',  role:'barbeiro',  label:'Sócio técnico · barbeiro', socio:true, hue:28, turno:'sem horário fixo', folga:1},
    {id:'breno',   name:'Breno',   role:'barbeiro',  label:'Barbeiro de abertura',      hue:345, turno:'abertura, 08:50', folga:3},
    {id:'daniel',  name:'Daniel',  role:'barbeiro',  label:'Barbeiro de abertura',      hue:145, turno:'abertura, 08:50', folga:3},
    {id:'durval',  name:'Durval',  role:'barbeiro',  label:'Barbeiro de fechamento',    hue:205, turno:'fechamento, 10:50', folga:2},
    {id:'heberth', name:'Heberth', role:'barbeiro',  label:'Barbeiro de fechamento',    hue:262, turno:'fechamento, 10:50', folga:2},
    {id:'magda',   name:'Magda',   role:'atendente', label:'Atendente de abertura',     hue:320, turno:'abertura, 08:30'},
    {id:'suellen', name:'Suellen', role:'atendente', label:'Atendente de fechamento',   hue:180, turno:'fechamento, até 20:00'},
  ];

  /* ---------- POPs (texto do documento HYPE v1.0) ---------- */
  const P = o => ({version:1, updated:'out/2026', approved:'Jessica e Victor', materials:[], quality:[], errors:[], reads:{}, ...o,
    steps:o.steps.map(s => typeof s === 'string' ? {t:s} : {t:s[0], crit:true})});
  const pops = [
    P({id:'POP-00', title:'Os 10 inegociáveis HYPE', area:'cultura', roles:['todos'], who:'Todos, todos os dias', owner:'Jessica', freq:'Sempre',
      objective:'Se você lembrar de apenas uma página do POP, que seja esta. É o que a gerência acompanha de perto.',
      steps:[['O cliente vem primeiro: ao chegar um cliente, qualquer outra tarefa para.'], ['Sorriso e gentileza em todo contato: balcão, cadeira, lavatório e WhatsApp.'],
        ['Benefícios sempre oferecidos: café coado, expresso, cappuccino, água e água com gás, servidos na bandeja.'], ['Todo corte termina no lavatório: o barbeiro direciona e a atendente lava o cabelo.'],
        ['Head Spa para 100%: oferecido a todo cliente que vai ao lavatório e realizado sempre que aceito.'], ['Confirmou, agendou: horário confirmado entra na agenda na hora, com preferência de barbeiro perguntada.'],
        ['Regra dos 15 minutos: encaixe só se o próximo esperar até 15 min. Atraso acima de 15 min perde o horário.'], ['Comanda fechada na saída: nenhum cliente sai com comanda aberta.'],
        ['Pontualidade e casa pronta: barbeiros de abertura às 08:50, barbeiros de fechamento às 10:50, sábado todos às 08:50. Bancada limpa antes de sair.'],
        ['Postura profissional: foco total no cliente da cadeira, sem conversas paralelas, sem temas polêmicos ou promíscuos, sem falar mal da equipe. Nunca gritar.']]}),
    P({id:'POP-01', title:'Abertura', area:'abertura', roles:['atendente','barbeiro'], who:'Atendente de abertura (Magda) e barbeiros de abertura', owner:'Jessica', freq:'Diário, 08:30 às 09:00',
      objective:'A primeira impressão do dia é construída antes do primeiro cliente entrar.',
      steps:['08:30: conferir o funcionamento dos ar-condicionados da recepção, da área de corte e do VIX do lavatório.', 'Conferir se todas as luzes estão ligadas, incluindo as luzes amarelas do lavatório.',
        'Fazer a limpeza da barbearia: área interna e banheiros.', 'Passar o café coado.', 'Garantir que as playlists da recepção e do lavatório estejam tocando.',
        '08:50: barbeiros de abertura chegam e todos os barbeiros presentes retiram as grades.', 'Os barbeiros de abertura ajudam a atendente na organização e conferência da abertura, exceto se já houver cliente para atender.',
        '10:50: chegada dos barbeiros de fechamento. Aos sábados, todos chegam às 08:50.', '11:30: ligar e conferir o VIX da área gourmet.']}),
    P({id:'POP-02', title:'Recepção', area:'recepcao', roles:['gerente','atendente'], who:'Gerente e atendentes', owner:'Jessica', freq:'Todo o expediente',
      objective:'Gerente e atendentes são a voz da HYPE no WhatsApp, no Direct e no balcão.',
      steps:[['Sempre fechar a comanda na saída do cliente. Comanda aberta é atendimento inacabado e erro de caixa no fim do dia.'], 'Começar a responder todos os clientes às 09:00 (atendente de abertura).',
        'Sempre responder o primeiro contato se identificando.', 'Atenção focal ao WhatsApp e ao Direct durante a recepção.', 'Fazer o plano dos clientes.', 'Confirmar o agendamento com o cliente pelo WhatsApp 1 hora antes do atendimento.'],
      quality:['Exemplo de primeiro contato: "Olá! Aqui é a Jessica, da HYPE Barbearia. Como posso te ajudar hoje?"']}),
    P({id:'POP-03', title:'Agenda', area:'agenda', roles:['gerente','atendente'], who:'Gerente e atendentes', owner:'Jessica', freq:'Todo o expediente',
      objective:'A agenda é o coração da operação. Cada minuto mal controlado vira espera para alguém.',
      steps:['Manter a lista de horário de chegada dos barbeiros: ela define a fila de atendimentos.', ['Horário pedido e confirmado entra na agenda imediatamente. Tem prioridade sobre qualquer outra tarefa.'],
        'Sempre perguntar se o cliente tem preferência de barbeiro.', ['Encaixe só se o próximo cliente esperar no máximo 15 minutos. Avaliar o cliente em atendimento, o próximo agendado e a capacidade técnica do barbeiro.'],
        ['Cliente com mais de 15 minutos de atraso perde o horário: aguarda o próximo encaixe disponível ou reagenda.'], 'Todo encaixe é comunicado obrigatoriamente ao barbeiro e à recepção.',
        'Se a resposta for não em qualquer etapa do encaixe, oferecer o próximo horário livre ou outro barbeiro disponível.'],
      quality:['Comunique o atraso com gentileza: a regra existe para respeitar quem chegou no horário.']}),
    P({id:'POP-04', title:'Atendimento: atendentes', area:'atendimento', roles:['atendente'], who:'Magda e Suellen', owner:'Jessica', freq:'A cada cliente e durante o expediente',
      objective:'O cliente sente a HYPE nos detalhes: o sorriso, a bandeja, o café no ponto, o Head Spa oferecido no momento certo.',
      steps:[['O cliente vem antes de tudo. Ao chegar um cliente, pare qualquer outra tarefa para atendê-lo.'], 'Atender sempre com sorriso no rosto e gentileza.',
        'Oferecer todos os benefícios: café coado, expresso, cappuccino, água e água com gás. Servir sempre com a bandeja.', 'Lavar o cabelo do cliente após todo serviço de corte e acabamento.',
        ['Oferecer o Head Spa a todos os clientes que forem ao lavatório: 15 min (R$ 39,90) ou 30 min (R$ 66,90).'], 'Dominar a tabela de preços dos produtos e serviços.',
        'Conferir com regularidade a sala de Spa (organização e limpeza) e os banheiros.', 'Aguar as plantas às segundas e quintas, em revezamento.', 'Limpar gradis e produtos às segundas, quartas e sextas, alternando.',
        'TV do Lounge, por padrão, nos jogos da ESPN pelo Disney+.', 'Posição padrão: Magda no balcão do Lounge, Suellen no sofá da recepção.', 'Cumprir o horário de almoço: abertura 12h às 13h, fechamento 14h às 15h.'],
      quality:['Como oferecer o Head Spa: "Já que você está aqui, gostaria de aproveitar e fazer o nosso Head Spa? É um momento de relaxamento para fechar o atendimento."'],
      errors:['Pressionar o cliente para aceitar o Head Spa.']}),
    P({id:'POP-05', title:'Barbeiros: posturas gerais', area:'barbeiros', roles:['barbeiro'], who:'Breno, Daniel, Durval, Heberth e Robson', owner:'Robson (técnica) e Jessica (rotina)', freq:'Todo o expediente',
      objective:'O barbeiro HYPE é um artista técnico: entrega estética com estratégia e cuida do espaço como cuida do corte.',
      steps:['Manter a bancada organizada ao longo do dia.', ['Limpar e organizar a bancada antes de sair da barbearia.'], 'Limpar a bancada infantil diariamente, em revezamento.',
        'Atenção constante ao cumprimento dos horários dos clientes.', 'Dominar a tabela de preços dos produtos e serviços.', 'Cliente chegou? Barbeiros sentados no sofá cedem o lugar imediatamente.',
        'Sem atendimento e com atendentes sobrecarregadas: se prontificar a servir água, água com gás e café coado.', 'Videogame: seu cliente chegou, encerre na hora. Mais de um cliente no Lounge sem jogar, encerre na hora.',
        'Participar da reunião de técnicas com o Robson, a cada duas semanas, na segunda às 19h30.'],
      quality:['O cliente recebe o mesmo resultado com qualquer barbeiro da casa.']}),
    P({id:'POP-06', title:'Barbeiros: padrão de atendimento', area:'barbeiros', roles:['barbeiro'], who:'Breno, Daniel, Durval, Heberth e Robson', owner:'Robson', freq:'A cada cliente',
      objective:'Da cadeira ao lavatório, cada atendimento deixa no cliente a sensação de cuidado, relaxamento e renovação.',
      steps:['Atender com sorriso no rosto e gentileza.', 'Assim que o cliente sentar, perguntar se aceita um benefício: café, expresso, cappuccino, água ou água com gás.',
        'Manter um diálogo amistoso e interativo, sempre que o cliente estiver disposto.', ['Ao finalizar todo corte e acabamento, direcionar o cliente ao lavatório.'],
        'Conduzir a conversa, de forma intencional, para entender alguma dor ou necessidade e apresentar a solução com produtos e serviços extras.',
        ['1:1, foco total no cliente da cadeira. Conversa só com quem está sendo atendido, exceto quando o próprio cliente puxa conversa com outra pessoa.']],
      errors:['Puxar ou alimentar temas polêmicos.', 'Estimular temas promíscuos, mesmo que o cliente puxe o assunto.', 'Conversas paralelas durante o atendimento.', 'Falar mal da equipe para os clientes.',
        'Discutir problemas operacionais na frente dos clientes.', 'Gritar na barbearia.']}),
    P({id:'POP-07', title:'Preços, Linha HYPE Premium e indicações', area:'vendas', roles:['todos'], who:'Gerente, atendentes e barbeiros', owner:'Robson (produtos) e Jessica', freq:'Sempre',
      objective:'Saber o preço na ponta da língua e o que cada ativo faz transmite segurança e autoridade. Vender na HYPE é resolver um problema do cliente.',
      steps:['Perceba: observe pele, couro cabeludo, cabelo, barba, nariz, orelha e sobrancelha.', 'Pergunte: descubra o que o cliente usa hoje e o que o incomoda.',
        'Explique: conte o que o ativo faz. Ex.: "a niacinamida do Balm equilibra a pele e reduz a vermelhidão".', 'Mostre: use o produto na finalização e deixe o cliente sentir o resultado.',
        ['Ofereça: indique o produto ou o combo, sem insistir depois de um "não".']],
      errors:['Empurrar produto ou serviço.', 'Indicar sem ter percebido uma necessidade.'],
      tables:[
        ['Cabelo', [['Corte','R$ 75,00'], ['Acabamento','R$ 30,00'], ['Penteado','R$ 29,90'], ['Hidratação capilar','R$ 30,00'], ['Botox capilar','a partir de R$ 129,90'], ['Camuflagem dos fios brancos','R$ 50,00'], ['Reflexo (luzes)','a partir de R$ 129,90'], ['Platinado (Nevou)','a partir de R$ 199,90']]],
        ['Barba', [['Barba','R$ 55,00'], ['Barboterapia','R$ 79,90'], ['Hidratação de barba','R$ 30,00'], ['Pigmentação de barba','R$ 35,00']]],
        ['Detalhes e combos', [['Sobrancelha','R$ 29,90'], ['Depilação nariz','R$ 29,90'], ['Depilação orelha','R$ 34,90'], ['Cabelo e barba','R$ 110,00'], ['Depilação nariz e orelha','R$ 50,00']]],
        ['Head Spa', [['Head Spa 15 min','R$ 39,90'], ['Head Spa 30 min','R$ 66,90']]],
        ['Linha HYPE Premium', [['Shampoo Ice Cold · 290 ml','R$ 89,00'], ['Condicionador Ice Cold · 290 ml','R$ 89,90'], ['Leave-in · 140 ml','R$ 99,90'], ['Cera Matte · 100 g','R$ 110,00'], ['Cera Brilho · 100 g','R$ 110,00'], ['Cera em Pó · 5 g','R$ 110,00'], ['Balm para barba · 140 ml','R$ 99,90'], ['Óleo para barba · 30 ml','R$ 89,90'], ['Combo Shampoo + Condicionador Ice','R$ 160,00'], ['Combo Balm + Óleo','R$ 169,00']]],
      ],
      guide:[['Fios aparentes no nariz ou na orelha','Depilação nariz / orelha · combo (R$ 50,00)',''], ['Sobrancelha sem forma ou com fios longos','Sobrancelha',''], ['Fios brancos que incomodam','Camuflagem dos fios brancos',''],
        ['Barba ressecada, áspera ou rebelde','Hidratação de barba · Barboterapia','Combo Balm + Óleo'], ['Barba opaca, sem brilho ou com frizz','Hidratação de barba','Óleo para barba'], ['Falhas ou pouca densidade na barba','Pigmentação de barba','Balm para barba'],
        ['Couro cabeludo oleoso ou com caspa','Head Spa','Shampoo Ice Cold'], ['Fios fracos ou com queda','Hidratação capilar · Head Spa','Shampoo Ice Cold'], ['Cabelo ressecado, opaco ou com frizz','Hidratação capilar · Botox capilar','Leave-in · Combo Shampoo + Condicionador'],
        ['Cliente tenso, cansado ou estressado','Head Spa 15 ou 30 min','Shampoo + Condicionador Ice'], ['Corte e barba no mesmo dia','Combo cabelo e barba (economia de R$ 20,00)','Cera do estilo do corte'],
        ['Evento, foto ou ocasião especial','Penteado','Cera Brilho · Matte · Pó'], ['Vontade de mudar o visual','Reflexo (luzes) · Platinado (Nevou)','Leave-in · Condicionador Ice']]}),
    P({id:'POP-08', title:'A jornada do cliente', area:'jornada', roles:['todos'], who:'Toda a equipe, cada etapa com um responsável', owner:'Jessica', freq:'A cada cliente',
      objective:'O cliente sai sentindo cuidado, relaxamento e renovação, e com vontade de voltar.',
      steps:['Primeiro contato (recepção): responder se identificando, perguntar preferência de barbeiro, colocar na agenda na hora.', 'Chegada (atendentes e barbeiros): sorriso e boas-vindas, barbeiros cedem o sofá, videogame encerrado se necessário.',
        'Espera no Lounge (atendentes): oferecer todos os benefícios, servidos na bandeja, TV na ESPN.', 'Na cadeira (barbeiro): perguntar se aceita um benefício, diálogo amistoso, entender necessidades.',
        'Fim do corte (barbeiro): direcionar ao lavatório após todo corte e acabamento.', 'Lavatório (atendentes): lavar o cabelo, oferecer o Head Spa a 100%, realizar se aceito.',
        'Produtos e extras (barbeiro e recepção): indicar o serviço extra ou o produto HYPE Premium para a necessidade identificada.', ['Saída (recepção): fechar a comanda e despedida cordial.']]}),
    P({id:'POP-09', title:'Fechamento', area:'fechamento', roles:['atendente','barbeiro'], who:'Atendente de fechamento (Suellen) e barbeiros', owner:'Jessica', freq:'Diário, 20:00 (sábado 18:00)',
      objective:'Fechar bem é abrir bem no dia seguinte. A casa fica pronta para a equipe da manhã.',
      steps:['Deixar copa, lavatório e salão limpos e organizados.', 'Deixar a cafeteira limpa e pronta para passar o café pela manhã.', 'Emitir o relatório da maquineta e grampear as vias de pagamento do dia.',
        'Barbeiros: limpar e organizar a própria bancada antes de sair.', 'Fechar as grades conforme a escala: seg, qua e sex Durval e Heberth; ter, qui e sáb Breno e Daniel.',
        ['Antes de apagar as luzes, todas as comandas do dia fechadas e conferidas com o relatório da maquineta.']]}),
    P({id:'POP-10', title:'Rotina de reuniões', area:'gestao', roles:['todos'], who:'Toda a equipe', owner:'Jessica e Robson', freq:'Semanal e quinzenal',
      objective:'Encontros fixos para alinhar a equipe, padronizar a técnica e acompanhar cada profissional de perto.',
      steps:['Segunda, 14:00 às 15:00: reunião de gestão (semanal).', 'Segunda, 19:00 às 19:30: alinhamento semanal.', 'Segunda, 19:30 às 20:30: técnicas com Robson, a cada duas semanas, logo após o alinhamento.',
        'Terça: one-on-ones de 30 min com Breno 09:00, Magda 09:30, Daniel 10:00, Heberth 10:30 e Suellen 11:00.', 'Quarta: one-on-ones com Durval 09:00 e Jessica 09:30.',
        ['Pontualidade como em qualquer atendimento.']],
      quality:['Próximas reuniões de técnicas: 16/11, 30/11 e 14/12.']}),
  ];
  // Termo de ciência: todos assinaram a v1.0
  pops.forEach(p => people.filter(x => x.role !== 'socio' && (p.roles.includes('todos') || p.roles.includes(x.role))).forEach(x => p.reads[x.id] = p.version));

  /* ---------- Rotinas (checklists do POP, pág. 18, e rodízios) ---------- */
  const R = o => ({kind:'check', verify:false, days:[1,2,3,4,5,6], ...o,
    items:o.items.map((x, k) => ({id:'i' + (k + 1), t:x[0], photo:/foto/.test(x[1] || ''), crit:/crit/.test(x[1] || '')}))});
  const tpls = [
    R({id:'ABR', title:'Abertura da barbearia', pop:'POP-01', verify:true, slots:[['08:30','09:00','magda']], items:[
      ['Ar-condicionados da recepção, área de corte e VIX do lavatório funcionando','crit'], ['Todas as luzes ligadas, incluindo as amarelas do lavatório'], ['Limpeza da área interna'],
      ['Limpeza dos banheiros','foto'], ['Sala de Spa organizada','foto'], ['Café coado passado'], ['Playlists da recepção e do lavatório tocando'], ['TV do Lounge na ESPN (Disney+)']]}),
    R({id:'BIN', title:'Chegada e grades', pop:'POP-01', verify:true, each:['breno','daniel'], slots:[['08:50','09:00']], items:[
      ['Chegada às 08:50','crit'], ['Grades retiradas'], ['Bancada organizada'], ['Ajuda à atendente na conferência da abertura (se não houver cliente)']]}),
    R({id:'REC', title:'Recepção aberta', pop:'POP-02', verify:true, slots:[['09:00','09:15','magda']], items:[
      ['Respostas do WhatsApp e Direct iniciadas às 09:00','crit'], ['Lista de chegada dos barbeiros atualizada'], ['Confirmações de 1 hora antes programadas para a manhã']]}),
    R({id:'PLA', title:'Plantas aguadas', pop:'POP-04', verify:true, days:[1,4], slots:[['10:00','12:00','magda']], items:[['Plantas aguadas']]}),
    R({id:'GRD', title:'Gradis e produtos limpos', pop:'POP-04', verify:true, days:[1,3,5], slots:[['10:00','12:00','suellen']], items:[['Gradis limpos'], ['Produtos da vitrine limpos e alinhados']]}),
    R({id:'BIF', title:'Chegada do fechamento', pop:'POP-01', verify:true, each:['durval','heberth'], slots:[['10:50','11:00']], items:[
      ['Chegada às 10:50','crit'], ['Bancada organizada'], ['Chegada avisada à recepção para a lista de chegada']]}),
    R({id:'AMB', title:'Conferência de banheiros e Spa', pop:'POP-04', verify:true, slots:[['11:00','11:30','magda'],['14:00','14:30','magda'],['17:00','17:30','suellen']], items:[
      ['Banheiros conferidos: papel, sabonete, lixo e piso'], ['Sala de Spa limpa e organizada'], ['Lounge organizado e bandejas limpas'], ['Copa organizada']]}),
    R({id:'GOU', title:'VIX da área gourmet', pop:'POP-01', slots:[['11:30','11:45','magda']], items:[['VIX da área gourmet ligado e conferido']]}),
    R({id:'RON', title:'Ronda dos inegociáveis', pop:'POP-00', kind:'ronda', slots:[['12:00','12:30','jessica'],['16:30','17:00','jessica']], items:[
      ['Cliente vem primeiro: ninguém esperando sem atendimento'], ['Sorriso e gentileza no balcão, na cadeira e no lavatório'], ['Benefícios oferecidos e servidos na bandeja'],
      ['Todo corte terminando no lavatório'], ['Head Spa oferecido no lavatório'], ['Agenda em dia, com preferência de barbeiro perguntada'], ['Regra dos 15 minutos respeitada'],
      ['Nenhuma comanda aberta de cliente que já saiu'], ['Bancadas organizadas'], ['Postura: foco no cliente, sem conversa paralela, sem gritar']]}),
    R({id:'INF', title:'Bancada infantil', pop:'POP-05', verify:true, slots:[['19:40','20:10','daniel']], items:[['Bancada infantil limpa e organizada']]}),
    R({id:'FEC', title:'Fechamento da barbearia', pop:'POP-09', verify:true, slots:[['20:00','20:30','suellen']], items:[
      ['Todas as comandas fechadas','crit'], ['Relatório da maquineta emitido'], ['Vias de pagamento grampeadas','foto'], ['Comandas conferidas com o relatório da maquineta','crit'],
      ['Copa limpa e organizada'], ['Lavatório limpo e organizado'], ['Salão limpo e organizado'], ['Cafeteira limpa e pronta para a manhã'], ['Banheiros conferidos']]}),
    R({id:'BFE', title:'Bancada limpa antes de sair', pop:'POP-05', verify:true, each:'barbeiro', slots:[['20:00','20:20']], items:[['Bancada limpa e organizada','foto']]}),
    R({id:'GRA', title:'Grades fechadas', pop:'POP-09', verify:true, days:[2,4,6], also:['daniel'], slots:[['20:20','20:40','breno']], items:[['Grades fechadas']]}),
    R({id:'GRB', title:'Grades fechadas', pop:'POP-09', verify:true, days:[1,3,5], also:['heberth'], slots:[['20:20','20:40','durval']], items:[['Grades fechadas']]}),
    R({id:'GES', title:'Reunião de gestão', pop:'POP-10', days:[1], slots:[['14:00','15:00','jessica']], items:[['Reunião feita com Victor e Robson'], ['Combinados registrados']]}),
    R({id:'ALI', title:'Alinhamento semanal', pop:'POP-10', days:[1], slots:[['19:00','19:30','jessica']], items:[['Reunião feita no horário'], ['Presença registrada'], ['Combinados registrados']]}),
    R({id:'TEC', title:'Reunião de técnicas', pop:'POP-10', days:[1], every2:true, slots:[['19:30','20:30','robson']], items:[['Reunião feita'], ['Presença dos barbeiros registrada'], ['Técnica do dia registrada']]}),
    R({id:'O1T', title:'One-on-ones de terça', pop:'POP-10', days:[2], slots:[['09:00','11:30','jessica']], items:[['Breno'], ['Magda'], ['Daniel'], ['Heberth'], ['Suellen']]}),
    R({id:'O1Q', title:'One-on-ones de quarta', pop:'POP-10', days:[3], slots:[['09:00','10:00','jessica']], items:[['Durval'], ['Jessica, com a sociedade']]}),
  ];
  const T = Object.fromEntries(tpls.map(t => [t.id, t]));

  /* ---------- Execuções de hoje (quinta-feira) ---------- */
  const WD_TODAY = 4, inst = [], I = {};
  const iid = (t, who, start) => `${t}.${who}.${start.replace(':', '')}`;
  tpls.forEach(t => {
    if (!t.days.includes(WD_TODAY)) return;
    t.slots.forEach(([start, due, who]) => {
      const list = Array.isArray(t.each) ? t.each : t.each ? people.filter(p => p.role === t.each && p.folga !== WD_TODAY).map(p => p.id) : [who];
      list.forEach(w => { const i = {id:iid(t.id, w, start), tpl:t.id, who:w, start:toMin(start), due:toMin(due), checks:{}, doneAt:null, ver:null}; inst.push(i); I[i.id] = i; });
    });
  });
  // O dia inteiro está gravado; a hora simulada mostra só o que aconteceu até agora
  const fill = (id, a, b, o = {}) => {
    const i = I[id], t = T[i.tpl], n = t.items.length, A = toMin(a), B = toMin(b);
    t.items.forEach((it, k) => {
      const at = Math.round(A + (B - A) * (n === 1 ? 1 : k / (n - 1))), nc = o.skip?.[k];
      i.checks[it.id] = nc ? {at, ok:false, note:nc} : {at, ok:true, photo:it.photo || undefined};
    });
    i.doneAt = B;
    if (o.ver) i.ver = {at:toMin(o.ver[0]), res:o.ver[1], note:o.ver[2] || '', by:'jessica'};
  };
  fill('ABR.magda.0830', '08:31', '08:56', {ver:['09:10','ok']});
  fill('BIN.breno.0850', '08:50', '08:56', {ver:['09:12','ok']});
  fill('BIN.daniel.0850', '08:49', '08:55', {ver:['09:12','ok']});
  fill('REC.magda.0900', '09:00', '09:08', {ver:['09:15','ok']});
  fill('PLA.magda.1000', '10:20', '10:20', {ver:['11:00','ok']});
  fill('BIF.durval.1050', '10:48', '10:55', {ver:['11:05','ok']});
  fill('BIF.heberth.1050', '10:50', '10:58', {ver:['11:05','ok']});
  fill('AMB.magda.1100', '11:05', '11:12', {ver:['11:30','ok']});
  fill('GOU.magda.1130', '11:31', '11:31');
  fill('RON.jessica.1200', '12:04', '12:20', {skip:{4:'Dois clientes saíram do lavatório sem a oferta do Head Spa.'}});
  fill('AMB.magda.1400', '14:46', '14:55', {ver:['15:10','ressalva','Feita depois do prazo. Às 14h a recepção fica com uma atendente só, por causa do almoço das 14h às 15h; vale avaliar a janela.']});
  fill('RON.jessica.1630', '16:35', '16:52');
  fill('AMB.suellen.1700', '17:04', '17:12', {ver:['17:30','ok']});
  fill('INF.daniel.1940', '19:45', '19:47', {ver:['20:35','ok']});
  fill('FEC.suellen.2000', '20:02', '20:28', {ver:['20:40','ok']});
  [['robson','20:03','20:05'], ['breno','20:01','20:02'], ['daniel','20:06','20:07'], ['durval','20:10','20:11'], ['heberth','20:12','20:14']].forEach(([w, a, b]) => fill(`BFE.${w}.2000`, a, b, {ver:['20:38','ok']}));
  fill('GRA.breno.2020', '20:31', '20:32', {ver:['20:42','ok']});

  /* ---------- Ocorrências (exemplos, sem nomes) ---------- */
  const occ = [
    {id:'OC-121', at:toMin('12:14'), who:null, src:'Ronda da gerente', inst:'RON.jessica.1200', title:'Head Spa não oferecido no lavatório', pop:'POP-04',
      desc:'Dois clientes saíram do lavatório sem a oferta do Head Spa. Inegociável 05: Head Spa para 100%.', status:'tratamento',
      actions:[{at:toMin('12:25'), by:'jessica', t:'Reforcei com as atendentes a frase do POP-04 para oferecer o Head Spa no lavatório.'}]},
    {id:'OC-120', at:toMin('10:40'), who:null, src:'Recepção', title:'Cliente chegou com 20 minutos de atraso', pop:'POP-03',
      desc:'Aplicada a regra dos 15 minutos. O cliente preferiu aguardar o próximo encaixe.', status:'resolvida',
      actions:[{at:toMin('10:45'), by:'jessica', t:'Encaixe confirmado para 11:30 com o Durval, avisado ao barbeiro e à recepção.'}]},
    {id:'OC-119', day:'11/11', at:0, who:null, src:'Cliente', title:'Cliente esperou sem aviso de atraso', pop:'POP-03',
      desc:'O atraso da agenda não foi avisado na recepção.', status:'resolvida',
      actions:[{at:0, day:'11/11', by:'jessica', t:'Pedi desculpas e ofereci um benefício. Levei para o alinhamento de segunda.'}]},
    {id:'OC-118', day:'09/11', at:0, who:null, src:'Fechamento', title:'Comanda aberta no fim do dia', pop:'POP-02',
      desc:'Uma comanda não batia com o relatório da maquineta.', status:'resolvida',
      actions:[{at:0, day:'09/11', by:'jessica', t:'Comanda localizada e fechada. Conferência das comandas passou a ser item crítico do fechamento.'}]},
  ];
  const occ30 = {};

  /* ---------- Lembretes ---------- */
  const reminders = [
    {id:'R1', at:'09:00', text:'Conferir se as respostas do WhatsApp e do Direct começaram', on:true},
    {id:'R2', at:'12:00', text:'Almoço da Magda: cobrir o balcão do Lounge até 13h', on:true},
    {id:'R3', at:'14:00', text:'Almoço da Suellen: cobrir o sofá da recepção até 15h', on:true},
    {id:'R4', at:'19:30', text:'Conferir comandas abertas antes do fechamento', on:true},
  ];
  const remDone = {R1:toMin('09:04'), R2:toMin('12:01'), R3:toMin('14:02'), R4:toMin('19:34')};
  const nudges = [{inst:'AMB.magda.1400', at:toMin('14:42'), by:'jessica'}];
  const rules = {antes:10, escalar:30, conferir:30, meta:.9, rondas:true, resumo:'21:00', fotos:true};

  return {v:SEED_V, people, pops, tpls, inst, occ, occ30, reminders, remDone, nudges, rules,
    ui:{user:'socios', now:toMin('14:40'), view:'painel', tab:'hoje', open:null, pop:null, nao:null, f:{}, more:false, selP:null}};
}
