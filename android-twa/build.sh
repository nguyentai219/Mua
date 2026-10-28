#!/bin/sh
# Đóng gói APK (TWA) bằng công cụ Android từ kho Ubuntu:
#   apt-get install android-sdk-platform-23 aapt apksigner zipalign dalvik-exchange
# Cách dùng: KEYSTORE=/đường/dẫn/mucaosu.keystore KS_PASS=... ./build.sh
set -e
cd "$(dirname "$0")"
SDK_JAR=/usr/lib/android-sdk/platforms/android-23/android.jar
: "${KEYSTORE:?Cần KEYSTORE}" "${KS_PASS:?Cần KS_PASS}"
rm -rf build && mkdir -p build/gen build/classes
aapt package -f -m -J build/gen -M AndroidManifest.xml -S res -I "$SDK_JAR" -F build/app.unsigned.apk
javac -nowarn -source 8 -target 8 -bootclasspath "$SDK_JAR" -d build/classes \
  $(find src build/gen -name '*.java')
dalvik-exchange --dex --output=build/classes.dex build/classes
(cd build && aapt add app.unsigned.apk classes.dex >/dev/null)
zipalign -f 4 build/app.unsigned.apk build/app.aligned.apk
apksigner sign --ks "$KEYSTORE" --ks-pass "pass:$KS_PASS" --out build/SoKhachHang.apk build/app.aligned.apk
apksigner verify --print-certs build/SoKhachHang.apk
