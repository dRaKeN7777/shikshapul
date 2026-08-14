# ShikshaPul

Offline-first Flutter app for Android and iOS that prepares students for Nepal
engineering and medical entrance examinations. It includes course-specific
exam practice, weakness analytics, animated concept visualizers, and a
low-memory offline tutor. An on-device Qwen GGUF edition is optional on
supported higher-memory Android phones.

The product distinguishes generated practice, syllabus-based practice,
expert-authored questions, and licensed past papers in the UI. Generated
content is never presented as an official past paper.

The in-app Trusted Resources library links current official syllabi and clearly
separated institutional model sets. Commercial EPCM material is not copied;
students may use an authorized copy alongside the app and record mistakes in
the Mistake Notebook.

## Download for Android

The signed ShikshaPul v1.0.1 APK is available from the
[Nepal release page](https://github.com/dRaKeN7777/shikshapul/releases/tag/v1.0.1).
It supports Android 8.0/API 26 or newer and can be used fully offline after
installation. Google Play testing is also active for invited accounts while
the mandatory production-access testing period is completed.

## Requirements

- Flutter 3.44 or newer (Dart 3.3+)
- Android: SDK 36, Java 17, and Android 8.0/API 26 or newer
- iOS: Xcode 16 or newer and iOS 13 or newer
- A physical ARM64 Android device for the optional Full-AI edition
- Lite edition: no 412 MB model download or extraction
- Full-AI edition: about 1 GB free storage and at least 1.4 GB currently free RAM

## Run

```sh
flutter pub get
flutter analyze
flutter test
flutter run --flavor lite
```

Build the low-memory development APK with
`flutter build apk --debug --flavor lite`. The output is
`build/app/outputs/flutter-apk/app-lite-debug.apk`.

Release builds require a private keystore. Create `android/key.properties`
with `storePassword`, `keyPassword`, `keyAlias`, and `storeFile`. The build now
fails instead of producing an invalid unsigned release APK when signing is not
configured.

The recommended release is `flutter build apk --release --flavor lite`, or run
`./build_latest_release.sh` for formatting, analysis, tests, signing,
certificate verification, and SHA-256 generation. It contains the complete
exam simulator and Lite Tutor without the large model.

Build the separately installable high-memory edition with
`flutter build apk --release --flavor full --target-platform android-arm64`, or run
`./build_full_ai_release.sh`. Run `./tool/download_qwen_model.sh` first to
download and SHA-256 verify the official Apache-2.0 Qwen2.5 0.5B Q3_K_M GGUF.
For Google Play, `flutter build appbundle --release --flavor full --target-platform android-arm64` places the
model in an install-time Play Asset Delivery pack while keeping the base module
within Play's size limit.

Build an unsigned iOS archive with `flutter build ios --release --no-codesign`.
For App Store or device distribution, open `ios/Runner.xcworkspace` in Xcode,
select your Apple development team, and create an Archive.

## Notes

- Questions are locally generated syllabus-aligned practice material, not
  reproduced or certified official past papers.
- Scholarship/readiness indicators are personal study signals, not official
  ranks, admissions decisions, or scholarship guarantees.
- Lite Tutor runs locally without a generative model or network connection. If
  optional native inference cannot start, the tutor stays usable through its
  offline syllabus knowledge engine.
- Only the Full-AI Android flavor contains the GGUF. Android extracts it through
  a native background stream and checks its SHA-256, avoiding a 400+ MB
  Dart-memory spike during first launch.
- Opening AI Tutor never auto-loads the native model. The verified local
  syllabus tutor is immediately available; Advanced AI is opt-in, checks for
  at least 1.4 GB free RAM, uses stable CPU inference on Android, and unloads
  when the tutor closes. Low-memory/model failures remain inside the safe tutor
  instead of crashing the app.
- Android's native low-RAM classification and total/available-memory checks run
  before model extraction. Phones with roughly 1 GB RAM stay in Lite Tutor:
  formulas, worked explanations, generated practice, exam strategy, and study
  plans remain available without allocating llama or copying the model.
- Exam countdowns repaint only the timer; question cards and explanations are
  not rebuilt every second, reducing CPU and battery use on entry-level phones.
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
