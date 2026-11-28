// What is this file for?
// Keeps the Stage 4 wake-word model details, keyword tokens, timings and
// messages in one place, so the detector and the card never repeat them.

/// Folder under app support storage that holds the wake-word model files.
const String wakeFolderName = 'sherpa-kws-gigaspeech';

/// Asset folder that ships the verified keyword-spotting model.
const String wakeAssetFolder = 'assets/wake_model';

/// The five model files copied out of the app assets on first use.
const List<String> wakeModelFileNames = [
  'encoder-epoch-12-avg-2-chunk-16-left-64.int8.onnx',
  'decoder-epoch-12-avg-2-chunk-16-left-64.onnx',
  'joiner-epoch-12-avg-2-chunk-16-left-64.int8.onnx',
  'tokens.txt',
  'bpe.model',
];

/// Exact byte sizes of the five files, checked after copying them.
const List<int> wakeModelFileSizes = [4807159, 1063189, 163380, 5006, 244837];

/// BPE tokens for "HEY JINN", encoded with the model's own bpe.model.
/// The \u2581 character is the SentencePiece word-boundary marker.
const String wakeKeywordTokens = '\u2581HE Y \u2581 J IN N';

/// Name of the keywords file written beside the copied model.
const String wakeKeywordsFileName = 'keywords.txt';

/// Score added to each keyword token. 3.0 catches the phrase across voices
/// without triggering on "Hey Siri", noise or the official test WAVs.
const double wakeKeywordScore = 3.0;

/// Acoustic probability needed before a keyword is accepted.
const double wakeKeywordThreshold = 0.25;

/// Sample rate the keyword model expects.
const int wakeSampleRate = 16000;

/// How long to ignore a second detection after one wake.
const Duration wakeRepeatDelay = Duration(seconds: 4);

/// How long to wait for the app to open before the detector resumes.
const Duration wakeOpenTimeout = Duration(seconds: 20);

/// How long the background worker may take to load its model.
const Duration wakeWorkerLoadTimeout = Duration(seconds: 20);

/// Name of the small file that remembers whether the user turned it on.
const String wakeSettingsFileName = 'wake_word_enabled.txt';

/// Method channel shared with the Android foreground service.
const String wakeChannelName = 'com.Sarthak.pocket_jinn/wake_word';

/// Message names sent between the app and the wake worker.
const String wakeAudioMessage = 'audio';
const String wakeFeedFileMessage = 'feed_file';
const String wakeFeedDoneMessage = 'feed_done';
const String wakeStopMessage = 'stop';
const String wakeDisposeMessage = 'dispose';
const String wakeReadyMessage = 'ready';
const String wakeDetectedMessage = 'wake';
const String wakeErrorMessage = 'error';

/// Title of the wake-word card.
const String wakeTitle = 'Wake word';

/// Label beside the on/off switch.
const String wakeToggleLabel = 'Listen for "Hey Jinn" in the background';

/// Honest explanation of the notification and the background behaviour.
const String wakeNote =
    'A small offline model listens behind a microphone notification. When the '
    'app is in the background, tap the notification after saying it.';

/// Shown while the model files are copied and loaded.
const String wakePreparingMessage = 'Preparing the wake word...';

/// Shown while the detector is running.
const String wakeListeningMessage = 'Listening for "Hey Jinn".';

/// Shown while a normal voice command owns the microphone.
const String wakePausedMessage =
    'Wake word paused while the microphone is open.';

/// Shown when the user turns the wake word off.
const String wakeOffMessage = 'Wake word is off.';

/// Shown when the microphone permission is missing.
const String wakePermissionMessage =
    'Microphone permission is needed for the wake word.';

/// Shown when the model assets cannot be prepared.
const String wakeModelMessage = 'The wake word model could not be prepared.';

/// Shown when the Android foreground service cannot start.
const String wakeServiceMessage = 'The background wake word could not start.';

/// Shown when Android will not show the wake-word notification.
const String wakeNotificationMessage =
    'Allow notifications so the wake word can tell you when it hears you.';

/// Shown after a background detection while the user taps the notification.
const String wakeBackgroundMessage =
    'Heard "Hey Jinn". Tap the notification to speak.';

/// How often the detector tells the Android service it is still alive.
const Duration wakeHeartbeatInterval = Duration(seconds: 10);

/// Start of the status line while the detector is running.
const String wakeStatusListening = 'Listening: yes';

/// Status line while the detector is off.
const String wakeStatusStopped = 'Listening: no';

/// Status line while the model files are loading.
const String wakeStatusStarting = 'Listening: starting';

/// Status line while a voice command owns the microphone.
const String wakeStatusPaused = 'Listening: paused';

/// Joins the "yes" status with the start time.
const String wakeStatusSince = 'since';

/// Title of the always-on help screen.
const String onboardingTitle = 'Keep Pocket Jinn listening';

/// Short explanation at the top of the help screen.
const String onboardingIntro =
    'Pocket Jinn listens for "Hey Jinn" with an offline model behind a small '
    'microphone notification. Android can still stop it to save battery. These '
    'steps help it stay on.';

/// Heading for the notification step.
const String onboardingNotificationsTitle = '1. Allow notifications';

/// Explanation for the notification step.
const String onboardingNotificationsNote =
    'Android needs notifications for the microphone indicator and for telling '
    'you when "Hey Jinn" was heard.';

/// Heading for the battery step.
const String onboardingBatteryTitle = '2. Allow background running';

/// Explanation for the battery step.
const String onboardingBatteryNote =
    'Turn off battery optimisation for Pocket Jinn so Android does not stop the '
    'listener while the screen is off.';

/// Heading for the auto-start step.
const String onboardingAutoStartTitle = '3. Allow auto-start';

/// Explanation for the auto-start step.
const String onboardingAutoStartNote =
    'Some phones stop apps after a restart. Open your phone maker\'s auto-start '
    'page and allow Pocket Jinn.';

/// Honest note about what Android does not allow.
const String onboardingHonestNote =
    'Android does not allow a microphone service to start by itself at boot or '
    'from the background. After a restart or a swipe-away, Pocket Jinn shows a '
    'reminder; tap it to start listening again.';

/// Button that closes the help screen.
const String onboardingDoneButton = 'Done';

/// Button that opens the battery settings page.
const String onboardingOpenBatteryButton = 'Open battery settings';

/// Button that opens the manufacturer auto-start page.
const String onboardingOpenAutoStartButton = 'Open auto-start settings';

/// Button that opens this app's information page.
const String onboardingOpenAppInfoButton = 'Open app info';

/// Button that asks for notification access.
const String onboardingAllowNotificationsButton = 'Allow notifications';

/// Shown when battery optimisation is already off.
const String onboardingBatteryAlreadyAllowed =
    'Battery optimisation is already off for Pocket Jinn.';

/// Shown when battery optimisation is still on.
const String onboardingBatteryStillOn =
    'Battery optimisation is still on. Open the settings and choose '
    '"Don\'t optimise".';

/// Shown after a settings page opens.
const String onboardingActionOpened = 'Settings opened.';

/// Shown when a settings page cannot open.
const String onboardingActionFailed =
    'This phone did not open that page. Use app info instead.';

/// Shown after notifications are allowed.
const String onboardingNotificationAllowed = 'Notifications are allowed.';

/// Shown when notifications are still blocked.
const String onboardingNotificationBlocked =
    'Notifications are still blocked. Allow them in app info.';
