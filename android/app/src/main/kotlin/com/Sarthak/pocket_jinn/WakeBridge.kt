// What is this file for?
// Handles the small wake-word channel for the whole app process. It uses the
// application context, so the background detector keeps working after the
// activity is destroyed by a swipe-away.
package com.Sarthak.pocket_jinn

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/// Connects the wake-word methods to the service, notifications and settings.
object WakeBridge {
    private const val CHANNEL_NAME = "com.Sarthak.pocket_jinn/wake_word"

    private var channel: MethodChannel? = null
    private var engine: FlutterEngine? = null
    private var appContext: Context? = null

    /// True while the app activity is on screen.
    @Volatile
    var isVisible = false

    /// True when a wake notification was tapped and not handled yet.
    @Volatile
    var pendingWake = false

    /// The current activity, used only for the notification permission box.
    private var activity: MainActivity? = null

    /// Registers the channel once for the shared engine.
    fun attach(newEngine: FlutterEngine, newActivity: MainActivity) {
        appContext = newActivity.applicationContext
        activity = newActivity
        if (engine === newEngine && channel != null) return
        engine = newEngine
        channel = MethodChannel(newEngine.dartExecutor.binaryMessenger, CHANNEL_NAME)
        channel?.setMethodCallHandler { call, result -> handle(call, result) }
    }

    /// Forgets the activity when it is destroyed, but keeps the channel alive.
    fun detachActivity(activity: MainActivity) {
        if (this.activity === activity) this.activity = null
    }

    /// Chooses the action for one wake-word method call.
    private fun handle(call: MethodCall, result: MethodChannel.Result) {
        val context = appContext
        if (context == null) {
            result.error("NO_CONTEXT", "The app is not ready yet.", null)
            return
        }
        when (call.method) {
            "startService" -> startService(context, result)
            "stopService" -> {
                WakeWordService.stop(context)
                result.success(true)
            }

            "notifyWake" -> {
                if (isVisible) {
                    result.success("foreground")
                } else {
                    WakeWordService.showWakeNotification(context)
                    result.success("background")
                }
            }

            "takePendingWake" -> {
                val wasPending = pendingWake
                pendingWake = false
                result.success(wasPending)
            }

            "serviceStatus" -> result.success(
                mapOf(
                    "running" to WakeWordService.isRunning,
                    "sinceMillis" to WakeWordService.startedAtMillis,
                    "wantsEnabled" to WakeWordService.wantsEnabled(context),
                ),
            )

            "setWakeEnabled" -> {
                val enabled = call.argument<Boolean>("enabled") ?: false
                WakeWordService.setWantsEnabled(context, enabled)
                result.success(true)
            }

            "heartbeat" -> {
                WakeWordService.noteHeartbeat()
                result.success(true)
            }

            "requestNotificationPermission" -> {
                val current = activity
                if (current == null) {
                    result.success(true)
                } else {
                    current.requestNotificationPermission(result)
                }
            }

            "openSettingsPage" -> {
                val page = call.argument<String>("page").orEmpty()
                result.success(KeepAliveSettings.open(context, page))
            }

            "isIgnoringBatteryOptimizations" ->
                result.success(KeepAliveSettings.isIgnoringBatteryOptimizations(context))

            else -> result.notImplemented()
        }
    }

    /// Starts the microphone service, checking the microphone permission first.
    private fun startService(context: Context, result: MethodChannel.Result) {
        val granted = ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.RECORD_AUDIO,
        ) == PackageManager.PERMISSION_GRANTED
        if (!granted) {
            result.error(
                "NO_MIC",
                "Microphone permission is needed for the wake word.",
                null,
            )
            return
        }
        try {
            WakeWordService.start(context)
            result.success(true)
        } catch (error: Exception) {
            result.error(
                "SERVICE_FAILED",
                error.message ?: "The wake word service could not start.",
                null,
            )
        }
    }
}
