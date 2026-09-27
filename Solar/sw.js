// 旧URL（/Solar/）のService Workerを解除するためのスタブ
self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', e => {
  e.waitUntil(self.registration.unregister());
});
