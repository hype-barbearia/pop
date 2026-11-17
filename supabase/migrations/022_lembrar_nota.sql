-- Hype POP · 022 · lembrete de nota fiscal enviado pela gestão ao barbeiro parceiro
create or replace function lembrar_nf(pessoa text, periodo date) returns void
language plpgsql security definer set search_path = public as $$
declare v numeric;
begin
  if not sou_gestor() then raise exception 'Só a gerente ou os sócios mandam o lembrete.'; end if;
  select nv.valor into v from nf_valores nv where nv.pessoa_id = pessoa and nv.periodo = lembrar_nf.periodo;
  if v is null then raise exception 'Informe o valor antes de lembrar.'; end if;
  -- no máximo um lembrete por hora para a mesma pessoa e quinzena
  perform notificar(pessoa, 'nflem:' || pessoa || ':' || periodo || ':' || to_char(now(), 'YYYYMMDDHH24'),
    'Lembrete: nota fiscal de ' || nf_rotulo(periodo),
    'Valor: R$ ' || brl(v) || '. Emita a NFS-e para a Hype e envie em Perfil até ' || to_char(nf_prazo(periodo), 'DD/MM') || '.');
  perform disparar_envio('enviar');
end $$;
revoke execute on function lembrar_nf(text, date) from public, anon;
grant execute on function lembrar_nf(text, date) to authenticated;
