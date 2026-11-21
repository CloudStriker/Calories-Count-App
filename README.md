# CalSnap

CalSnap is a personal Android food calorie tracker built with Flutter. Snap a meal photo or pick one from the gallery, get an itemized calorie and macro estimate from Gemini vision, adjust portions if needed, and sync the meal automatically to Samsung Health through Android Health Connect.

## Features

- Photo or gallery meal capture with optional portion notes before AI analysis
- Structured calorie, protein, carbohydrate, and fat breakdown via the Gemini REST API
- Editable meal title, meal category (breakfast, lunch, dinner, snack), and individual food items
- Local SQLite meal history and compressed photo thumbnails
- Automatic write sync to Android Health Connect (`NutritionRecord`) for Samsung Health Food Tracker, with retry for failed syncs
- Adaptive layout tuned for both the Samsung Galaxy Z Fold 6 cover screen and unfolded display, with light and dark themes
- Encrypted on-device storage for your Gemini API key and runtime model switching from Settings

## Getting the APK with GitHub Actions

Because this repository is configured with `.github/workflows/android-ci.yml`, pushing to `main` or a `v*` tag automatically runs `flutter analyze`, `flutter test`, and `flutter build apk --release` on GitHub's runner.

1. Push the repository to GitHub.
2. Open the **Actions** tab and wait for **Android CI** to finish.
3. Download the `calsnap-android-apk` artifact (or grab the APK from **Releases** when pushing a tag such as `v0.1.0`), then install it on your phone.

## Phone Setup (Samsung Galaxy Z Fold 6)

### 1. Add your Gemini API key

1. Create a free API key in Google AI Studio.
2. Open **CalSnap** and tap the Settings icon.
3. Paste your key under **Gemini API**, confirm the model ID (default `gemini-3.5-flash-lite`), adjust your daily calorie target if needed, and tap **Simpan Pengaturan**.

The key is stored only on your device using Android Keystore-backed storage and is never included in source control or the APK. You can switch model IDs directly in Settings without rebuilding the app.

### 2. Link Health Connect to Samsung Health

CalSnap writes `NutritionRecord` entries into Android Health Connect, and Samsung Health pulls them into its Food Tracker automatically.

1. In CalSnap Settings, tap **Hubungkan Health Connect** and allow write access for Nutrition.
2. Open **Samsung Health > Settings > Health Connect** and grant **Read** permission for **Nutrition**.
3. Enable **Sync with Samsung Cloud** in Samsung Health Settings so synced entries stay up to date when you open or pull to refresh Samsung Health.

Note: Android or One UI updates occasionally reset Health Connect permissions. If sync fails later, open CalSnap Settings and check the Health Connect status card.

## Local Development

Requirements:

- Flutter `3.50.0` or later (Dart `>=3.12.0`)
- Java 17
- Android SDK platform 37 (`platforms;android-37`)

If you build locally without CI, generate the Gradle wrapper once inside `android/` before running Flutter:

```bash
cd android && gradle wrapper --gradle-version 9.5.0 --distribution-type all
cd ..
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

## Architecture Notes

Vision analysis sits behind the `FoodAnalyzer` interface in `lib/services/food_analyzer.dart`. Today `GeminiFoodAnalyzer` calls the Gemini `generateContent` REST endpoint directly. To add an offline on-device multimodal model later (such as Gemma 3n via Google AI Edge LiteRT-LM), implement `FoodAnalyzer` and wire a provider toggle in Settings.
