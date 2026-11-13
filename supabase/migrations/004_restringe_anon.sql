-- Hype POP · 004 · funções auxiliares só para quem está logado
revoke execute on function eu(), sou_membro(), sou_socio(), sou_gestor(), pode_ver_execucao(uuid), pode_executar(uuid), hoje() from public, anon;
grant execute on function eu(), sou_membro(), sou_socio(), sou_gestor(), pode_ver_execucao(uuid), pode_executar(uuid), hoje() to authenticated;
