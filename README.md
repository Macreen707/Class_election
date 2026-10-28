# Class_election
# Class Election App

A Flutter class-election app that lets voters vote for a candidate, view the current results, and read live advice from an internet API.

Votes and voter names are saved on the phone using `shared_preferences`, so the data remains after the app closes and opens again. The Live API screen gets advice from `https://api.adviceslip.com/advice` and shows a Retry button if the request fails.

## Packages

Add these packages to `pubspec.yaml` under `dependencies` (keep your existing Flutter dependency):

```yaml
dependencies:
  flutter:
    sdk: flutter
  shared_preferences: ^2.5.3
  http: ^1.4.0
```

Then run:

```bash
flutter pub get
```

## Run the app

1. Back up your existing `lib/main.dart`.
2. Replace its contents with the supplied `main.dart`.
3. Add the two packages above to `pubspec.yaml`.
4. For Android, check that `android/app/src/main/AndroidManifest.xml` includes this permission above the `<application>` element:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

5. Run:

```bash
flutter pub get
flutter run
```

## Screenshots

Create a folder named `screenshots` in the project root. Add your own screenshots with these exact file names:

- `screenshots/before.png` — vote screen after you have entered some test votes.
- `screenshots/after.png` — close/stop the app, run it again, and show that the vote counts remain.
- `screenshots/api.png` — the Live API screen after advice has loaded.
- `screenshots/no-internet.png` — turn on Airplane mode, open the Live API screen, and show the error and Retry button.

## Screenshot previews

![Before closing](screenshots/before.png)

![After running again](screenshots/after.png)

![Live data from an API](screenshots/api.png)

![No internet](screenshots/no-internet.png)

## Push to GitHub

1. Create a **public** repository on GitHub.
2. In a terminal opened in the Flutter project folder, run:

```bash
git init
git add .
git commit -m "Build class election mini project"
git branch -M main
git remote add origin https://github.com/YOUR-USERNAME/YOUR-REPOSITORY.git
git push -u origin main
```

Replace the example repository URL with your own. If Git is already initialized, do not repeat `git init` or add a second remote; check `git remote -v` first.

## Important notes

- The candidate names in this sample are Macrine Singiza, Diane Uwase, and Alice Mukamana. Change them to the names approved for your own project if needed.
- The app prevents the same voter name from voting twice on this device. This is a classroom demo, not a secure online election: local preferences can be edited or cleared and the app does not synchronize votes between phones.
- You should understand and test the code before submitting it. Capture the four screenshots from your own running app and use your own GitHub repository.
