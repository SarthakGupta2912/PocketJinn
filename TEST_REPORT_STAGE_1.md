# Stage 1 test report

Device: Samsung SM-T865 (Galaxy Tab S6), Android 12, wireless debugging.
App id: `com.Sarthak.pocket_jinn`.
Build: debug APK built with `flutter build apk --debug` and installed with
`adb install -r`.
Package: `flutter_edge_ai` 2.7.1 and `flutter_edge_ai_litertlm` 1.21.0.
Model: pinned catalog entry `functiongemma-270M-it.litertlm`
(284,426,240 bytes) downloaded once over Wi-Fi.

The device stayed in dark mode, portrait, with display size reset to the
physical 1600 x 2560 panel and density 420, except where a row below says a
mode or size was changed. Rotation and night mode were restored afterwards.

## Results

| # | Test | Commands used | Expected | Actual | Result | Screenshot |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | Install and launch | `adb install -r app-debug.apk`, `adb shell monkey -p ... 1` | App opens, no crash | App opened with the Stage 1 cards, no fatal log | PASS | `stage1_launch_dark.png` |
| 2 | Download the model on the tablet | Tap `Prepare offline brain` | Progress shown, file saved, model loads | Download started through the catalog URL, progress bar reached 36% in the first check, then install finished and the UI showed "Offline brain ready" | PASS | `stage1_download2.png`, `stage1_load.png` |
| 3 | Load the model again after relaunch | Force-stop, relaunch | Model opens without downloading | Screen showed "Offline brain ready" about 30 s after launch; log had "restored active inference model: functiongemma-270M-it.litertlm" | PASS (after fix) | `stage1_autoload2.png` |
| 4 | Safe tool | Type `what time is it` and press Send | `get_current_time` runs and a readable time is shown | Tool called by FunctionGemma; card showed "The current time is 6:44 AM on Monday, 23 November 2026." | PASS | `stage1_time3.png` |
| 5 | Repeat the safe tool three times | Same command three times in a row | Three correct answers, no history mix-up | Three tool calls in log and three updated times | PASS | `stage1_repeat1.png` to `stage1_repeat3.png` |
| 6 | Risky tool, cancel path | `clear my recent commands`, tap `Cancel` | Confirmation appears, nothing is deleted | Dialog asked "Delete all recent commands?"; Cancel kept every history row and returned "The user declined." | PASS | `stage1_confirm2.png`, `stage1_cancel2.png` |
| 7 | Risky tool, approve path | Same command, tap `Delete` | Confirmation appears, history is cleared | Result became "Recent commands cleared." and the old rows disappeared | PASS | `stage1_deleted_top.png`, `stage1_deleted_bottom.png` |
| 8 | Unknown command | Type `tell me a joke` | Friendly reply, no tool, no crash | Model replied that it can only manage the app tasks; no tool ran | PASS | `stage1_unknown2.png` |
| 9 | Empty or whitespace command | Send blank field | Nothing is sent | `ask()` ignores empty text, no model call | PASS (code and UI check) | `stage1_cleared3.png` |
| 10 | Dark mode tablet portrait | `cmd uimode night yes` | Dark theme stays readable | Correct colors, status bar icons visible | PASS | `stage1_time3.png` |
| 11 | Light mode tablet portrait | `cmd uimode night no` | Light theme stays readable | Correct light colors, dark status bar icons | PASS | `stage1_light.png` |
| 12 | Tablet landscape | `settings put system user_rotation 1` | Content reflows and scrolls | Centered 700 dp column, page scrolled, no overflow log | PASS | `stage1_landscape.png` |
| 13 | Phone-width window | `adb shell wm size 1080x1920` | One column, no cut text | Text wrapped, buttons stayed full width, no overflow log | PASS | `stage1_phone.png` |
| 14 | Typing survives a rebuild | Type a draft, rotate to landscape | Draft text is kept | Text stayed in the field after rotation | PASS (after fix) | `stage1_draft.png` |
| 15 | Home, then reopen | `input keyevent 3`, then `monkey -p ... 1` | App resumes with state intact | Same result and ready state, no crash | PASS | `stage1_lifecycle.png` |
| 16 | Force-stop, then cold start | `am force-stop`, `monkey -p ... 1` | Clean start and automatic model load | New process, model opened, no fatal log | PASS | `stage1_autoload2.png` |
| 17 | Automated parser tests | `flutter test` | JSON reader accepts valid calls and rejects bad text | 6 of 6 tests passed | PASS | - |
| 18 | Static checks | `dart format lib test`, `flutter analyze` | No format or analyzer problems | Formatter clean, "No issues found!" | PASS | - |
| 19 | Crash and exception check | `adb logcat -d` filtered for FATAL, Unhandled, Exception | No app crash lines | No Flutter or app crash lines. Samsung Taskbar and Galaxy Store warnings belong to the system, not this app | PASS | - |
| 20 | Permission check | `dumpsys package com.Sarthak.pocket_jinn` | Only the declared network permission | `android.permission.INTERNET` granted; no runtime permission requested | PASS | - |

## Fixes made during testing

1. The first launch after the model was installed still offered
   `Prepare offline brain`. The installed id includes the `.litertlm` suffix,
   so the check missed it. The model id is now matched with or without that
   suffix, and it loads automatically on launch.
2. `CommandInputCard` created its `TextEditingController` inside `build()`,
   which could drop a partly typed command. It is now a `StatefulWidget` that
   owns and disposes the controller. The draft survived a rotation on device.
3. `get_current_time` originally returned only an ISO timestamp. It now keeps
   the ISO value and adds a spoken-style message, which is what the result card
   shows.

## Notes and limits

- The 284 MB model download happens once. If the app data is cleared, it must
  download again.
- History is in memory only in this stage, so a cold start begins with an empty
  list. Saving history is planned for a later stage.
- The cancel path is also added to the recent list as "The user declined.".
  That is the current honest record of the command.
- Voice input, wake word, accessibility and real Android actions do not exist
  yet. The microphone button still shows the "coming soon" message.
- The grey pencil in some screenshots is the tablet's S Pen shortcut, not app
  UI.

## Honest summary

Stage 1 works on the connected tablet: the pinned model downloads, loads
offline, understands typed commands, runs the safe time tool, asks before the
risky clear tool, and keeps working across rotation, light/dark mode, phone
width and app restarts. Everything marked PASS was checked on the real device
or by the named command. Nothing in this report is a placeholder result.
