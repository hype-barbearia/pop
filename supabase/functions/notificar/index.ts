// Hype POP · envia as notificações pendentes para os celulares (Web Push)
// e, com ?tarefa=limpeza, apaga fotos com mais de 90 dias.
// Chamado pelo agendamento do banco (pg_cron + pg_net) com o cabeçalho x-hype-segredo.
import webpush from "npm:web-push@3.6.7";
import { createClient } from "npm:@supabase/supabase-js@2.45.4";

Deno.serve(async (req) => {
  const sb = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
  const cfg = async (k: string) => (await sb.rpc("config_privada", { k })).data as string;
  if (req.headers.get("x-hype-segredo") !== await cfg("segredo_cron")) return new Response("negado", { status: 401 });

  const tarefa = new URL(req.url).searchParams.get("tarefa") || "enviar";

  if (tarefa === "limpeza") {
    const { data } = await sb.rpc("fotos_antigas", { dias: 90 });
    const nomes = (data || []).map((r: { name: string }) => r.name);
    if (nomes.length) await sb.storage.from("fotos").remove(nomes);
    return Response.json({ apagadas: nomes.length });
  }

  webpush.setVapidDetails(await cfg("vapid_contato"), await cfg("vapid_publica"), await cfg("vapid_privada"));
  const desde = new Date(Date.now() - 2 * 3600e3).toISOString();
  const { data: pend } = await sb.from("notificacoes").select("*").is("enviado_em", null).gte("criado_em", desde).order("criado_em").limit(200);
  let enviadas = 0;
  for (const n of pend || []) {
    const { data: subs } = await sb.from("push_inscricoes").select("*").eq("pessoa_id", n.pessoa_id);
    for (const s of subs || []) {
      try {
        await webpush.sendNotification({ endpoint: s.endpoint, keys: { p256dh: s.p256dh, auth: s.auth } },
          JSON.stringify({ title: n.titulo, body: n.corpo || "", url: n.url || "./", tag: n.chave }), { TTL: 3600 });
        enviadas++;
      } catch (e) {
        const code = (e as { statusCode?: number }).statusCode;
        if (code === 404 || code === 410) await sb.from("push_inscricoes").delete().eq("endpoint", s.endpoint);
      }
    }
    await sb.from("notificacoes").update({ enviado_em: new Date().toISOString() }).eq("id", n.id);
  }
  return Response.json({ pendentes: (pend || []).length, enviadas });
});
