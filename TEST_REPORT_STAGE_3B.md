# Stage 3B test report

Device: Samsung SM-T865 (Galaxy Tab S6), Android 12, wireless debugging.
App id: `com.Sarthak.pocket_jinn`.
Build: debug APK built with `flutter build apk --debug` and installed with
`adb install -r`, so the Stage 1 language model stayed installed.

Stage 3B replaces the English-only Stage 3 recognizer with a swappable speech
engine interface. `SherpaSpeechEngine` uses Qwen3-ASR 0.6B int8 and Silero VAD.
`AndroidSpeechEngine` uses Android's `SpeechRecognizer` with
`EXTRA_PREFER_OFFLINE`. Settings lets the user pick either engine and a
language hint. A name matcher transliterates Indian names, builds a simple
sound key, compares spellings, checks taught aliases first, and returns the
top three candidates. The LLM receives those names and a risky action needs an
extra confirmation when the match is weak or two guesses are close.

All speech engine code lives in `lib/services/speech_service.dart` and its two
Dart part files in the same folder, so an engine can be swapped in one place.

## Verified sources

- `sherpa_onnx` 2.0.3 on pub.dev: real package, Android arm64 supported,
  Apache-2.0, published 22 Nov 2026. Its Dart API was read from the installed
  package before use (`OfflineQwen3AsrModelConfig`, `VoiceActivityDetector`,
  `readWave`).
- sherpa-onnx Qwen3-ASR docs:
  `https://k2-fsa.github.io/sherpa/onnx/qwen3-asr/pretrained.html`
- Model release:
  `https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/sherpa-onnx-qwen3-asr-0.6B-int8-2026-03-25.tar.bz2`
  (879 MB). The release has **no individual files**, so the app downloads them
  from the matching verified Hugging Face mirror
  `csukuangfj2/sherpa-onnx-qwen3-asr-0.6B-int8-2026-03-25`.
- Silero VAD:
  `https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/silero_vad.onnx`
  (643,854 bytes), verified with an HTTP HEAD request.
- The model supports Hindi (`hi`), English (`en`) and 30+ other languages. The
  verified Dart config has **no language field**, so the language selector is a
  hint only. The UI says this plainly.

## Results

| # | Test | Commands used | Expected | Actual | Result | Screenshot |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | Install and launch | `adb install -r`, `am start -n .../.MainActivity` | App opens, no crash | App opened, Stage 1 brain ready, no fatal log | PASS | `s3b_home.png` |
| 2 | Settings screen | Tap the gear icon | Engine and language choices visible | Three cards: Speech engine, Language hint, Teach a name | PASS | `s3b_settings.png` |
| 3 | Engine choice | Open engine dropdown | Two named engines | `Sherpa offline (Qwen3-ASR)` and `Android offline recognizer` | PASS | `s3b_settings.png` |
| 4 | Language choice | Open language dropdown | Auto, Hindi and English plus model languages | 31 options shown, Auto selected | PASS | `s3b_settings.png` |
| 5 | Model download | Tap the microphone | All model files download with progress | 7 files downloaded: 44,148,281 / 182,491,662 / 755,914,231 / 1,671,853 / 12,487 / 2,776,833 / 643,854 bytes | PASS | - |
| 6 | Android storage permission | First debug audio test | App can read a pushed WAV from `/sdcard` | `READ_EXTERNAL_STORAGE` granted; `/sdcard/test_en.wav` transcribed | PASS | - |
| 7 | Debug audio broadcast | `am broadcast -a <pkg>.DEBUG_COMMAND --es audio_path /sdcard/test_en.wav` | Real STT engine transcribes the file | English rap sample transcribed, starting "Sometimes I just feel like..." | PASS | `s3b_debug_ui5.txt` |
| 8 | Debug text broadcast | `am broadcast ... --es text 'get the current time'` | Text command still runs | Latest result: "The current time is 6:50 AM on Wednesday, 25 November 2026." | PASS | `s3b_typed_regression2.txt` |
| 9 | Model load time | Cold start + debug audio | Reported from `debugPrint` | 5,323 ms and 5,444 ms on two cold runs | PASS | - |
| 10 | Recognition time | Same 18 s English sample | Reported from `debugPrint` | 26,154 ms with 2 threads, 24,946 ms with 4 threads | PASS (slow) | - |
| 11 | RAM after load | `dumpsys meminfo com.Sarthak.pocket_jinn` | Reported honestly | TOTAL PSS 3,085,506 kB, Native Heap 2,485,788 kB | PASS (high) | - |
| 12 | Devanagari name | `am broadcast ... --es name "सार्थक"` | Latin key matches `sarthak` | Matcher returned `sarthak:1.00` | PASS | `s3b_name_hi.txt` |
| 13 | Misspelled name | `am broadcast ... --es name "sarthik"` | Close name still matches | Matcher returned `sarthak:0.86` | PASS | `s3b_name_mis.txt` |
| 14 | Engine switching | Settings dropdown, both directions | Both engines select without crash | Android selected, Hindi hint chosen, then Sherpa restored, Auto restored | PASS | `s3b_engine_menu2.png`, `s3b_lang_menu.png` |
| 15 | Mic start/stop with Qwen3 | Tap mic, wait, tap again | No crash and state returns to idle | Red stop button appeared, then idle with "I did not catch that." | PASS (state only) | `s3b_mic3.png` |
| 16 | German sample | `DEBUG_COMMAND` with `de.wav` | Correct transcript | "Raptorium Bergbau scheint profitierter als Monroe..." — correct; decode 3,206 ms | PASS | `s3b_de.txt` |
| 17 | French sample | `DEBUG_COMMAND` with `fr1.wav` | Correct transcript | "Ali et moi sommes allés à Paris voyager en train au printemps..." — correct apart from one name; decode 2,610 ms | PASS | `s3b_fr1.wav_clean.txt` |
| 18 | Spanish sample | `DEBUG_COMMAND` with `es1.wav` | Correct transcript | "Esta prenda es amplia. Recomiendo elegir una talla menor al habitual." — correct; decode 2,208 ms | PASS | `s3b_es1.wav_clean.txt` |
| 19 | Japanese sample | `DEBUG_COMMAND` with `ja1.wav` | Correct transcript | Nonsensical place names ("Gazan, bishkek..."); decode 4,260 ms | FAIL (note below) | `s3b_ja1.wav_clean.txt` |
| 20 | Static checks | `dart format .`, `flutter analyze`, `flutter test` | Clean and passing | Formatter clean, "No issues found!", 6 of 6 tests | PASS | - |

