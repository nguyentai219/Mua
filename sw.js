const CACHE = 'xem-so-kh-v1.8';
// Dùng scope của chính service worker để tự suy ra đường dẫn — không phụ thuộc tên thư mục deploy cụ thể
const BASE = self.registration.scope; // VD: https://nguyentai219.github.io/XemSoKhachHang/
const FILES = [
  BASE,
  BASE + 'index.html',
  BASE + 'manifest.json',
  BASE + 'icon-192.png',
  BASE + 'icon-512.png',
  BASE + 'apple-touch-icon.png',
  BASE + 'splash.png'
];

self.addEventListener('install', e => {
  e.waitUntil(caches.open(CACHE).then(c => c.addAll(FILES)).catch(()=>{}));
  self.skipWaiting();
});

self.addEventListener('activate', e => {
  e.waitUntil(
    caches.keys().then(ks =>
      Promise.all(ks.filter(k => k !== CACHE).map(k => caches.delete(k)))
    )
  );
  self.clients.claim();
});

self.addEventListener('fetch', e => {
  const url = new URL(e.request.url);
  const isHTML = e.request.destination === 'document' || url.pathname.endsWith('.html') || url.pathname.endsWith('/');

  if (isHTML) {
    // HTML: Network First — luôn lấy bản mới nhất, cache làm dự phòng offline
    e.respondWith(
      fetch(e.request)
        .then(response => {
          const clone = response.clone();
          caches.open(CACHE).then(c => c.put(e.request, clone));
          return response;
        })
        .catch(() => caches.match(e.request))
    );
  } else {
    // Tài nguyên tĩnh (icon, manifest): Cache First — nhanh hơn
    e.respondWith(
      caches.match(e.request).then(r => r || fetch(e.request).catch(() => caches.match(BASE + 'index.html')))
    );
  }
});
