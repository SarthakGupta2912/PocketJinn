# Stage 8 test report — always-on assistant (Part 1 and Part 2)

Date: 28 November 2026
Device: Samsung SM-T865 (Galaxy Tab S6), Android 12, wireless ADB
App id: `com.Sarthak.pocket_jinn`, debug build installed with `adb install -r`
Build checks: `dart format .` clean, `flutter analyze` no issues, `flutter test`
14/14 pass, `flutter build apk --debug` succeeds.

## What this stage adds

### Part 1 — name matching in any script

- `NameMatcher` behind a `NameAliasSource` interface, with a testable built-in
  Devanagari-to-Latin fallback when Android ICU transliteration is not available.
- Exact, whole-word, and sound-key tiers, plus prefix-only partial matching and
  cleanup of `th` and trailing `h` sounds.
- Fake-contact fixtures and 24 spoken forms in `test/`, with no real contacts,
  numbers or recordings in the repository.
- Debug logcat lines for the name check and for test transcripts.

### Part 2 — always-on wake listener

- One shared `FlutterEngine` (`PocketJinnEngine`) so the Dart wake isolate
  survives an activity swipe-away.
- A context-only `WakeBridge`, so the wake channel, notifications and settings
  work without an activity.
- `WakeWordService` hardened with `START_STICKY`, a partial wake lock, a saved
  `wantsEnabled` flag, a 15-minute watchdog and honest resume reminders.
- `BootReceiver` and `WatchdogReceiver` for restart and silent-stop reminders.
- A visible status line ("Listening: yes, since 07:18") and a 10-second
  heartbeat from Dart to the Android service.
- An onboarding/help screen with notification, battery, auto-start and app-info
  deep links, plus an honest note that Android cannot start a microphone service
  from boot or from the background.
- An app-scoped, debug-only broadcast receiver, so test audio can still be fed
  after the activity is destroyed.

## Device results

| Test | How it was run | Result |
| --- | --- | --- |
| App launches with shared engine | `am start`, screenshot, `dumpsys window` | PASS — home screen visible, no crash |
| Saved switch restores listening | relaunch with saved `wake_word_enabled.txt=true` | PASS — service foreground, status line "Listening: yes, since 07:18" |
| Status line | screenshot of Settings wake card | PASS — shows start time |
| Always-on help opens | tapped "Open always-on help" | PASS — help screen with three steps |
| Notification deep link | tapped "Allow notifications" | PASS — status "Notifications are allowed." |
| Battery deep link | tapped "Open battery settings" | PASS — Android dialog "Stop optimising battery usage?" |
| Battery exemption applied | tapped "Allow" in Android dialog | PASS — package in `dumpsys deviceidle whitelist`; help screen refreshed to "already off" |
| Auto-start deep link | tapped "Open auto-start settings" | PASS — safe fallback to app info on Samsung; status "Settings opened." |
| Swipe-away survival | recents swipe; `dumpsys activity activities`, `dumpsys activity services` | PASS — task removed, service still foreground, detector still emitting audio chunks |
| No false stop reminder after swipe-away | `dumpsys notification --noredact` | PASS — only ongoing notification 4104 |
| Background wake after swipe-away | debug broadcast with `wake_path /sdcard/wake_hey_jinn.wav` | PASS — logcat "Wake detected: HEY JINN", alert notification 4105 posted |
| Alert tap resumes listening | tapped "Pocket Jinn heard you" in shade | PASS — app opened, models loaded, normal listening started |
| Watchdog scheduled | `dumpsys alarm` | PASS — `*walarm*:.../.WatchdogReceiver`, repeat 900000 ms |
| Watchdog on healthy service | `am broadcast -n .../.WatchdogReceiver` | PASS — no reminder while `isRunning=true` |
| Long-running detector | logcat after several hours | PASS — wake audio chunks still flowing |
| Name matching, 24 spoken forms | `flutter test test/name_matcher_test.dart` | PASS — TOP-1 24/24, TOP-3 24/24 |
| Real owner contact list and misspellings | needs the owner's data | NOT VERIFIED (waiting for owner data) |
| Owner's personal Hindi/English WAVs | needs the owner's recordings | NOT VERIFIED (waiting for owner data) |
| Speaker-to-microphone spoken "Hey Jinn" | tablet echo cancellation blocks this | NOT VERIFIED (needs a real human voice) |
| Call/SMS delivery | tablet has no SIM/network | NOT VERIFIED (no SIM) |
| Screen-off listening | tablet re-locked on screen-off | NOT VERIFIED (waiting for owner to unlock / disable lock) |
| Reboot resume notification | Android blocks simulated `BOOT_COMPLETED` from shell | NOT VERIFIED (needs a real reboot) |
| Silent-stop reminder after process death | shell cannot kill a foreground app; `am stopservice` is rejected | NOT VERIFIED |

## Honest limits

- Android 12+ does not allow a microphone foreground service to start from the
  background or at boot. The app therefore posts a tap-to-open reminder instead
  of silently restarting the microphone.
- A cached Flutter engine keeps the detector alive after a swipe-away, but the
  system can still kill the process under extreme memory pressure. The watchdog
  and the resume notification are the honest fallback, not a promise of 100%
  uptime.
- The boot receiver, battery exemption and auto-start pages are best-effort:
  each phone maker can change or remove those settings pages.
- Synthetic WAV checks use file feeds, not a real microphone. They validate the
  model and the handoff, not real spoken audio.

## Remaining work

- Finish the locked-device checks when the owner unlocks the tablet (or
  temporarily sets Screen lock to None): screen-off listening, real reboot, and
  the silent-stop reminder.
- Stage 8 Part 3: one file per tool, one line in the registry, unit tests and a
  debug-broadcast test per tool, in Tier 1 → 2 → 3 order.
