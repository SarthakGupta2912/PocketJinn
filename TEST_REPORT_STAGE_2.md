# Stage 2 test report

Device: Samsung SM-T865 (Galaxy Tab S6), Android 12, wireless debugging.
App id: `com.Sarthak.pocket_jinn`.
Build: debug APK built with `flutter build apk --debug` and installed with
`adb install -r`, so the 284 MB model stayed installed.
Model: the same pinned FunctionGemma 270M `.litertlm` model from Stage 1.

Stage 2 adds two risky real Android tools through one Kotlin method channel:
`call_test_contact` and `send_sms_to_test_contact`. Both are locked to the one
approved test contact, sarthak at 9023850632. The number is fixed in
`MainActivity.kt`, so a model mistake cannot reach anyone else.

The device stayed in dark mode, portrait, with the physical 1600 x 2560 panel and
the 420 density override, except where a row below says a mode or size was
changed. Rotation, night mode and display size were restored afterwards.

## Results

| # | Test | Commands used | Expected | Actual | Result | Screenshot |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | Install and launch | `adb install -r app-debug.apk`, `adb shell monkey -p ... 1` | App opens, no crash | App opened, model started loading, no fatal log | PASS | `s2_start.png` |
| 2 | Model auto-load | Wait after launch | Brain becomes ready without downloading | Card changed to "Offline brain ready" | PASS | `s2_loaded.png` |
| 3 | Call confirmation | `call sarthak` | Confirmation names the fixed contact and uses the `Call` label | Dialog "Call sarthak at 9023850632?" with Cancel / Call | PASS | `stage2_call_confirm.png` |
| 4 | Call cancel path | Same command, tap `Cancel` | Nothing is dialled | Dialog closed, no call started, reply "The user declined." | PASS | `stage2_call_confirm.png` |
| 5 | Call permission | Same command, tap `Call`, then Android permission box | Android asks for phone permission, then dials | CALL_PHONE box shown, Allow granted, `ACTION_CALL` started for `tel:9023850632` | PASS | `stage2_call_permission.png`, `stage2_call_live.png` |
| 6 | Call reaches Android | `dumpsys telecom` after Allow | An outgoing call is started to the test number | `START_OUTGOING_CALL` to `tel:90******32`, then disconnect with `Sim Absent` | PASS (handoff only) | `stage2_call_live.png` |
| 7 | SMS confirmation | `send sms to sarthak saying hello from pocket jinn` | Confirmation previews the exact text and uses the `Send` label | Dialog "Send this SMS to sarthak at 9023850632?" with the message body and Cancel / Send | PASS | `stage2_sms_confirm.png` |
| 8 | SMS permission | Tap `Send` | Android asks for SMS permission, then the SMS is handed off | SEND_SMS box shown, Allow granted (`state = Granted`), tool returned success | PASS | `stage2_sms_permission.png` |
| 9 | SMS result message | After Allow | Honest handoff wording | Card showed "SMS handed to Android for sending to sarthak at 9023850632." | PASS | `stage2_sms_result.png` |
| 10 | SMS cancel path | `send sms to sarthak saying cancel test`, tap `Cancel` | No permission box, nothing sent | Dialog closed, no permission prompt, reply "The user declined." | PASS | `s2_sms_cancel_prompt.png`, `s2_sms_cancelled2.png` |
| 11 | Safe tool regression | `get the current time` | Time tool runs with no confirmation | Card showed "The current time is 7:38 AM on Tuesday, 24 November 2026." | PASS | `s2_time2.png` |
| 12 | Safe tool repeated three times | Same command three times | Three correct answers, no drift, no crash | Three SDK-parsed tool calls in the log and three updated times | PASS | `s2_time3x.png` |
| 13 | Unclear phrasing stays safe | `what time is it` | No crash; only a text reply is fine | Model replied in text without calling a tool; nothing risky ran | PASS (note below) | `s2_time.png` |
| 14 | Tablet landscape | `settings put system user_rotation 1` | Content reflows and scrolls | Centered column, page scrolled, no overflow log | PASS | `s2_landscape.png` |
| 15 | Light mode | `cmd uimode night no` | Light theme stays readable | Correct light colors and dark status icons | PASS | `s2_light.png` |
| 16 | Dark mode | `cmd uimode night yes` | Dark theme stays readable | Correct dark colors | PASS | `s2_phone.png` |
| 17 | Phone-width window | `wm size 1080x2340`, `wm density 420` | One column, no cut text | Text wrapped, buttons stayed full width, no overflow log | PASS | `s2_phone.png` |
| 18 | Home, then reopen | `input keyevent 3`, then `monkey -p ... 1` | App resumes with state intact | Model still ready, latest result kept, no crash | PASS | `s2_resume.png` |
| 19 | Overflow and crash scan | `adb logcat -d` filtered for FATAL, Unhandled, RenderFlex overflow | No app crash or overflow lines | No app crash or overflow lines; only Samsung system warnings | PASS | - |
| 20 | Permission state | `dumpsys package com.Sarthak.pocket_jinn` | CALL_PHONE and SEND_SMS granted after Allow | Both listed as `granted=true` | PASS | - |
| 21 | Automated tests | `flutter test` | Tool-call JSON reader still correct | 6 of 6 tests passed | PASS | - |
| 22 | Static checks | `dart format lib`, `flutter analyze` | No format or analyzer problems | Formatter clean, "No issues found!" | PASS | - |

## Fixes made during testing

1. The SMS tools originally said "SMS sent...". Android only accepts the SMS
   request and, on a tablet without a SIM, cannot report real delivery. Both the
   Kotlin and Dart messages now say "SMS handed to Android for sending to ...",
   which is what actually happens.
2. The shared confirmation dialog is now `scrollable: true`, so a long SMS
   preview cannot overflow the dialog.
3. The confirmation dialog now takes a per-tool confirm label, so the risky
   buttons read `Call`, `Send` and `Delete` instead of a generic word.

## Notes and limits

- This tablet is an LTE model but has **no SIM inserted** and no mobile network.
  Android accepted both requests and started the call (`START_OUTGOING_CALL`),
  then ended it with `Sim Absent`. Because of that, a real connected call and a
  real delivered SMS could **not** be verified on this device. The app's part,
  the permission flow and the Android handoff were verified.
- The SMS is reported as "handed to Android for sending", not "delivered",
  because delivery cannot be confirmed here.
- FunctionGemma is a small single-turn model. `what time is it` produced a text
  reply instead of the time tool; `get the current time` called the tool
  correctly. This is model wording behaviour, not an app fault, and no risky
  action was involved.
- The grey pencil in some screenshots is the tablet's S Pen shortcut, not app
  UI.
- `shots/*` screenshots are kept locally and are not committed.

## Honest summary

Stage 2 works on the connected tablet: both risky tools ask for confirmation
first, cancel does nothing, Android shows and records the runtime permissions,
and the call and SMS requests reach Android locked to sarthak at 9023850632.
Safe tools, rotation, light/dark, phone width and app restarts still work, with
no crashes or overflow. What could not be shown on this device is a real
connected call or a delivered SMS, because there is no SIM and no mobile
network. Nothing in this report is a placeholder result.
