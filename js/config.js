/* Projeto Supabase "Hype Barbearia". A chave publicável é pública por natureza:
   quem não está cadastrado não lê nada, por causa das regras de acesso (RLS) do banco. */
const HYPE_CONFIG = {
  url: 'https://fwecscsvfxocgjspdsis.supabase.co',
  key: 'sb_publishable_okZkjMGJDdClZtrjzA2Idw_BQxk99pv',
  vapid: 'BLdw3xoZrerkEqnH8v9c0s_lNvujnwwdjreQMh8awa2iZRKYhy9ydLbFiFN_M-tyFurEvLR697_zPhBn_l1u3o8',  // chave pública das notificações
  ambiente: 'producao',  // no site de teste, a publicação troca este arquivo por ambientes/teste/config.js
};

/* Ambiente de teste: faixa fixa na tela e "TESTE" no título, para ninguém confundir com o app real */
if (HYPE_CONFIG.ambiente === 'teste' && typeof document !== 'undefined' && document.documentElement) {
  document.documentElement.classList.add('amb-teste');
  document.title = 'TESTE · ' + document.title;
}
