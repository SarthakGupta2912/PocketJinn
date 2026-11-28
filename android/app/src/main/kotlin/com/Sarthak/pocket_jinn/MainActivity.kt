// What is this file for?
// Hosts the Flutter screen and runs the two approved phone actions. The number
// is fixed here, so a model mistake can never call or message anyone else.
package com.Sarthak.pocket_jinn

import android.Manifest
import android.content.Context
import android.os.Build
import android.icu.text.Transliterator
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.telephony.SmsManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL_NAME = "com.Sarthak.pocket_jinn/android_tools"
        private const val DEBUG_CHANNEL_NAME =
            "com.Sarthak.pocket_jinn/debug_callbacks"
        private const val TEST_CONTACT_NAME = "sarthak"
        private const val TEST_CONTACT_NUMBER = "9023850632"
        private const val CALL_PERMISSION_REQUEST = 4101
        private const val SMS_PERMISSION_REQUEST = 4102
        private const val NOTIFICATION_PERMISSION_REQUEST = 4106
    }

    private var pendingResult: MethodChannel.Result? = null
    private var pendingAction: (() -> Unit)? = null
    private var pendingNotificationResult: MethodChannel.Result? = null
    private var speechBridge: AndroidSpeechBridge? = null

    /// Returns the one engine shared with the background service.
    override fun provideFlutterEngine(context: Context): FlutterEngine {
        return PocketJinnEngine.get(context)
    }

    /// Registers the small channel used by the Stage 2 call and SMS tools.
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val channel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL_NAME,
        )
        val debugChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            DEBUG_CHANNEL_NAME,
        )
        speechBridge = AndroidSpeechBridge(this, channel, debugChannel)
        channel.setMethodCallHandler { call, result ->
            handleMethodCall(call, result)
        }
        WakeBridge.attach(flutterEngine, this)
        speechBridge?.registerDebugReceiver()
        requestTestAudioPermission()
    }

    /// Asks once for access to pushed test WAV files in shared storage.
    private fun requestTestAudioPermission() {
        val permission = if (Build.VERSION.SDK_INT >= 33) {
            Manifest.permission.READ_MEDIA_AUDIO
        } else {
            Manifest.permission.READ_EXTERNAL_STORAGE
        }
        if (checkSelfPermission(permission) != PackageManager.PERMISSION_GRANTED) {
            requestPermissions(arrayOf(permission), 4103)
        }
    }

    /// Remembers when the app is on screen and reads a wake notification tap.
    override fun onResume() {
        super.onResume()
        WakeBridge.isVisible = true
        consumeWakeExtra(intent)
    }

    /// Marks the app hidden so the wake alert can be shown instead.
    override fun onPause() {
        WakeBridge.isVisible = false
        super.onPause()
    }

    /// Reads a wake notification tap while the activity already exists.
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        consumeWakeExtra(intent)
    }

    /// Turns the wake extra into a pending wake and clears it from the intent.
    private fun consumeWakeExtra(intent: Intent?) {
        if (intent?.getBooleanExtra(WakeWordService.WAKE_EXTRA, false) == true) {
            WakeBridge.pendingWake = true
            intent.removeExtra(WakeWordService.WAKE_EXTRA)
        }
    }

    /// Releases the speech recognizer when the activity is destroyed.
    override fun onDestroy() {
        speechBridge?.dispose()
        speechBridge = null
        WakeBridge.detachActivity(this)
        super.onDestroy()
    }

    /// Asks for notification access on Android 13 and newer.
    fun requestNotificationPermission(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < 33 ||
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) ==
            PackageManager.PERMISSION_GRANTED
        ) {
            result.success(true)
            return
        }
        if (pendingNotificationResult != null) {
            result.error("BUSY", "Another permission request is already open.", null)
            return
        }
        pendingNotificationResult = result
        requestPermissions(
            arrayOf(Manifest.permission.POST_NOTIFICATIONS),
            NOTIFICATION_PERMISSION_REQUEST,
        )
    }

    /// Chooses the action for one Flutter method call.
    private fun handleMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "callTestContact" ->
                runWithPermission(
                    Manifest.permission.CALL_PHONE,
                    CALL_PERMISSION_REQUEST,
                    result,
                ) { placeTestCall(result) }

            "sendSmsToTestContact" -> {
                val message = call.argument<String>("message")?.trim().orEmpty()
                if (message.isEmpty()) {
                    result.error("EMPTY_MESSAGE", "Type the SMS text first.", null)
                    return
                }
                runWithPermission(
                    Manifest.permission.SEND_SMS,
                    SMS_PERMISSION_REQUEST,
                    result,
                ) { sendTestSms(message, result) }
            }

            "isAndroidSpeechAvailable" ->
                result.success(speechBridge?.isAvailable() ?: false)

            "startAndroidSpeech" -> {
                speechBridge?.start(call.argument<String>("languageCode").orEmpty())
                result.success(true)
            }

            "stopAndroidSpeech" -> {
                speechBridge?.stop()
                result.success(true)
            }

            "transliterate" -> {
                val text = call.argument<String>("text").orEmpty()
                val latin = try {
                    Transliterator.getInstance("Any-Latin; Latin-ASCII")
                        .transliterate(text)
                } catch (error: Exception) {
                    text
                }
                result.success(latin)
            }

            "batteryLevel" -> {
                val battery = DeviceTools.batteryLevel(this)
                if (battery == null) {
                    result.error("NO_BATTERY", "Battery state is unavailable.", null)
                } else {
                    result.success(battery)
                }
            }

            "setAlarm" -> {
                val hour = call.argument<Int>("hour") ?: -1
                val minute = call.argument<Int>("minute") ?: -1
                val label = call.argument<String>("label").orEmpty()
                if (hour !in 0..23 || minute !in 0..59) {
                    result.error("BAD_TIME", "Use an hour from 0 to 23 and a minute from 0 to 59.", null)
                } else {
                    try {
                        result.success(DeviceTools.setAlarm(this, hour, minute, label))
                    } catch (error: Exception) {
                        result.error("ALARM_FAILED", error.message ?: "No clock app.", null)
                    }
                }
            }

            else -> result.notImplemented()
        }
    }

    /// Runs an action now or after the user answers the Android permission box.
    private fun runWithPermission(
        permission: String,
        requestCode: Int,
        result: MethodChannel.Result,
        action: () -> Unit,
    ) {
        if (checkSelfPermission(permission) == PackageManager.PERMISSION_GRANTED) {
            action()
            return
        }
        if (pendingResult != null) {
            result.error("BUSY", "Another permission request is already open.", null)
            return
        }
        pendingResult = result
        pendingAction = action
        requestPermissions(arrayOf(permission), requestCode)
    }

    /// Continues the saved action when the user allows the permission.
    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == NOTIFICATION_PERMISSION_REQUEST) {
            val notificationResult = pendingNotificationResult
            pendingNotificationResult = null
            notificationResult?.success(
                grantResults.isNotEmpty() &&
                    grantResults[0] == PackageManager.PERMISSION_GRANTED,
            )
            return
        }
        val result = pendingResult ?: return
        val action = pendingAction
        pendingResult = null
        pendingAction = null
        if (grantResults.isNotEmpty() &&
            grantResults[0] == PackageManager.PERMISSION_GRANTED &&
            action != null
        ) {
            action()
        } else {
            result.error(
                "PERMISSION_DENIED",
                "Phone permission is needed to call or message $TEST_CONTACT_NAME.",
                null,
            )
        }
    }

    /// Places a call to the one approved test contact.
    private fun placeTestCall(result: MethodChannel.Result) {
        try {
            val dialIntent = Intent(
                Intent.ACTION_CALL,
                Uri.parse("tel:$TEST_CONTACT_NUMBER"),
            )
            startActivity(dialIntent)
            result.success("Calling $TEST_CONTACT_NAME at $TEST_CONTACT_NUMBER.")
        } catch (error: Exception) {
            result.error(
                "CALL_FAILED",
                error.message ?: "The call could not be started.",
                null,
            )
        }
    }

    /// Sends one SMS, splitting it into parts when Android requires that.
    private fun sendTestSms(message: String, result: MethodChannel.Result) {
        val smsManager = getSystemService(SmsManager::class.java)
        if (smsManager == null) {
            result.error("SMS_UNAVAILABLE", "This device cannot send SMS.", null)
            return
        }
        try {
            val parts = smsManager.divideMessage(message)
            if (parts.size == 1) {
                smsManager.sendTextMessage(
                    TEST_CONTACT_NUMBER,
                    null,
                    message,
                    null,
                    null,
                )
            } else {
                smsManager.sendMultipartTextMessage(
                    TEST_CONTACT_NUMBER,
                    null,
                    parts,
                    null,
                    null,
                )
            }
            result.success(
                "SMS handed to Android for sending to $TEST_CONTACT_NAME " +
                    "at $TEST_CONTACT_NUMBER.",
            )
        } catch (error: Exception) {
            result.error(
                "SMS_FAILED",
                error.message ?: "The SMS could not be sent.",
                null,
            )
        }
    }
}
