# ShikshaPul

Offline-first Flutter app for Android and iOS that prepares students for Nepal
engineering and medical entrance examinations. It includes course-specific
exam practice, weakness analytics, animated concept visualizers, and an
on-device Qwen GGUF tutor.

The product distinguishes generated practice, syllabus-based practice,
expert-authored questions, and licensed past papers in the UI. Generated
content is never presented as an official past paper.

The in-app Trusted Resources library links current official syllabi and clearly
separated institutional model sets. Commercial EPCM material is not copied;
students may use an authorized copy alongside the app and record mistakes in
the Mistake Notebook.

## Requirements

- Flutter 3.44 or newer (Dart 3.3+)
- Android: SDK 36, Java 17, and Android 8.0/API 26 or newer
- iOS: Xcode 16 or newer and iOS 13 or newer
- A physical ARM64 Android or iOS device for native Qwen inference
- About 1 GB free storage on first AI Tutor launch

## Run

```sh
flutter pub get
flutter analyze
flutter test
flutter run
```

Build an installable development APK with `flutter build apk --debug`. The
output is `build/app/outputs/flutter-apk/app-debug.apk`.

Release builds require a private keystore. Create `android/key.properties`
with `storePassword`, `keyPassword`, `keyAlias`, and `storeFile`. The build now
fails instead of producing an invalid unsigned release APK when signing is not
configured.

For Google Play, publish a signed Android App Bundle with
`flutter build appbundle --release`. The bundled offline model makes the
download large; validate the compressed size in Play Console and move it to
Play Asset Delivery if the final evaluated model pushes the base module beyond
the current store limit or materially hurts install conversion.

Build an unsigned iOS archive with `flutter build ios --release --no-codesign`.
For App Store or device distribution, open `ios/Runner.xcworkspace` in Xcode,
select your Apple development team, and create an Archive.

## Notes

- Questions are locally generated syllabus-aligned practice material, not
  reproduced or certified official past papers.
- Scholarship/readiness indicators are personal study signals, not official
  ranks, admissions decisions, or scholarship guarantees.
- The AI model runs locally on supported Android and iOS devices. If native
  inference cannot start, the tutor automatically uses its offline syllabus
  knowledge engine.
- Android extracts the large GGUF through a native background stream and checks
  its SHA-256, avoiding a 400+ MB Dart-memory spike during first launch.
- Configure a private Android release keystore and Apple signing team before
  publishing. Release artifacts are intentionally not signed with debug keys.
- Exam blueprints carry a source version and verification state. KU KUCAT 2026
  is linked to the official KU source; other profiles remain visibly
  provisional until their current official documents are recorded.
- The subject-adapter workflow is documented in `training/README.md`. It
  rejects unlicensed or non-expert-verified records and creates independent
  Physics, Chemistry, Mathematics, and Biology adapters.
- The bundled GGUF is currently a development artifact. Its provenance and
  evaluation gaps are explicit in `assets/models/model_manifest.json`; do not
  market it as exam-verified until every required field is completed.
- Strategy questions about passing, rank, scholarship, EPCM, or configuration
  use deterministic guidance instead of unconstrained model output. The app
  explicitly avoids outcome guarantees.
