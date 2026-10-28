-- ═══════════════════════════════════════════════════════════════════════════════════════════════
-- SỔ KHÁCH HÀNG — xem sổ bằng Mã KH + mật khẩu, KHÔNG cần đăng nhập Supabase trên máy khách
-- Chạy 1 lần trong Supabase → SQL Editor → New query → dán toàn bộ → Run. Chạy lại nhiều lần không sao.
--
-- • xem_so_khach(ma, mk): đúng Mã KH + mật khẩu xem sổ (app Mủ Cao Su cấp, lưu ở khoá 'kh_pw') → trả về
--   CHỈ sổ của đúng khách đó (Thu Mua, Bán, Gửi sổ, Ứng tiền, Chấm công, liên hệ, mốc chốt).
-- • xem_so_admin(email, mk): email tài khoản Supabase của chủ vựa + mật khẩu quản trị (khoá 'admin_pw')
--   → trả về sổ của TẤT CẢ khách của chủ vựa đó.
-- • Sai 5 lần liên tiếp → khoá mã/tài khoản đó 15 phút (chống dò mật khẩu).
-- Hàm chạy với quyền chủ (security definer) nên đọc được bảng mucaosu_data, nhưng chỉ trả ra đúng phần
-- được phép; máy khách không đọc trực tiếp được bảng nào.
-- ═══════════════════════════════════════════════════════════════════════════════════════════════

-- Đếm số lần nhập sai (không ai đọc trực tiếp được: bật RLS, không có policy)
create table if not exists public.so_kh_dang_nhap_sai (
  khoa      text primary key,
  so_lan    int not null default 0,
  khoa_den  timestamptz
);
alter table public.so_kh_dang_nhap_sai enable row level security;

-- Chuẩn hoá tên: bỏ khoảng trắng thừa, không phân biệt hoa/thường (giống normTen trong app)
create or replace function public._sokh_norm(t text) returns text
language sql immutable as $$
  select lower(regexp_replace(btrim(coalesce(t, '')), '\s+', ' ', 'g'))
$$;

-- Lấy 1 khoá dữ liệu (jsonb) của chủ vựa
create or replace function public._sokh_lay(p_uid uuid, p_key text) returns jsonb
language sql stable security definer set search_path = public as $$
  select m.data_value::jsonb from public.mucaosu_data m
  where m.user_id = p_uid and m.data_key = p_key
  limit 1
$$;

-- Lọc mảng giao dịch theo tên khách (p_ten null = lấy tất cả)
create or replace function public._sokh_loc(p_uid uuid, p_key text, p_ten text) returns jsonb
language sql stable security definer set search_path = public as $$
  select coalesce(jsonb_agg(e), '[]'::jsonb)
  from jsonb_array_elements(
    case when jsonb_typeof(public._sokh_lay(p_uid, p_key)) = 'array'
         then public._sokh_lay(p_uid, p_key) else '[]'::jsonb end
  ) e
  where p_ten is null or public._sokh_norm(e->>'ten') = public._sokh_norm(p_ten)
$$;

-- Ghi nhận 1 lần sai; trả về true nếu vừa bị khoá
create or replace function public._sokh_ghi_sai(p_khoa text) returns void
language plpgsql security definer set search_path = public as $$
begin
  insert into public.so_kh_dang_nhap_sai (khoa, so_lan, khoa_den) values (p_khoa, 1, null)
  on conflict (khoa) do update
    set so_lan = case when public.so_kh_dang_nhap_sai.khoa_den is not null
                       and public.so_kh_dang_nhap_sai.khoa_den <= now() then 1
                      else public.so_kh_dang_nhap_sai.so_lan + 1 end,
        khoa_den = case when public.so_kh_dang_nhap_sai.khoa_den is not null
                         and public.so_kh_dang_nhap_sai.khoa_den <= now() then null
                        else public.so_kh_dang_nhap_sai.khoa_den end;
  update public.so_kh_dang_nhap_sai set khoa_den = now() + interval '15 minutes', so_lan = 0
  where khoa = p_khoa and so_lan >= 5;
end $$;

-- Số phút còn bị khoá (0 = không khoá)
create or replace function public._sokh_con_khoa(p_khoa text) returns int
language sql stable security definer set search_path = public as $$
  select coalesce((
    select greatest(1, ceil(extract(epoch from (khoa_den - now())) / 60)::int)
    from public.so_kh_dang_nhap_sai where khoa = p_khoa and khoa_den is not null and khoa_den > now()
  ), 0)
$$;

-- ── KHÁCH HÀNG: Mã KH + mật khẩu ──
create or replace function public.xem_so_khach(p_ma text, p_mk text) returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  v_khoa text := 'kh:' || coalesce(btrim(p_ma), '');
  v_phut int;
  r record;
  v_uid uuid;
  v_ten text;
  v_info jsonb;
  v_chot text;
