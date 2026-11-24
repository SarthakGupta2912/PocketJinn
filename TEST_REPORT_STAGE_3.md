# Stage 3 test report

Device: Samsung SM-T865 (Galaxy Tab S6), Android 12, wireless debugging.
App id: `com.Sarthak.pocket_jinn`.
Build: debug APK built with `flutter build apk --debug` and installed with
`adb install -r`, so the 284 MB language model from Stage 1 stayed installed.

Stage 3 replaces the old "voice input is not ready yet" message with real
push-to-talk offline speech recognition. The chosen scope is push-to-talk only;
always-on "Hey Jinn" wake word stays for Stage 4. The app downloads the four
small English speech-model files once (about 45 MB total), asks for the
microphone permission, then captures 16 kHz mono PCM and decodes it with
`sherpa_onnx` directly on the tablet. A finished transcript is sent to the same
FunctionGemma brain used in Stages 1 and 2.

The device stayed in dark mode, portrait, with the physical 1600 x 2560 panel and
the 420 density override, except where a row below says a mode or size was
changed. Rotation, night mode and display size were restored afterwards.

## Results

| # | Test | Commands used | Expected | Actual | Result | Screenshot |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | Install and launch | `adb install -r ...`, `am start -n .../.MainActivity` | App opens, old brain still ready | App opened, "Offline brain ready", no fatal log | PASS | `stage3_home.png` |
| 2 | Mic permission | Tap the microphone | Android asks to record audio | "Allow Pocket Jinn to record audio?" with While using the app / Only this time / Don't allow | PASS | `stage3_permission.png` |
| 3 | Permission granted | Tap "While using the app" | Permission recorded by Android | `RECORD_AUDIO` listed as `granted=true` | PASS | - |
| 4 | One-time model download | Continue after permission | Four files download with visible progress | Four files appeared in app support storage (42,845,182 / 2,092,272 / 259,572 / 5,048 bytes) | PASS | `stage3_download.png` |
| 5 | Listening state | After download and load | Button turns red, live hint shown | "Listening... tap the microphone to stop." with the red stop icon | PASS | `stage3_final_listen.png` |
| 6 | Tap to stop | Tap the microphone again | Recording stops, empty speech gives a clear message | "I did not catch that. Please try again." | PASS | `stage3_final_idle.png` |
| 7 | 15-second safety stop | Start listening with no command and wait | App stops itself instead of recording forever | After about 15 s the mic returned to idle with the no-speech message | PASS | `stage3_timeout.png` |
| 8 | Live microphone capture | Instrumented debug build during testing | Real audio samples arrive from the mic | 2560-byte PCM chunks arrived about every 80 ms with non-zero peaks | PASS | - |
| 9 | Offline recognizer correctness | Feed a saved spoken phrase to the recognizer in whole-file and microphone-sized chunks | English words are recognized without a network | "T TIME IS IT" was transcribed from the test phrase both ways | PASS (engine only) | - |
| 10 | Start/stop repeated three times | Tap, wait, tap, three rounds | No stuck state or crash | Each round showed listening, then the no-speech message; no FATAL log | PASS | `r1.txt`, `r2.txt`, `r3.txt` |
| 11 | Tablet landscape | `settings put system user_rotation 1` | Column reflows and scrolls | Content reflowed and scrolled, no overflow | PASS | `stage3_landscape.png` |
| 12 | Light mode | `cmd uimode night no` | Theme stays readable | Correct light colors and status icons | PASS | `stage3_light.png` |
| 13 | Dark mode | `cmd uimode night yes` | Theme stays readable | Correct dark colors | PASS | `stage3_home.png` |
| 14 | Phone-width window | `wm size 1080x1920` | One column, no cut text | Text wrapped and the mic fit the narrower width, no overflow | PASS | `stage3_phone.png` |
| 15 | Crash and overflow scan | `adb logcat -d` filtered for FATAL, exceptions and overflow | No app crash or overflow | No app crash or overflow lines from the app | PASS | - |
| 16 | Automated tests | `flutter test` | Existing tests still pass | 6 of 6 tests passed | PASS | - |
| 17 | Static checks | `dart format lib`, `flutter analyze` | No format or analyzer problems | Formatter clean, "No issues found!" | PASS | - |

## Fixes made during testing

1. The first build created the speech recognizer before the model files were
   downloaded, so the first mic tap failed with "Offline voice is not ready."
   Permission is now requested first, the model downloads second, and the
   recognizer is created only after the files exist.
2. Automatic endpoint detection was disabled for push-to-talk. On this tablet it
   ended a session after a short silence before the user had spoken. Listening
   now stops on a tap or after 15 seconds.
3. The mic recorder now uses the exact plain 16-bit PCM configuration from the
   `sherpa_onnx` example. Extra auto-gain and noise-suppression flags were
   removed because they raised the noise floor on this device.
4. All temporary diagnostic hooks used while testing (test WAV playback, chunk
   logging and WAV capture) were removed before the final build.

## Notes and limits

- The one-time download needs Wi-Fi. After that, all speech recognition is fully
  offline.
- The recognizer is English-only and its model is small, so accuracy in a noisy
  room will be lower than a large cloud service. That is the trade-off for a
  fully offline app.
- Acoustic verification with a real human voice was **not** completed in this
  session. The tablet's microphone does capture audio, and the offline
  recognizer correctly transcribed a stored spoken phrase when fed the same PCM
  path and chunk size, but a spoken command through the tablet's speaker was
  masked by the room noise floor here. Microphone accuracy still needs the user
  to speak a few commands near the tablet before Stage 3 can be called complete.
- No wake word is active yet. The user chose push-to-talk first, so "Hey Jinn"
  remains visual branding until Stage 4.
- The grey pencil in some screenshots is the tablet's S Pen shortcut, not app UI.
- `shots/*` screenshots are kept locally and are not committed.

## Honest summary

The microphone is no longer a placeholder: it asks for permission, downloads the
offline voice model once, records real audio, shows live state, stops safely, and
sends a final transcript to the existing brain. On-device recognition was
verified with a stored spoken phrase, and all UI, lifecycle, responsive and
static checks passed on the tablet. What is still unconfirmed is how accurately
it hears a real person speaking in this room; the user needs to speak a few test
commands before that part can be marked done.
