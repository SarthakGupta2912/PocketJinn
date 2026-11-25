// What is this file for?
// Keeps the text, default values and fixed sizes used across Pocket Jinn in
// one place, so screens never repeat magic strings or magic numbers.

export 'voice_constants.dart';

export 'settings_constants.dart';

/// The name shown on the home screen, app bar and launcher.
const String appName = 'Pocket Jinn';

/// One short sentence that explains what the app does.
const String appTagline = 'Your private voice assistant that works offline';

/// The wake name used until the user changes it in settings.
const String defaultWakeName = 'Hey Jinn';

/// Label above the current wake name.
const String wakeNameLabel = 'Wake name';

/// Message shown when the assistant is idle and ready.
const String homeStatusReady = 'Ready';

/// Hint under the big microphone button.
const String homeMicrophoneHint = 'Tap the microphone to speak a command';

/// Short headline above the microphone button.
const String homeAskTitle = 'Ask Pocket Jinn';

/// Title of the recent commands card on the home screen.
const String homeHistoryTitle = 'Recent commands';

/// Text shown when no commands have been saved yet.
const String homeHistoryEmptyMessage =
    'Nothing here yet. Your latest commands will appear in this list.';

/// Title of the card that explains the three steps.
const String howItWorksTitle = 'How it works';

/// First explanation step: the user speaks.
const String howItWorksStepOne = '1. Say your wake name, then your command.';

/// Second explanation step: the on-device model understands the sentence.
const String howItWorksStepTwo =
    '2. A small on-device model turns it into a tool call.';

/// Third explanation step: the tool runs on the phone.
const String howItWorksStepThree =
    '3. Pocket Jinn runs the action, after asking before risky ones.';

/// Text on the microphone button for screen readers.
const String microphoneButtonLabel = 'Start listening';

/// Text command box hint for the local model stage.
const String commandFieldHint = 'Type a command for Pocket Jinn';

/// Label for the local model preparation action.
const String prepareBrainLabel = 'Prepare offline brain';

/// Label for the command submission action.
const String sendCommandLabel = 'Ask';

/// Text shown while the local model is being downloaded or loaded.
const String brainPreparingMessage = 'Preparing the offline brain...';

/// Text shown after the local model is ready.
const String brainReadyMessage = 'Offline brain ready';

/// Text shown before the first model preparation.
const String brainNotReadyMessage =
    'Prepare the offline brain to type commands.';

/// Text shown when a local model operation fails.
const String brainErrorMessage = 'The offline brain could not be prepared.';

/// Title used for the latest assistant result.
const String latestResultTitle = 'Latest result';

/// Most recent commands kept visible on the home screen.
const int maxVisibleRecentCommands = 5;

/// Android channel shared with MainActivity for real phone actions.
const String androidToolsChannelName = 'com.Sarthak.pocket_jinn/android_tools';

/// Channel used by native code to send debug broadcast events to Dart.
const String debugCallbackChannelName =
    'com.Sarthak.pocket_jinn/debug_callbacks';

/// The only contact Pocket Jinn may call or message in stage 2.
const String testContactName = 'sarthak';

/// The only phone number Pocket Jinn may call or message in stage 2.
const String testContactNumber = '9023850632';

/// Longest SMS text accepted from the model in stage 2.
const int maxSmsLength = 480;

/// Shown after the phone accepts a call request.
const String callStartedMessage = 'Calling sarthak at 9023850632.';

/// Shown when a call request could not start.
const String callFailedMessage = 'The call could not be started.';

/// Shown after Android accepts an SMS request for sending.
const String smsHandedOffMessage =
    'SMS handed to Android for sending to sarthak at 9023850632.';

/// Shown when an SMS request could not be sent.
const String smsFailedMessage = 'The SMS could not be sent.';

/// Shown when the model asks to send an empty SMS.
const String smsEmptyMessage = 'Type the SMS text first.';

/// Shown when the model asks for an SMS above the safe length.
const String smsTooLongMessage =
    'That SMS is too long. Keep it under $maxSmsLength characters.';

/// Fixed sizes shared by the layout and the common widgets.
class AppSizes {
  const AppSizes._();

  /// Smallest allowed touch target, recommended by Android.
  static const double minimumTouchTarget = 48;

  /// Widest content column on tablets, so lines stay easy to read.
  static const double contentMaxWidth = 700;

  /// Size of the round microphone button on a phone.
  static const double microphoneButtonPhone = 140;

  /// Size of the round microphone button on a tablet.
  static const double microphoneButtonTablet = 176;

  /// Icon takes this share of the microphone button width.
  static const double microphoneIconFraction = 0.38;

  /// Width of thin borders such as the status chip outline.
  static const double thinBorder = 1.2;

  /// Size of a small icon placed next to text.
  static const double smallIconSize = 18;

  /// Size of the loading spinner inside a button.
  static const double loadingIndicatorSize = 20;

  /// Thickness of the loading spinner line.
  static const double loadingIndicatorStroke = 2;

  /// Shadow depth of the microphone button.
  static const double microphoneElevation = 4;

  /// Size of the round badge on the welcome card.
  static const double welcomeBadgeSize = 56;

  /// Size of the icon inside the welcome badge.
  static const double welcomeBadgeIconSize = 28;

  /// Size of a normal icon such as the history clock.
  static const double mediumIconSize = 24;

  /// Width of the small download progress bar under the microphone.
  static const double voiceProgressWidth = 220;
}
