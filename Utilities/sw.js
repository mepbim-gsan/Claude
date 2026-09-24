const CACHE_NAME = 'utilities-dashboard-v1';
const ENTRY_HTML = './utilities-dashboard.html';

// ネットワーク優先で取得するリソース（更新頻度が高いもの）
const NETWORK_FIRST_PATTERNS = [
  /firebasejs/,
  /googleapis\.com/,
  /gstatic\.com/,
  /jsdelivr\.net/,
];

// プリキャッシュ対象（アイコン類のみ）
const PRECACHE_ASSETS = [
  './icons/icon-192.png',
  './icons/icon-512.png',
];

self.addEventListener('install', e => {
  e.waitUntil(
    caches.open(CACHE_NAME)
      .then(c => c.addAll(PRECACHE_ASSETS))
      .then(() => self.skipWaiting())  // 待機なしで即時アクティブ化
  );
});

self.addEventListener('activate', e => {
  e.waitUntil(
    caches.keys()
      .then(keys => Promise.all(
        keys.filter(k => k !== CACHE_NAME).map(k => caches.delete(k))
      ))
      .then(() => self.clients.claim())  // 既存タブを即時制御下に
  );
});

self.addEventListener('fetch', e => {
  const url = e.request.url;

  // アイコン → キャッシュファースト
  if (url.includes('/icons/')) {
    e.respondWith(
      caches.match(e.request).then(cached => {
        if (cached) return cached;
        return fetch(e.request).then(res => {
          if (!res || res.status !== 200 || res.type === 'opaque') return res;
          const clone = res.clone();
          caches.open(CACHE_NAME).then(c => c.put(e.request, clone));
          return res;
        });
      })
    );
    return;
  }

  // HTMLエントリ・manifest・Firebase/Chart.js CDN → ネットワーク優先
  const isNetworkFirst =
    url.endsWith(ENTRY_HTML) ||
    url.includes('manifest.json') ||
    NETWORK_FIRST_PATTERNS.some(p => p.test(url));

  if (isNetworkFirst) {
    e.respondWith(
      fetch(e.request)
        .then(res => {
          // 成功したらキャッシュにも保存（次回オフライン時のフォールバック用）
          if (res && res.status === 200 && res.type !== 'opaque') {
            const clone = res.clone();
            caches.open(CACHE_NAME).then(c => c.put(e.request, clone));
          }
          return res;
        })
        .catch(() => caches.match(e.request))  // オフライン時はキャッシュにフォールバック
    );
    return;
  }

  // その他 → キャッシュファースト
  e.respondWith(
    caches.match(e.request).then(cached => {
      if (cached) return cached;
      return fetch(e.request).then(res => {
        if (!res || res.status !== 200 || res.type === 'opaque') return res;
        const clone = res.clone();
        caches.open(CACHE_NAME).then(c => c.put(e.request, clone));
        return res;
      });
    })
  );
});