## Fixes made after the first device pass

1. **Stuck on listening with no recognition.** The first VAD design only sent
   VAD-detected segments to the recognizer. If VAD never fired, no audio reached
   STT. Every audio chunk is now kept, and VAD is only used to stop recording.
   A spoken French clip played through the tablet speaker was then transcribed
   correctly after tapping stop: "Annie et moi sommes allés à Paris...".
2. The VAD threshold was lowered from 0.5 to 0.2, following the sherpa-onnx
   docs example, so quiet speech has a better chance of stopping recording
   automatically. It still did not auto-stop with speaker playback, so this
   remains unverified with a real voice.
3. The brain's system instruction now says to call a tool only when the command
   clearly asks for that action. Earlier arbitrary test audio wrongly produced
   a call request, which the confirmation dialog safely blocked.

## NOT VERIFIED — for the user to do

These rows need the user's own voice and contact list, which were not available
during this session. Nothing here is claimed as tested.

- Real microphone speech with Qwen3-ASR (only the start/stop state was checked).
- VAD end-of-speech stopping when a person stops talking.
- Hindi and other non-English spoken commands from the user's WAV files.
- Indian contact names, misspellings, Devanagari spellings and similar-sounding
  names from the user's list. Only one starter contact, `sarthak`, exists today.
- "Teach a name" two-recording flow with a real voice and the saved JSON aliases.
- The extra confirmation dialog when the best name score is low or two guesses
  are close.
- `AndroidSpeechEngine` on this tablet: the code path is written, but the device
  has no offline Google speech data, so a real offline recognition result was
  not obtained.
- Wake word: unchanged and not built yet; Stage 4 owns it.

## Notes and limits

- The Qwen3-ASR download is about 982 MB. It is kept in app-private storage and
  is not in git.
- Recognition takes about 25 seconds for an 18-second clip on this tablet. A
  short spoken command should be much faster, but this needs a real-voice test.
- Memory use is high (about 3 GB PSS). This is the cost of a 0.6B on-device ASR
  model and may not suit low-RAM phones.
- Transcription is reliable and fast on short European-language clips here:
  2.2–4.3 seconds for 6–20 second samples. An 18-second noisy English clip took
  about 25 seconds, so long audio is slow on this tablet.
- The Japanese test clip produced nonsense. The model lists Japanese as
  supported, but this device sample was not recognised correctly. This is a
  model limitation, not a crash.
- Arbitrary test audio sometimes made the brain request a call or SMS. The
  existing confirmation dialog appeared every time and was safely cancelled;
  no risky action ran during testing.
- The debug audio hook needs `READ_EXTERNAL_STORAGE` on Android 12 and
  `READ_MEDIA_AUDIO` on Android 13+. A pushed file can be passed as
  `/sdcard/file.wav` or an app-private path.
- Debug broadcast forms:
  - `adb shell am broadcast -a com.Sarthak.pocket_jinn.DEBUG_COMMAND --es audio_path /sdcard/test.wav`
  - `adb shell am broadcast -a com.Sarthak.pocket_jinn.DEBUG_COMMAND --es text "get the current time"`
  - `adb shell am broadcast -a com.Sarthak.pocket_jinn.DEBUG_COMMAND --es name "सार्थक"`
- `shots/*` screenshots are local only and are not committed.

## Honest summary

The Stage 3B engines, settings, debug hook and name matcher are implemented and
pass static checks. On the tablet, the 982 MB model downloaded, settings
switched engines and hints both ways, pushed German, French, Spanish and
English WAVs were transcribed by the real Qwen3-ASR engine, typed commands
still worked, Devanagari and a misspelled Latin name matched the test contact,
and timings and RAM were measured. Japanese was not recognised correctly, and
arbitrary audio sometimes triggered a confirmation dialog that was cancelled
safely. Accuracy for Hindi and Indian names from the user's own recordings,
all spoken-microphone flows, the teaching flow and the ambiguity confirmation
remain unverified until the user supplies the test data and speaks.
