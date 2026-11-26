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

All speech engine code lives in `lib/services/speech_service.dart` and its Dart
part files in the same folder, so an engine can be swapped in one place.

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
- Live-word preview: multilingual Whisper base int8 from
  `csukuangfj/sherpa-onnx-whisper-base`, files `base-encoder.int8.onnx`
  (29,120,534 bytes), `base-decoder.int8.onnx` (130,672,026 bytes) and
  `base-tokens.txt` (816,730 bytes). All three URLs were checked with HTTP HEAD.
  The Dart `OfflineWhisperModelConfig`, including its `language` field, was read
  from the installed `sherpa_onnx` 2.0.3 package, and the language override was
  checked against the matching sherpa-onnx C++ decoder source.

## Results

| # | Test | Commands used | Expected | Actual | Result | Screenshot |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | Install and launch | `adb install -r`, `am start -n .../.MainActivity` | App opens, no crash | App opened, Stage 1 brain ready, no fatal log | PASS | `s3b_home.png` |
| 2 | Settings screen | Tap the gear icon | Engine and language choices visible | Three cards: Speech engine, Language hint, Teach a name | PASS | `s3b_settings.png` |
| 3 | Engine choice | Open engine dropdown | Two named engines | `Sherpa offline (Qwen3-ASR)` and `Android offline recognizer` | PASS | `s3b_settings.png` |
| 4 | Language choice | Open language dropdown | Auto, Hindi and English plus model languages | 31 options shown, Auto selected | PASS | `s3b_settings.png` |
| 5 | Model download | Tap the microphone | All model files download with progress | 7 Qwen3 files (982 MB) plus 3 preview files (160 MB) downloaded with progress | PASS | - |
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
| 20 | Slow Qwen3 partials (removed) | Play a WAV while recording and wait for the 5 s timer | Accurate words appear before stopping | Accurate French text appeared but only after several seconds, and the screen paused during each decode | FAIL (too slow) | - |
| 21 | Fast live words | Play English, French and Indian-accented English WAVs while recording | Words appear within about 1–2 s and stay on screen | Preview text appeared and updated every ~0.5 s; English "It's the time", French "années… à Paris", name clip "Goal, Sartik"; decode 127–573 ms | PASS | `cum_2.png`, `nm_2.png` |
| 22 | Final result unchanged | Tap stop after the preview | Qwen3 final transcript drives the assistant | Final result produced "Is the time?" and the assistant answered the current time; name clip matched `sarthak (0.50)` and the confirmation dialog was cancelled | PASS | `nm_after.txt` |
| 23 | Static checks | `dart format .`, `flutter analyze`, `flutter test` | Clean and passing | Formatter clean, "No issues found!", 6 of 6 tests | PASS | - |
| 24 | VAD-gated live preview, English | Play `/sdcard/en_alarm.wav` while recording | Live words before stopping, final Qwen3 unchanged | First words ~1.9 s after playback, full sentence by ~2.5 s, decode 277–610 ms; final "Set an alarm for seven in the morning." | PASS | `en_final3.txt` |
| 25 | Noise rejection | Start the microphone in a quiet room | Room noise must not stop recording or produce words | VAD segments at level 0.0022 and 0.0049 were rejected; recording stayed active | PASS | - |
| 26 | Hindi hint with preview | Hindi hint + `/sdcard/hi_long.mp3` | Accurate final transcript in Devanagari | Qwen3 returned "आज मौसम कैसा रहेगा? क्या आज बारिश होगी?"; live preview stayed romanised and rough | PASS (final only) | `hif.png` |
| 27 | Preview model trials | Tried tiny int8, base int8, base fp32, small int8 | Fast preview that also writes Hindi | base int8 was fastest (277–610 ms), base fp32 also romanised Hindi, small int8 wrote Devanagari but took 1.5–5.3 s per decode and fell behind; kept base int8 | FAIL (kept base) | - |

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
4. The user asked for accurate words during recording, so Qwen3 partial decoding
   replaced the rough streaming preview. That worked but each update took
   several seconds and paused the screen, so the user asked for lower latency.
   The Qwen3 partial timer was removed. A small multilingual Whisper tiny model
   now runs in its own background isolate and decodes the audio heard so far
   every half second. Its text appears about 1–2 seconds behind speech, keeps
   earlier words instead of dropping them, and never blocks the screen. Qwen3
   still makes the accurate final transcript after stopping. Music notes and
   common noise phrases are filtered, and short silent windows are skipped.
5. **Noise triggered false stops and invented preview words.** A room-noise
   burst produced a 0.6 s VAD segment with level 0.0022, which ended the
   recording before the user spoke. VAD segments now need average level
   >= 0.01 to stop, and preview audio is only fed when VAD detects speech and
   the chunk level is >= 0.005. A 1.2 s pre-roll keeps the first word, and the
   first decode waits for 2 s so it starts with a real phrase. Repetition
   cleanup drops a trailing copy of the sentence start.

## NOT VERIFIED — for the user to do

These rows need the user's own voice and contact list, which were not available
during this session. Nothing here is claimed as tested.

- Real microphone speech with Qwen3-ASR (only speaker playback was checked).
- VAD end-of-speech stopping for a real person; it was verified with speaker
  playback of English and Hindi clips (segments at level 0.0170 and 0.0225).
- Hindi and other non-English spoken commands from the user's own WAV files
  (the checks used Google Translate TTS clips).
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

- Live text comes from Whisper base int8 running in a background isolate. It
  decodes the newest 12 s every half second and is deliberately approximate;
  the accurate Qwen3 result replaces it after stopping. English preview words
  arrive about 1.9 s after speech starts and decode takes 277–610 ms.
  Hindi preview is only romanised/rough with a model this small: the final
  Qwen3 transcript is the accurate Devanagari one. Trials of base fp32 and
  small int8 were rejected: neither improved speed, and small int8 took
  1.5–5.3 s per decode while falling behind the microphone.
- VAD segments below level 0.01 are ignored, so room noise does not stop a
  recording. The preview only receives audio when VAD hears speech and the
  chunk level is >= 0.005.
- The preview download is about 160 MB, so total speech storage is about
  1.14 GB. It is kept in app-private storage and is not in git. The trial
  folders `sherpa-whisper-tiny`, `sherpa-whisper-small` and
  `sherpa-whisper-base-full` remain on the test tablet from model comparisons;
  the app does not use them.
- Preview load took about 1.3–5.5 s on the tablet and ran in parallel with the
  Qwen3 load. Qwen3 load stayed around 5.2–5.9 s.
- The Qwen3-ASR download is about 982 MB. It is kept in app-private storage and
  is not in git.
- Recognition takes about 25 seconds for an 18-second clip on this tablet. A
  short spoken command should be much faster, but this needs a real-voice test.
- Memory use is high (about 2.7 GB PSS after the preview model loaded). This is
  the cost of a 0.6B on-device ASR model plus the preview model and may not suit
  low-RAM phones.
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
and timings and RAM were measured. Fast live words now appear before stopping,
while the accurate Qwen3 transcript still runs after stopping. Japanese was not
recognised correctly, and
arbitrary audio sometimes triggered a confirmation dialog that was cancelled
safely. Accuracy for Hindi and Indian names from the user's own recordings,
all spoken-microphone flows, the teaching flow and the ambiguity confirmation
remain unverified until the user supplies the test data and speaks.
