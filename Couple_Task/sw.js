// couple-tasks sw.js - network-only（キャッシュなし）
// Firebase依存のため常に最新を取得する

self.addEventListener('install', e => {
  self.skipWaiting();
});

self.addEventListener('activate', e => {
  // 既存キャッシュをすべて削除
  e.waitUntil(
    caches.keys()
      .then(keys => Promise.all(keys.map(k => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', e => {
  // GETリクエストのみ処理（POST等はそのまま通す）
  if (e.request.method !== 'GET') return;
  e.respondWith(fetch(e.request));
});
