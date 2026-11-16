/* Hype POP · service worker só para notificações (sem cache, para nunca prender uma versão antiga) */
self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', e => e.waitUntil(self.clients.claim()));
self.addEventListener('push', e => {
  let d = {}; try { d = e.data.json(); } catch (x) { d = {title:'Hype POP', body:e.data && e.data.text()}; }
  e.waitUntil(self.registration.showNotification(d.title || 'Hype POP', {body:d.body || '', tag:d.tag, icon:'icon-180.png', badge:'icon-180.png', data:{url:d.url || './'}}));
});
self.addEventListener('notificationclick', e => {
  e.notification.close();
  e.waitUntil((async () => {
    const all = await self.clients.matchAll({type:'window', includeUncontrolled:true});
    for (const c of all) { if ('focus' in c) return c.focus(); }
    return self.clients.openWindow(e.notification.data.url || './');
  })());
});
