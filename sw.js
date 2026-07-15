const CACHE = 'xem-so-kh-v1.0';
const FILES = ['/XemSoKhachHang/','/XemSoKhachHang/index.html','/XemSoKhachHang/manifest.json','/XemSoKhachHang/icon-192.png','/XemSoKhachHang/icon-512.png','/XemSoKhachHang/apple-touch-icon.png'];

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
      caches.match(e.request).then(r => r || fetch(e.request).catch(() => caches.match('/XemSoKhachHang/index.html')))
    );
  }
});
