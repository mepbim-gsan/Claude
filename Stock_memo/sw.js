// キャッシュを使用しない Service Worker
// 既存キャッシュをすべて削除してネットワーク優先で動作

self.addEventListener('install', () => {
  self.skipWaiting();
});

self.addEventListener('activate', e => {
  e.waitUntil(
    caches.keys().then(keys => Promise.all(keys.map(k => caches.delete(k))))
  );
  self.clients.claim();
});

// fetch ハンドラーなし → ブラウザのデフォルト動作（ネットワーク取得）
