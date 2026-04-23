// キャッシュなし・常にネットワークから取得
// PWAとしてインストール可能にするためだけのService Worker
self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', () => self.clients.claim());
self.addEventListener('fetch', e => {
  if (e.request.url.includes('googleapis.com') ||
      e.request.url.includes('firebase')) {
    return;
  }
  e.respondWith(fetch(e.request));
});