begin
  v_phut := public._sokh_con_khoa(v_khoa);
  if v_phut > 0 then return jsonb_build_object('loi', 'khoa', 'phut', v_phut); end if;

  -- Tìm chủ vựa + tên khách có Mã KH này, kiểm tra mật khẩu xem sổ (kh_pw khoá theo Mã KH)
  for r in
    select m.user_id, e.key as ten
    from public.mucaosu_data m,
         jsonb_each_text(case when jsonb_typeof(m.data_value::jsonb) = 'object' then m.data_value::jsonb else '{}'::jsonb end) e
    where m.data_key = 'kh_ids' and e.value = btrim(p_ma)
  loop
    if coalesce(public._sokh_lay(r.user_id, 'kh_pw') ->> btrim(p_ma), '') <> ''
       and public._sokh_lay(r.user_id, 'kh_pw') ->> btrim(p_ma) = btrim(coalesce(p_mk, '')) then
      v_uid := r.user_id; v_ten := r.ten; exit;
    end if;
  end loop;

  if v_uid is null then
    perform public._sokh_ghi_sai(v_khoa);
    return jsonb_build_object('loi', 'sai');
  end if;
  delete from public.so_kh_dang_nhap_sai where khoa = v_khoa;

  select e.value into v_info
  from jsonb_each(case when jsonb_typeof(public._sokh_lay(v_uid, 'kh_info')) = 'object' then public._sokh_lay(v_uid, 'kh_info') else '{}'::jsonb end) e
  where public._sokh_norm(e.key) = public._sokh_norm(v_ten) limit 1;
  select e.value into v_chot
  from jsonb_each_text(case when jsonb_typeof(public._sokh_lay(v_uid, 'mua_chot_moc')) = 'object' then public._sokh_lay(v_uid, 'mua_chot_moc') else '{}'::jsonb end) e
  where public._sokh_norm(e.key) = public._sokh_norm(v_ten) limit 1;

  return jsonb_build_object(
    'ten', v_ten, 'ma', btrim(p_ma),
    'mua', public._sokh_loc(v_uid, 'gd3_mua', v_ten),
    'ban', public._sokh_loc(v_uid, 'gd3_ban', v_ten),
    'sg',  public._sokh_loc(v_uid, 'sg3', v_ten),
    'su',  public._sokh_loc(v_uid, 'su_data', v_ten),
    'cc',  public._sokh_loc(v_uid, 'cc_data', v_ten),
    'kh_info', coalesce(v_info, '{}'::jsonb),
    'mua_chot', coalesce(v_chot, '')
  );
end $$;

-- ── CHỦ VỰA (quản trị): email tài khoản Supabase + mật khẩu quản trị ──
create or replace function public.xem_so_admin(p_email text, p_mk text) returns jsonb
language plpgsql security definer set search_path = public, auth as $$
declare
  v_khoa text := 'ad:' || lower(btrim(coalesce(p_email, '')));
  v_phut int;
  v_uid uuid;
  v_pw text;
begin
  v_phut := public._sokh_con_khoa(v_khoa);
  if v_phut > 0 then return jsonb_build_object('loi', 'khoa', 'phut', v_phut); end if;

  select u.id into v_uid from auth.users u where lower(u.email) = lower(btrim(p_email)) limit 1;
  if v_uid is not null then
    v_pw := coalesce(public._sokh_lay(v_uid, 'admin_pw') #>> '{}', '28082008');
  end if;
  if v_uid is null or v_pw is null or v_pw <> btrim(coalesce(p_mk, '')) then
    perform public._sokh_ghi_sai(v_khoa);
    return jsonb_build_object('loi', 'sai');
  end if;
  delete from public.so_kh_dang_nhap_sai where khoa = v_khoa;

  return jsonb_build_object(
    'admin', true,
    'mua', public._sokh_loc(v_uid, 'gd3_mua', null),
    'ban', public._sokh_loc(v_uid, 'gd3_ban', null),
    'sg',  public._sokh_loc(v_uid, 'sg3', null),
    'su',  public._sokh_loc(v_uid, 'su_data', null),
    'cc',  public._sokh_loc(v_uid, 'cc_data', null),
    'kh_ids',   coalesce(public._sokh_lay(v_uid, 'kh_ids'), '{}'::jsonb),
    'kh_info',  coalesce(public._sokh_lay(v_uid, 'kh_info'), '{}'::jsonb),
    'mua_chot', coalesce(public._sokh_lay(v_uid, 'mua_chot_moc'), '{}'::jsonb)
  );
end $$;

-- Quyền: chỉ 2 hàm xem_so_* được gọi từ app; các hàm phụ (_sokh_*) không ai gọi trực tiếp được
revoke all on function public._sokh_lay(uuid, text) from public, anon, authenticated;
revoke all on function public._sokh_loc(uuid, text, text) from public, anon, authenticated;
revoke all on function public._sokh_ghi_sai(text) from public, anon, authenticated;
revoke all on function public._sokh_con_khoa(text) from public, anon, authenticated;
revoke all on function public.xem_so_khach(text, text) from public;
revoke all on function public.xem_so_admin(text, text) from public;
grant execute on function public.xem_so_khach(text, text) to anon, authenticated;
grant execute on function public.xem_so_admin(text, text) to anon, authenticated;
