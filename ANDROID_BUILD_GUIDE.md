# Android build guide

This ZIP contains the Flutter application source and the verified local SQLite dataset. It does **not** currently include the generated Android platform folder or a compiled APK.

## Requirements
- Flutter SDK with Dart 3 support
- Android Studio / Android SDK
- Android device or emulator

## Create Android platform files (first time only)
From this project directory, run:

```bash
flutter create --platforms=android .
```

If the generated `android/app/src/main/AndroidManifest.xml` does not already contain it, add this permission inside the `<manifest>` element:

```xml
<uses-permission android:name="android.permission.INTERNET" />
```

Internet permission is needed for streamed recitation audio. Quran text remains local/offline.

## Resolve packages and validate

```bash
flutter pub get
flutter analyze
flutter test
```

## Run on a connected Android phone

```bash
flutter run
```

## Build a debug APK

```bash
flutter build apk --debug
```

Expected output:
`build/app/outputs/flutter-apk/app-debug.apk`

Do not describe the app as release-ready until the APK has been installed and tested on real Android devices, audio playback and rights have been checked, and all pending Quran content has been reviewed.
