package io.github.nguyentai219.sokhachhang;

import android.app.Activity;
import android.content.ComponentName;
import android.content.Intent;
import android.content.ServiceConnection;
import android.content.pm.ResolveInfo;
import android.net.Uri;
import android.os.Binder;
import android.os.Bundle;
import android.os.Handler;
import android.os.IBinder;
import android.os.Looper;
import android.os.Parcel;
import java.util.List;

/**
 * Mở app web Sổ Khách Hàng (GitHub Pages, repo Mua) dưới dạng Trusted Web Activity (TWA) trong Chrome.
 * APK chỉ là "vỏ": mọi nội dung và cập nhật đều đến từ trang web, nên app tự lên bản mới mỗi khi
 * trang web được cập nhật mà không cần cài lại APK.
 *
 * Không dùng thư viện AndroidX: tự nói chuyện với dịch vụ Custom Tabs của trình duyệt qua Binder
 * (giao thức ICustomTabsService.aidl khai báo id tường minh warmup = 1, newSession = 2; mã Binder thật
 * = FIRST_CALL_TRANSACTION + id, tức 2 và 3).
 */
public class LauncherActivity extends Activity {
    private static final String URL = "https://nguyentai219.github.io/Mua/index.html";
    private static final String ACTION_CT_SERVICE = "android.support.customtabs.action.CustomTabsService";
    private static final String DESC_SERVICE = "android.support.customtabs.ICustomTabsService";
    private static final String DESC_CALLBACK = "android.support.customtabs.ICustomTabsCallback";
    private static final String EXTRA_SESSION = "android.support.customtabs.extra.SESSION";
    private static final String EXTRA_TWA = "android.support.customtabs.extra.LAUNCH_AS_TRUSTED_WEB_ACTIVITY";
    private static final String EXTRA_TOOLBAR_COLOR = "android.support.customtabs.extra.TOOLBAR_COLOR";
    private static final String EXTRA_NAVBAR_COLOR = "androidx.browser.customtabs.extra.NAVIGATION_BAR_COLOR";
    private static final int TX_WARMUP = IBinder.FIRST_CALL_TRANSACTION + 1;
    private static final int TX_NEW_SESSION = IBinder.FIRST_CALL_TRANSACTION + 2;
    private static final int THEME_COLOR = 0xFF1A472A;
    // Trình duyệt ưu tiên (đều hỗ trợ TWA); không có thì lấy trình duyệt đầu tiên hỗ trợ Custom Tabs
    private static final String[] PREFERRED = {
        "com.android.chrome", "com.chrome.beta", "com.chrome.dev", "com.microsoft.emmx",
        "com.sec.android.app.sbrowser", "org.mozilla.firefox"
    };

    /** Callback rỗng gửi cho trình duyệt; mọi lệnh gọi về đều trả lời "không có dữ liệu". */
    private static class Callback extends Binder {
        Callback() { attachInterface(null, DESC_CALLBACK); }
        @Override
        protected boolean onTransact(int code, Parcel data, Parcel reply, int flags) {
            if (code == INTERFACE_TRANSACTION) {
                if (reply != null) reply.writeString(DESC_CALLBACK);
                return true;
            }
            if (reply != null) { reply.writeNoException(); reply.writeInt(0); }
            return true;
        }
    }

    private final Callback callback = new Callback();
    private final Handler handler = new Handler(Looper.getMainLooper());
    private ServiceConnection connection;
    private boolean launched;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        if (savedInstanceState != null && savedInstanceState.getBoolean("launched")) {
            launched = true;
            return;
        }
        final String pkg = pickBrowser();
        if (pkg == null) { launchPlain(); return; }
        connection = new ServiceConnection() {
            @Override public void onServiceConnected(ComponentName name, IBinder service) {
                call(service, TX_WARMUP, false);
                call(service, TX_NEW_SESSION, true);
                launchTwa(pkg);
            }
            @Override public void onServiceDisconnected(ComponentName name) { }
        };
        Intent si = new Intent(ACTION_CT_SERVICE).setPackage(pkg);
        boolean bound = false;
        try { bound = bindService(si, connection, BIND_AUTO_CREATE); } catch (Exception e) { }
        if (!bound) { connection = null; launchTwa(pkg); return; }
        // Trình duyệt không phản hồi kịp → vẫn mở (ở dạng Custom Tab có thanh địa chỉ)
        handler.postDelayed(new Runnable() { public void run() { launchTwa(pkg); } }, 4000);
    }

    private String pickBrowser() {
        List<ResolveInfo> list = getPackageManager().queryIntentServices(new Intent(ACTION_CT_SERVICE), 0);
        if (list == null || list.isEmpty()) return null;
        for (String p : PREFERRED) {
            for (ResolveInfo ri : list) if (ri.serviceInfo != null && p.equals(ri.serviceInfo.packageName)) return p;
        }
        return list.get(0).serviceInfo.packageName;
    }

    private void call(IBinder service, int code, boolean withCallback) {
        Parcel data = Parcel.obtain(), reply = Parcel.obtain();
        try {
            data.writeInterfaceToken(DESC_SERVICE);
            if (withCallback) data.writeStrongBinder(callback); else data.writeLong(0);
            service.transact(code, data, reply, 0);
            reply.readException();
        } catch (Exception e) {
        } finally { data.recycle(); reply.recycle(); }
    }

    private void launchTwa(String pkg) {
        if (launched || isFinishing()) return;
        launched = true;
        handler.removeCallbacksAndMessages(null);
        Intent i = new Intent(Intent.ACTION_VIEW, Uri.parse(URL));
        i.setPackage(pkg);
        Bundle b = new Bundle();
        b.putBinder(EXTRA_SESSION, callback);
        i.putExtras(b);
        i.putExtra(EXTRA_TWA, true);
        i.putExtra(EXTRA_TOOLBAR_COLOR, THEME_COLOR);
        i.putExtra(EXTRA_NAVBAR_COLOR, THEME_COLOR);
        try { startActivity(i); } catch (Exception e) { launched = false; launchPlain(); }
    }

    private void launchPlain() {
        launched = true;
        try { startActivity(new Intent(Intent.ACTION_VIEW, Uri.parse(URL))); } catch (Exception e) { }
        finish();
    }

    @Override
    protected void onSaveInstanceState(Bundle out) {
        super.onSaveInstanceState(out);
        out.putBoolean("launched", launched);
    }

    // Người dùng bấm Back thoát khỏi app web → quay về đây → đóng luôn (không để lại màn chờ trống)
    @Override
    protected void onRestart() {
        super.onRestart();
        if (launched) finish();
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        handler.removeCallbacksAndMessages(null);
        if (connection != null) { try { unbindService(connection); } catch (Exception e) { } connection = null; }
    }
}
