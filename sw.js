const CACHE = 'mu-cao-su-v1.6.1';
const FILES = ['/Mucaosu/','/Mucaosu/index.html','/Mucaosu/manifest.json','/Mucaosu/icon-192.png','/Mucaosu/icon-512.png','/Mucaosu/apple-touch-icon.png','/Mucaosu/logo.png','/Mucaosu/splash.png'];

self.addEventListener('install', e => {
  e.waitUntil(caches.open(CACHE).then(c => c.addAll(FILES)).catch(()=>{}));
  self.skipWaiting(); // kích hoạt SW mới ngay lập tức
});

self.addEventListener('activate', e => {
  // Xóa tất cả cache cũ
  e.waitUntil(
    caches.keys().then(ks =>
      Promise.all(ks.filter(k => k !== CACHE).map(k => caches.delete(k)))
    )
  );
  self.clients.claim(); // chiếm quyền kiểm soát tất cả tab ngay
});

self.addEventListener('fetch', e => {
  const url = new URL(e.request.url);
  const isHTML = e.request.destination === 'document' || url.pathname.endsWith('.html') || url.pathname.endsWith('/');

  if (isHTML) {
    // HTML: Network First — luôn lấy bản mới nhất, cache làm dự phòng offline
    e.respondWith(
      fetch(e.request)
        .then(response => {
          // Cập nhật cache với bản mới
          const clone = response.clone();
          caches.open(CACHE).then(c => c.put(e.request, clone));
          return response;
        })
        .catch(() => caches.match(e.request))
    );
  } else {
    // Tài nguyên tĩnh (icon, manifest): Cache First — nhanh hơn
    e.respondWith(
      caches.match(e.request).then(r => r || fetch(e.request).catch(() => caches.match('/Mucaosu/index.html')))
    );
  }
});
