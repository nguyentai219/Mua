const CACHE = 'xem-so-kh-v1.33';
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
  // Tải với cache:'reload' (bỏ qua bộ nhớ đệm HTTP 10 phút của GitHub Pages) để bản mới không bị nhét
  // nhầm index.html CŨ vào cache. Từng file riêng lẻ: 1 file lỗi không làm hỏng cả lượt cài.
  e.waitUntil(
    caches.open(CACHE).then(c => Promise.all(FILES.map(u =>
      fetch(new Request(u, { cache: 'reload' })).then(r => { if (r && r.ok) return c.put(u, r); }).catch(() => {})
    ))).catch(() => {})
  );
  self.skipWaiting();
});

self.addEventListener('activate', e => {
  // Chỉ xoá cache CŨ CỦA APP NÀY (tiền tố riêng) — bộ nhớ cache dùng chung cả tên miền
  // nguyentai219.github.io, xoá hết sẽ làm mất bản offline của các app khác (Mủ Cao Su, Quản Lý Heo...).
  e.waitUntil(
    caches.keys().then(ks =>
      Promise.all(ks.filter(k => (k.startsWith('xem-so-kh-')) && k !== CACHE).map(k => caches.delete(k)))
    ).then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', e => {
  const url = new URL(e.request.url);
  // CHỈ xử lý request GET cùng gốc với app. Request ra ngoài (Supabase: đăng nhập, tải sổ...) để trình duyệt
  // tự xử lý — trước đây request Supabase lỡ lỗi mạng bị trả nhầm trang index.html đã lưu thay vì báo lỗi.
  if (url.origin !== self.location.origin || e.request.method !== 'GET') return;
  if (!url.href.startsWith(BASE)) return; // chỉ tài nguyên của app này, không đụng app khác cùng tên miền

  const isHTML = e.request.mode === 'navigate' || e.request.destination === 'document' || url.pathname.endsWith('.html') || url.pathname.endsWith('/');
  // Trang, icon, manifest: lấy mạng trước (cache:'no-cache' = luôn hỏi lại máy chủ, không dùng bản 10 phút
  // trong bộ nhớ đệm HTTP) để bản mới hiện ngay và Chrome so icon đúng với máy chủ (không hiện popup "cập
  // nhật biểu tượng"); mất mạng thì dùng bản đã lưu.
  const networkFirst = isHTML || url.pathname.endsWith('.png') || url.pathname.endsWith('manifest.json');
  if (networkFirst) {
    const daLuu = () => caches.match(e.request).then(r => r || (isHTML
      ? caches.match(BASE + 'index.html', { ignoreSearch: true })
      : undefined));
    const mang = fetch(new Request(e.request.url, { cache: 'no-cache' }))
      .then(response => {
        if (response && response.ok) {
          const clone = response.clone();
          caches.open(CACHE).then(c => c.put(e.request, clone)).catch(() => {});
        }
        return response;
      });
    // Mạng chập chờn (đang tải mãi không xong) → sau 4 giây dùng bản đã lưu để app mở ra ngay, thay vì đứng
    // mãi ở màn hình logo khởi động; bản mới vẫn tiếp tục tải ngầm và dùng ở lần mở sau.
    const hetGio = new Promise(res => setTimeout(res, 4000)).then(daLuu).then(r => r || mang);
    e.respondWith(
      Promise.race([mang, hetGio])
        .catch(() => daLuu().then(r => r || Response.error()))
    );
  } else {
    e.respondWith(
      caches.match(e.request).then(r => r || fetch(e.request))
    );
  }
});
