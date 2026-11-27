# Stage 4 test report — background "Hey Jinn" wake word

Date: 27 November 2026
Device: Samsung SM-T865 (Galaxy Tab S6), Android 12, wireless ADB
App id: `com.Sarthak.pocket_jinn`, debug build installed with `adb install -r`
Build checks: `dart format .` clean, `flutter analyze` no issues, `flutter test`
8/8 pass, `flutter build apk --debug` succeeds.

## What Stage 4 adds

- A microphone-type foreground service (`WakeWordService`) with a persistent
  notification, started only while the app is visible.
- Five bundled, verified sherpa-onnx keyword-spotting model files copied into
  app-private storage on first use.
- A `KeywordSpotter` running in its own Dart isolate, fed by a 16 kHz PCM
  microphone stream.
- A Settings card that turns the wake word on and off and shows its state.
- The wake word pauses while a normal voice command owns the microphone and
  restarts when that command ends.
- On a foreground wake, the app returns home and starts listening.
- On a background wake, Android shows a "Pocket Jinn heard you" notification;
  tapping it opens the app and starts listening. Android blocks automatic
  activity launches from the background, so the notification is the handoff.

## Model verification before device testing

The model bundled in the app is from the official full release archive:

`https://github.com/k2-fsa/sherpa-onnx/releases/download/kws-models/sherpa-onnx-kws-zipformer-gigaspeech-3.3M-2024-01-01.tar.bz2`

- The five bundled files were checked against the SHA-256 sums in
  `assets/wake_model/NOTICE.txt`.
- The separate `-mobile` encoder (4,000,908 bytes) fails on the first decode
  with an ONNX Reshape shape error in sherpa-onnx 2.0.3. The full int8 encoder
  (4,807,159 bytes, `1e721676…`) works and is the one bundled.
- `sherpa-onnx-cli text2token` with the bundled `tokens.txt` and `bpe.model`
  produced `▁HE Y ▁ J IN N` for `HEY JINN`.
- With sherpa-onnx Python 2.0.3 (the same native version as the Flutter plugin):
  - Official test WAVs detect `LIGHT UP`, `LOVELY CHILD` and `FOREVER`.
  - Windows SAPI voices Hazel (en-GB) and Zira (en-US) saying "Hey Jinn"
    detect `HEY JINN`; David (en-US) does not.
  - `keywordsScore = 3.0`, `keywordsThreshold = 0.25` gives no detection on
    30 s of white noise, silence, "Hello world", "Hey Siri", "Light up" or
    the two official test WAVs.
  - "Hey Gin" and "Hey Jean" can trigger, as expected for near-homophones.

## Device results

| Check | Result | Evidence |
| --- | --- | --- |
| Settings card appears at bottom of Settings | PASS | Screenshot `stage4_settings.png` |
| Switch on, model copied and worker loaded | PASS | `Wake load ms: 991` / `991–1173 ms` |
| Status changes to `Listening for "Hey Jinn".` | PASS | Screenshot `stage4_on.png` |
| Microphone foreground service is running | PASS | `dumpsys activity services`: `.WakeWordService`, `isForeground=true`, id 4104 |
| Persistent notification "Pocket Jinn is listening" | PASS | Screenshot `stage4_shade.png` |
| Pushed WAV fed to worker detects the keyword | PASS | `Wake detected: HEY JINN` |
| Foreground wake starts normal listening | PASS | Screenshot `stage4_detected.png`, `Qwen3 load ms: 5503` |
| Card says "paused while the microphone is open" | PASS | Screenshot `stage4_before_off.png` |
| Wake resumes after the voice command | PASS | `Wake audio chunk` logs resume; second `Wake detected: HEY JINN` |
| Non-wake WAV ("Hello world") does not trigger | PASS | No detection in log |
| App in background, wake is detected | PASS | `Wake detected: HEY JINN` with launcher still top activity |
| Alert notification "Pocket Jinn heard you" | PASS | Screenshot `stage4_shade.png`, `dumpsys notification` |
| No automatic activity launch from background | PASS | `topResumedActivity` stays the launcher |
| Tapping the alert opens app and starts listening | PASS | `topResumedActivity` becomes `.MainActivity`, `Qwen3 load ms: 5350`, screenshot `stage4_notif_tap.png` |
| Switch off stops service and notifications | PASS | `dumpsys` shows no `WakeWordService` or Pocket Jinn notifications; screenshot `stage4_off.png` |

## NOT VERIFIED

- **Real human voice.** No person spoke "Hey Jinn" near the tablet during this
  test. Detection was verified by feeding pushed WAVs through the same worker.
- **Speaker-to-microphone path.** Playing the TTS WAV through the tablet
  speaker while the wake listener was on did not produce a detection. The
  microphone stream was active and carried audio, but Samsung's record path may
  suppress or distort the speaker playback. The user should say the phrase
  aloud; that path was not reproducible with the available tools.
- **Noise on device.** The parameter sweep used generated noise on the dev
  machine. No live noisy-room test with the tablet was possible.
- **Android 13+ notification permission.** The test device is Android 12, so
  `POST_NOTIFICATIONS` did not need a runtime prompt. The code requests it on
  Android 13+, but that prompt was not exercised.

## Debug hook

`adb shell am broadcast -a com.Sarthak.pocket_jinn.DEBUG_COMMAND --es wake_path /sdcard/x.wav`
feeds a pushed WAV into the wake worker without using the microphone. It exists
for repeatable device tests and is available only while the app is running.
