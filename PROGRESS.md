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
| 1 | Local LLM brain and JSON tool calls | Done, tests passed |
| 2 | Real Android tools through Kotlin | Done, tests passed |
| 3 | Offline voice input and wake word | Not started |
| 4 | Background listening service | Not started |
| 5 | Accessibility actions in other apps | Not started |
| 6 | History, speech output and polish | Not started |
| 7 | Optional smart fallback agent | Not started |

## What exists now

- A Flutter project that already existed in this folder, now with a complete
  Stage 0 shell and a working Stage 1 offline model.
- The app has a shared theme (light and dark), responsive helpers, common
  widgets and a real home screen.
- A pinned FunctionGemma model runs fully on the tablet and calls four app
  tools: current time, clear recent commands, call the test contact and send an
  SMS to the test contact.
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

## Done in stage 1

- Replaced the discontinued `flutter_gemma` plan with `flutter_edge_ai` and
  `flutter_edge_ai_litertlm`, after reading their real API and example.
- Added the pinned FunctionGemma 270M `.litertlm` catalog model, loaded fully
  on the device, with download progress and automatic loading on later starts.
- Added the tool base class, registry and two tools: the safe current-time tool
  and the risky clear-history tool that needs a confirmation dialog.
- Added the assistant controller, tool-call model, typed command box, brain
  status card, latest result card and in-memory recent commands card.
- Added automated tests for the safe tool-call JSON reader.
- Kept all model calls inside `lib/services/llm_service.dart`.
- Tested on the real tablet: download, load, safe tool, risky cancel/approve,
  unknown command, rotation, light/dark, phone width and app restarts. The full
  table is in `TEST_REPORT_STAGE_1.md`.

## Done in stage 2

- Added one Kotlin method channel in `MainActivity.kt` for the call and SMS
  actions, with runtime `CALL_PHONE` and `SEND_SMS` permission handling.
- Locked both actions to the one approved test contact, sarthak at 9023850632.
  The number is fixed in Kotlin, and the Dart tool schemas take no recipient,
  so the model cannot choose anyone else.
- Added `AndroidToolService`, `CallTestContactTool` and `SendSmsTool`, and
  registered them next to the Stage 1 tools.
- Extended the shared confirmation dialog with a per-tool confirm label and a
  scrollable body, so `Call`, `Send` and `Delete` read correctly and long SMS
  previews do not overflow.
- Added `CALL_PHONE`, `SEND_SMS` and an optional telephony feature to the
  manifest.
- Tested on the real tablet: call and SMS confirmation, cancel paths, Android
  permission boxes, the call and SMS handoff to Android, safe-tool regression,
  three-time repeat, rotation, light/dark, phone width and app restarts. The
  full table is in `TEST_REPORT_STAGE_2.md`.

## Next

- Start stage 3: offline voice input and wake word. Ask the user before adding
  an accessibility service, and confirm microphone accuracy and wake-word
  behaviour in noise on the device before calling it done.

## Known issues

- The test tablet has no SIM and no mobile network, so a real connected call
  and a delivered SMS could not be verified. Only the permission flow and the
  Android handoff were checked.
- Real voice and wake word are not built yet.
- History is in memory only, so a cold start has an empty list.
- Testing needs the tablet connected over wireless debugging.
