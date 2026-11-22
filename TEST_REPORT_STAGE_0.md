# Stage 0 test report

Device: Samsung SM-T865 (Galaxy Tab S6), Android 12, wireless debugging.
App id: `com.Sarthak.pocket_jinn`.
Build: debug, installed with `flutter run -d <wireless-device-id>`.

The device was already in dark mode and had a display density override of 420.
Both were restored afterwards (`wm size` reset to physical, density 420,
`accelerometer_rotation` 1, `user_rotation` 0, night mode yes).

## Results

| # | Test | Commands used | Expected | Actual | Result | Screenshot |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | Fresh install and launch | `flutter run -d <device>` | App opens on the home screen with no crash | App opened, first frame drawn, no crash | PASS | `stage0_home_dark_tablet.png` |
| 2 | Dark mode tablet portrait, 610 x 975 dp | `adb exec-out screencap` | Theme, spacing and cards look correct | Purple and dark theme, readable text, no overflow | PASS | `stage0_home_dark_tablet.png` |
| 3 | Light mode tablet portrait | `adb shell cmd uimode night no` | Colors switch and text stays readable | Light theme looked correct | PASS | `stage0_home_light_tablet.png` |
| 4 | Status bar readability | Screenshot review | Clock and battery icons easy to read | First build showed white icons on a pale background. Added a theme status bar style, rebuilt, icons are now dark | PASS (after fix) | `stage0_home_light_final.png`, `stage0_home_dark_final.png` |
| 5 | Big tablet landscape, 975 x 610 dp | `adb shell wm size 2560x1600` | Centered content, page scrolls, no overflow stripes | Centered column, scrollable, no overflow | PASS | `stage0_home_light_landscape.png` |
| 6 | Small phone portrait, 360 x 800 dp | `adb shell wm size 1080x2400`, `wm density 480` | Single column, chips wrap, no cut text | Chips wrapped to two rows, text wrapped, no overflow | PASS | `stage0_home_light_small_phone.png` |
| 7 | Phone portrait, 411 x 914 dp | `adb shell wm size 1080x2400`, `wm density 420` | One column, scrollable | Correct one-column layout | PASS | `stage0_home_light_phone.png` |
| 8 | Phone landscape, 914 x 411 dp | `adb shell wm size 2400x1080` | Scrollable, no overflow | Scrollable, microphone below the fold, no overflow | PASS | `stage0_home_light_phone_landscape.png` |
| 9 | Tap the microphone button | `adb shell input tap 800 1177` | Friendly message, no crash | Snack bar: "Voice input is not ready yet..." | PASS | `stage0_mic_tap_dark.png` |
| 10 | Repeat main action three times | Same tap repeated 3 times, UI dump after each | Same friendly message every time | Message found in all 3 UI dumps | PASS | `stage0_repeat_1.xml` to `stage0_repeat_3.xml` |
| 11 | Press Home, then reopen | `adb shell input keyevent KEYCODE_HOME`, `am start -n ...` | App returns without losing state or crashing | Task brought to front, screen intact | PASS | `stage0_home_dark_final.png` |
| 12 | Force-stop and relaunch | `adb shell am force-stop`, `am start -n ...` | Cold start works | App started with a new pid, no crash | PASS | `stage0_relaunch_tablet.png` |
| 13 | Rotate while running | `settings put system accelerometer_rotation 0`, `user_rotation 1` | Layout reflows and stays usable | Reflowed to landscape, no overflow | PASS | `stage0_rotate_tablet_landscape.png` |
| 14 | Dark mode phone portrait | `cmd uimode night yes` | Dark theme on a small window | Correct dark theme, no overflow | PASS | `stage0_home_dark_phone.png` |
| 15 | Empty / gibberish / very long command | Not possible yet | Friendly message for bad input | This stage has no text box or model yet, so there is nothing to send. Voice tap shows a friendly message instead | NOT APPLICABLE | - |
| 16 | Permission denied | Not possible yet | Friendly message, no crash | This stage requests no runtime permission. Permission tests start in stage 2 | NOT APPLICABLE | - |
| 17 | Crash and exception check | `adb logcat -d --pid=<app pid>` filtered for FATAL, AndroidRuntime, Exception, E/flutter | Zero crash or exception lines | Zero matching lines after launch, taps, rotation and relaunch | PASS | - |
| 18 | Memory snapshot | `adb shell dumpsys meminfo com.Sarthak.pocket_jinn` | App memory is reasonable | 228 MB PSS for a debug build with the Flutter engine | PASS | - |

## Notes

- Some screenshots include a small grey pencil floating button. That is the
  tablet's S Pen shortcut, not part of Pocket Jinn.
- A grey status bar band was found in light mode during testing. It was fixed
  in `app_theme.dart` by matching the status bar color to the page and using
  dark status bar icons. The fix was rebuilt and re-checked.
- Real voice, wake word, permissions and Android tools do not exist yet, so
  those cannot be verified in this stage.

## Honest summary

Stage 0 passes on the connected tablet. The only parts waiting for later
stages are voice input, wake word, runtime permissions and real Android
actions. Nothing was marked PASS without running it on the device.
