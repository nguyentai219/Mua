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
- **Chế độ quản trị (từ v1.1)**: nếu ai đó nhập đúng **Mã quản trị** (mật khẩu quản trị của app máy chủ) vào ô "Mã khách hàng", họ sẽ xem được **toàn bộ** người bán chứ không chỉ 1 người. Vì vậy Mã quản trị càng cần được giữ kín hơn Mã khách hàng thông thường.

## Triển khai

Upload các file trong thư mục này lên GitHub Pages tại đường dẫn:
```
nguyentai219.github.io/XemSoKhachHang/
```
(Nếu dùng tên thư mục khác, cần sửa lại đường dẫn tuyệt đối trong `sw.js` và `manifest.json` cho khớp.)

## Lịch sử phiên bản

| Phiên bản | Ngày | Thay đổi |
|---|---|---|
| **v1.4** | 2026-07 | Bỏ hẳn cơ chế tải lại cả trang mỗi 10s (gây chớp màn hình khó chịu) — thay bằng **làm mới ngầm**: chỉ gọi lại dữ liệu Supabase và vẽ lại đúng màn đang xem, không điều hướng/reload nên không còn chớp hình. Thêm tuỳ chọn **bật/tắt tự động làm mới** và **chọn thời gian làm mới** (5s/10s/15s/30s/1 phút/5 phút) trong ⚙️ Cài đặt. Tối ưu hiển thị khi khách hàng là **người mua lại hàng** (đầu mối mua mủ từ vựa): tự phát hiện vai trò dựa trên có dữ liệu Bán mà không có Thu Mua, đổi "Lịch sử Thu Mua" thành "🚛 Lịch sử mua hàng từ vựa" dùng dữ liệu Bán, đổi nhãn tổng tiền phù hợp, tự ẩn Gửi sổ/Ứng tiền nếu không có dữ liệu. Đưa **Lịch sử chính** (Thu Mua hoặc Bán tuỳ vai trò) lên ngay dưới tên khách hàng, trước cả phần tổng quan |
| **v1.3** | 2026-07 | Sửa lỗi máy chỉ cho "Tạo lối tắt" chứ không cho "Cài đặt app" (thêm icon thật ra màn hình chính) — nguyên nhân do thiếu các thẻ meta PWA cho iOS (`apple-mobile-web-app-capable`, `apple-touch-icon` bổ sung...) mà app máy chủ đã có. Đã bổ sung đầy đủ thẻ meta giống app máy chủ, sửa `manifest.json` (bỏ purpose "maskable" gây xung đột, thêm icon apple-touch-icon vào danh sách icons, thêm categories/lang), và sửa `sw.js` dùng đường dẫn tự suy ra từ scope thay vì gán cứng tên thư mục — để không bị lệch nếu đổi tên thư mục khi deploy |
| **v1.2** | 2026-07 | Đổi icon app (icon-192.png, icon-512.png, apple-touch-icon.png) sang biểu tượng bắt tay + túi tiền, cắt tròn khít theo vòng tròn xanh đậm (bỏ viền trắng ngoài) |
| **v1.1** | 2026-07 | Gộp toàn bộ nút "Đăng xuất" và "Tra cứu mã khác" thành 1 menu ⚙️ Cài đặt (icon bánh răng ở góc trên, thay cho nút Đăng xuất cũ). Mã khách hàng đã nhập được **lưu lại**, không tự thoát khi tải lại trang — chỉ thoát khi chọn "Tra cứu mã khác" hoặc "Đăng xuất tài khoản đồng bộ" trong Cài đặt. Tự động tải lại trang mỗi 10 giây để lấy dữ liệu mới (bỏ qua nếu đang gõ dở ô nhập liệu). Đổi câu từ hướng tới vai trò **người bán mủ** (người dùng app này). Thêm **Chế độ quản trị**: nhập đúng Mã quản trị của app máy chủ vào ô Mã khách hàng sẽ vào màn hình có menu chọn bất kỳ người bán nào để xem toàn bộ ghi chép chi tiết (cần app máy chủ đồng bộ `admin_pw` — nâng cấp từ v1.a2) |
| **v1.0** | 2026-07 | Bản đầu tiên: đăng nhập Supabase (chung tài khoản với máy chủ), nhập Mã khách hàng để xem Lịch sử Thu Mua (ngày, KG, độ/loại, giá, thành tiền + tổng), Lịch sử Gửi sổ (ngày, KG, độ/loại, thành tiền, trạng thái chốt sổ + tổng chưa chốt), Lịch sử Ứng tiền (ngày, số tiền, nội dung, trạng thái chốt + tổng chưa chốt). Chỉ đọc dữ liệu, không có chức năng chỉnh sửa. PWA cài được ra màn hình chính, hoạt động Network-First để luôn lấy bản mới nhất. |
