# Pocket Jinn progress

Pocket Jinn is an offline, on-device voice assistant for Android. The Flutter
app sends a spoken command to a small local language model, the model answers
with a JSON tool call, and the app runs the matching Android action.

This file is updated at the start and end of every stage.

## How to run

1. Open a terminal in this folder.
2. Run `flutter pub get`.
3. Connect the phone with wireless debugging, then check `adb devices`.
4. Run `flutter run -d <device-id>`.

The current application id is `com.Sarthak.pocket_jinn`.

## Stage status

| Stage | What it adds | Status |
| --- | --- | --- |
| 0 | Audit, theme, responsive helpers, common widgets, home screen | Done, tests passed |
| 1 | Local LLM brain and JSON tool calls | Not started |
| 2 | Real Android tools through Kotlin | Not started |
| 3 | Offline voice input and wake word | Not started |
| 4 | Background listening service | Not started |
| 5 | Accessibility actions in other apps | Not started |
| 6 | History, speech output and polish | Not started |
| 7 | Optional smart fallback agent | Not started |

## What exists now

- A Flutter project that already existed in this folder, with a hello world
  `lib/main.dart` and an empty Kotlin `MainActivity`.
- The app now has a shared theme (light and dark), responsive helpers, common
  widgets and a real home screen.
- Android only. The `ios` folder is left untouched.

## Done in stage 0

- Started a git repository and connected the GitHub remote.
- Added `.gitignore` rules for build files, keys and AI model downloads.
- Added `lib/core/constants.dart`, `app_theme.dart`, `app_theme_component_themes.dart`
  and `responsive.dart`.
- Added shared widgets for text, buttons, cards, fields, dialogs, chips and
  the big microphone button.
- Added the first home screen, built only from shared widgets.
- Fixed the light mode status bar colors after seeing the first screenshot.
- Tested on the real tablet in tablet, phone, landscape, light and dark sizes.
  The full table is in `TEST_REPORT_STAGE_0.md`.

## Next

- Start stage 1: add `flutter_gemma`, the tool call model, the tool registry
  and a text command box. Before writing code, check the real package version
  and the real model names on the device.

## Known issues

- None in stage 0.
- Real voice, wake word, permissions and Android tools are not built yet.
- Testing needs the tablet connected over wireless debugging.
