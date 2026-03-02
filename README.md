# HEICFlow

**HEIC to JPG/PNG/PDF — on-device**

HEICFlow is a local-first Flutter app for iOS and Android that imports iPhone HEIC/HEIF photos, previews them, and exports to JPG, PNG, or PDF without uploading files to external servers.

## Highlights

- Local-only processing for core features (no required external APIs)
- Multi-file import queue with validation and per-item status
- Responsive gallery (phone + tablet) with selection mode
- Full-screen viewer with pinch zoom, double-tap zoom, and swipe navigation
- Export pipeline:
  - `JPG` (quality control)
  - `PNG`
  - `PDF` (combined or one-per-image)
- Cancelable export jobs with progress UI
- Share/save outputs with `share_plus`
- ZIP fallback for multi-file output bundles
- History of last 20 export sessions
- Settings for theme, default export format/quality, temp-file policy, and cache cleanup
- Privacy screen describing local processing

## Tech Stack

- Flutter stable (Dart 3.10+)
- State: `flutter_riverpod`
- Routing: `go_router`
- Picker: `file_picker`
- HEIC/HEIF conversion: `heif_converter`
- PDF: `pdf`, `printing`
- Share: `share_plus`
- Storage paths: `path_provider`
- ZIP: `archive`
- Settings/history persistence: `shared_preferences`

## Project Structure

```text
lib/
  app/
  features/
    import/
    gallery/
    export/
    history/
    settings/
    media/
  models/
  services/
  utils/
  widgets/
```

## Setup

## 1) Install dependencies

```bash
flutter pub get
```

## 2) Run

```bash
flutter run
```

## 3) Analyze and test

```bash
flutter analyze
flutter test
```

## Build

### Android

```bash
flutter build apk
# or
flutter build appbundle
```

### iOS

```bash
flutter build ios
```

## Platform Targets

- iOS 15+
- Android 8+ (API 26+)

## Platform Permissions

- iOS (`Info.plist`):
  - `NSPhotoLibraryUsageDescription`
  - `NSPhotoLibraryAddUsageDescription`
- Android (`AndroidManifest.xml`):
  - `android.permission.READ_EXTERNAL_STORAGE` (`maxSdkVersion="32"`)
  - `android.permission.READ_MEDIA_IMAGES` (Android 13+)

## Privacy

HEICFlow processes files on-device. By default, no analytics are enabled and no file contents are uploaded for conversion.

## Supported Formats

### Input

- HEIC
- HEIF
- JPG/JPEG
- PNG

### Output

- JPG
- PNG
- PDF (combined or separate)

## Notes and Limitations

- HEIC/HEIF decoding is handled by native conversion paths.
- Metadata retention can vary by format and platform conversion behavior.
- Some platforms/apps may handle share/open-location targets differently.
