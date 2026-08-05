#!/bin/zsh
set -euo pipefail

project_dir="/Users/draken/Downloads/shikshapul_entrance"
java_runtime="/Applications/ZAP.app/Contents/PlugIns/jre-jdk-17.0.17+10-jre/Contents/Home"
apk_signer="/opt/homebrew/share/android-commandlinetools/build-tools/36.0.0/apksigner"
apk_path="$project_dir/build/app/outputs/flutter-apk/app-release.apk"

cd "$project_dir"

if [[ ! -x "$java_runtime/bin/java" ]]; then
  print -u2 "Java 17 runtime not found: $java_runtime"
  exit 1
fi
if [[ ! -f "android/key.properties" ]]; then
  print -u2 "Signing configuration missing: android/key.properties"
  exit 1
fi
if [[ ! -x "$apk_signer" ]]; then
  print -u2 "Android apksigner not found: $apk_signer"
  exit 1
fi

export JAVA_HOME="$java_runtime"

flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --release

"$apk_signer" verify --verbose --print-certs "$apk_path"
shasum -a 256 "$apk_path" | tee "$apk_path.sha256"

print "\nVerified signed APK:"
print "$apk_path"
