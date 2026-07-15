# Xem Sổ Khách Hàng (v1.0)

Ứng dụng đồng hành ("máy khách") của app **Mua Bán Mủ Cao Su**. Cài trên điện thoại của khách hàng bán mủ, cho phép họ tự tra cứu sổ **Thu Mua / Gửi sổ / Ứng tiền** của riêng mình — không xem được dữ liệu của khách hàng khác, và không xem được **Bán** (giao dịch bán cho vựa lớn, không liên quan tới khách hàng cá nhân).

## Cách hoạt động

1. **Máy chủ** (chủ vựa) dùng app "Mua Bán Mủ Cao Su", đăng nhập Supabase, ghi chép Mua/Bán/Gửi/Ứng như bình thường — dữ liệu tự động đồng bộ lên Supabase.
2. Trong app chính, vào **⚙️ Cài đặt → 📇 Mã khách hàng**, tìm tên khách hàng, bấm "Sao chép" để lấy **Mã KH** (5 ký tự, cố định, không đổi).
3. **Máy khách** (điện thoại khách hàng) cài app này, đăng nhập **CÙNG tài khoản Supabase** với máy chủ (chỉ cần làm 1 lần duy nhất trên máy đó — chủ vựa tự tay đăng nhập giúp khách hàng khi giao máy/cài đặt).
4. Từ đó về sau, khách hàng chỉ cần mở app, nhập **Mã KH** của mình để xem sổ — không cần đăng nhập lại, không cần biết mật khẩu tài khoản Supabase.

## Bảo mật — LƯU Ý QUAN TRỌNG

- App này dùng **chung 1 tài khoản Supabase** với máy chủ để đọc dữ liệu, sau đó **lọc theo Mã KH ngay trên máy khách hàng** (không có phân quyền phía server theo từng khách hàng).
- Nghĩa là: ai có **email + mật khẩu** của tài khoản Supabase đều có thể xem được **toàn bộ** dữ liệu (không riêng của 1 khách hàng), nếu họ tự đăng nhập trực tiếp bằng tài khoản đó thay vì dùng app này.
- Vì vậy: **chỉ chủ vựa mới nên biết email/mật khẩu Supabase**, tự tay đăng nhập vào máy khách hàng, và **không chia sẻ mật khẩu Supabase cho khách hàng** — họ chỉ cần Mã KH.
- Đây là giải pháp đơn giản, phù hợp quy mô nhỏ giữa các bên tin tưởng nhau. Nếu cần phân quyền chặt chẽ hơn (mỗi khách hàng chỉ được server cho phép xem đúng dữ liệu của mình, kể cả khi biết mật khẩu), cần nâng cấp lên cơ chế Row Level Security (RLS) theo khách hàng — phức tạp hơn, có thể làm ở phiên bản sau nếu cần.

## Triển khai

Upload các file trong thư mục này lên GitHub Pages tại đường dẫn:
```
nguyentai219.github.io/XemSoKhachHang/
```
(Nếu dùng tên thư mục khác, cần sửa lại đường dẫn tuyệt đối trong `sw.js` và `manifest.json` cho khớp.)

## Lịch sử phiên bản

| Phiên bản | Ngày | Thay đổi |
|---|---|---|
| **v1.0** | 2026-07 | Bản đầu tiên: đăng nhập Supabase (chung tài khoản với máy chủ), nhập Mã khách hàng để xem Lịch sử Thu Mua (ngày, KG, độ/loại, giá, thành tiền + tổng), Lịch sử Gửi sổ (ngày, KG, độ/loại, thành tiền, trạng thái chốt sổ + tổng chưa chốt), Lịch sử Ứng tiền (ngày, số tiền, nội dung, trạng thái chốt + tổng chưa chốt). Chỉ đọc dữ liệu, không có chức năng chỉnh sửa. PWA cài được ra màn hình chính, hoạt động Network-First để luôn lấy bản mới nhất. |
