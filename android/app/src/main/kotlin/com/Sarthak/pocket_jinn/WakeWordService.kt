// What is this file for?
// Keeps Pocket Jinn alive in the background with a small microphone
// notification, so the offline "Hey Jinn" detector can keep listening. It also
// remembers the user's choice, watches for a silent stop and helps after a
// reboot.
package com.Sarthak.pocket_jinn

import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import android.os.SystemClock
import androidx.core.content.ContextCompat

class WakeWordService : Service() {
    companion object {
        /// Low-importance channel for the ongoing service notification.
        private const val SERVICE_CHANNEL_ID = "pocket_jinn_wake_service"

        /// High-importance channel for the "I heard you" notification.
        private const val ALERT_CHANNEL_ID = "pocket_jinn_wake_alert"

        /// Medium-importance channel for "listening stopped" reminders.
        private const val STATUS_CHANNEL_ID = "pocket_jinn_wake_status"

        /// Extra that tells MainActivity a wake notification was tapped.
        const val WAKE_EXTRA = "wake_pending"

        private const val SERVICE_NOTIFICATION_ID = 4104
        private const val ALERT_NOTIFICATION_ID = 4105
        private const val RESUME_NOTIFICATION_ID = 4106

        private const val PREFS_NAME = "pocket_jinn_wake"
        private const val KEY_ENABLED = "wake_enabled"
        private const val WATCHDOG_REQUEST = 4107

        /// How often the watchdog checks that the detector is still alive.
        private const val WATCHDOG_INTERVAL_MS = 15 * 60 * 1000L

        /// How long the detector may stay silent after a swipe-away.
        private const val HEARTBEAT_GRACE_MS = 25_000L

        /// True while the foreground service is running.
        @Volatile
        var isRunning = false
            private set

        /// When the current listening session began, in wall-clock millis.
        @Volatile
        var startedAtMillis = 0L
            private set

        /// Last time the Dart detector reported that it was still alive.
        @Volatile
        private var lastHeartbeatMillis = 0L

        /// Starts the foreground service from the visible app.
        fun start(context: Context) {
            val intent = Intent(context, WakeWordService::class.java)
            ContextCompat.startForegroundService(context, intent)
        }

        /// Stops the foreground service and its ongoing notification.
        fun stop(context: Context) {
            context.stopService(Intent(context, WakeWordService::class.java))
        }

        /// True when the user left the wake word switched on.
        fun wantsEnabled(context: Context): Boolean {
            return prefs(context).getBoolean(KEY_ENABLED, false)
        }

        /// Saves the user's choice and starts or stops the watchdog.
        fun setWantsEnabled(context: Context, enabled: Boolean) {
            prefs(context).edit().putBoolean(KEY_ENABLED, enabled).apply()
            if (enabled) {
                scheduleWatchdog(context)
            } else {
                cancelWatchdog(context)
            }
        }

        /// Marks the Dart detector as alive.
        fun noteHeartbeat() {
            lastHeartbeatMillis = System.currentTimeMillis()
        }

        /// Shows the tap-to-speak notification after a background wake.
        fun showWakeNotification(context: Context) {
            ensureChannels(context)
            val manager =
                context.getSystemService(NotificationManager::class.java) ?: return
            manager.notify(ALERT_NOTIFICATION_ID, buildAlert(context))
        }

        /// Tells the user that listening stopped and how to start it again.
        fun showResumeNotification(context: Context) {
            ensureChannels(context)
            val manager =
                context.getSystemService(NotificationManager::class.java) ?: return
            manager.notify(RESUME_NOTIFICATION_ID, buildResume(context))
        }

        /// Creates the quiet, loud and reminder channels when needed.
        fun ensureChannels(context: Context) {
            val manager =
                context.getSystemService(NotificationManager::class.java) ?: return
            val serviceChannel = NotificationChannel(
                SERVICE_CHANNEL_ID,
                "Wake word",
                NotificationManager.IMPORTANCE_LOW,
            )
            serviceChannel.description =
                "Keeps the offline \"Hey Jinn\" detector running."
            manager.createNotificationChannel(serviceChannel)

            val alertChannel = NotificationChannel(
                ALERT_CHANNEL_ID,
                "Wake word alerts",
                NotificationManager.IMPORTANCE_HIGH,
            )
            alertChannel.description = "Tells you when \"Hey Jinn\" was heard."
            manager.createNotificationChannel(alertChannel)

            val statusChannel = NotificationChannel(
                STATUS_CHANNEL_ID,
                "Wake word reminders",
                NotificationManager.IMPORTANCE_DEFAULT,
            )
            statusChannel.description = "Tells you when listening stopped."
            manager.createNotificationChannel(statusChannel)
        }

        /// Schedules a repeating check that the detector did not stop silently.
        fun scheduleWatchdog(context: Context) {
            val alarm = context.getSystemService(AlarmManager::class.java) ?: return
            val intent = Intent(context, WatchdogReceiver::class.java)
            val pending = PendingIntent.getBroadcast(
                context,
                WATCHDOG_REQUEST,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            alarm.setInexactRepeating(
                AlarmManager.ELAPSED_REALTIME_WAKEUP,
                SystemClock.elapsedRealtime() + WATCHDOG_INTERVAL_MS,
                WATCHDOG_INTERVAL_MS,
                pending,
            )
        }

        /// Stops the repeating watchdog.
        fun cancelWatchdog(context: Context) {
            val alarm = context.getSystemService(AlarmManager::class.java) ?: return
            val intent = Intent(context, WatchdogReceiver::class.java)
            val pending = PendingIntent.getBroadcast(
                context,
                WATCHDOG_REQUEST,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            alarm.cancel(pending)
        }

        /// Returns the small private file that remembers the switch.
        private fun prefs(context: Context) =
            context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

        /// Builds an intent that opens the app, with a flag only for the alert.
        private fun openApp(context: Context, isWake: Boolean): PendingIntent {
            val intent = Intent(context, MainActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
                if (isWake) putExtra(WAKE_EXTRA, true)
            }
            return PendingIntent.getActivity(
                context,
                if (isWake) ALERT_NOTIFICATION_ID else SERVICE_NOTIFICATION_ID,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
        }

        /// The small ongoing notification that keeps the detector alive.
        private fun buildService(context: Context): Notification {
            return Notification.Builder(context, SERVICE_CHANNEL_ID)
                .setSmallIcon(android.R.drawable.ic_btn_speak_now)
                .setContentTitle("Pocket Jinn is listening")
                .setContentText("Say \"Hey Jinn\" to start a command.")
                .setContentIntent(openApp(context, isWake = false))
                .setOngoing(true)
                .setCategory(Notification.CATEGORY_SERVICE)
                .build()
        }

        /// The alert shown when a wake happens while the app is hidden.
        private fun buildAlert(context: Context): Notification {
            return Notification.Builder(context, ALERT_CHANNEL_ID)
                .setSmallIcon(android.R.drawable.ic_btn_speak_now)
                .setContentTitle("Pocket Jinn heard you")
                .setContentText("Tap to speak your command.")
                .setContentIntent(openApp(context, isWake = true))
                .setAutoCancel(true)
                .setCategory(Notification.CATEGORY_MESSAGE)
                .build()
        }

        /// The reminder shown after a silent stop or a reboot.
        private fun buildResume(context: Context): Notification {
            return Notification.Builder(context, STATUS_CHANNEL_ID)
                .setSmallIcon(android.R.drawable.ic_btn_speak_now)
                .setContentTitle("Wake word is off")
                .setContentText("Tap to start listening for \"Hey Jinn\" again.")
                .setContentIntent(openApp(context, isWake = false))
                .setAutoCancel(true)
                .setCategory(Notification.CATEGORY_REMINDER)
                .build()
        }
    }

    private val handler = Handler(Looper.getMainLooper())
    private var wakeLock: PowerManager.WakeLock? = null

    /// Creates the channels, holds the CPU awake and shows the notification.
    override fun onCreate() {
        super.onCreate()
        ensureChannels(this)
        startedAtMillis = System.currentTimeMillis()
        lastHeartbeatMillis = startedAtMillis
        wakeLock = getSystemService(PowerManager::class.java)
            ?.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "PocketJinn:wake")
            ?.apply {
                setReferenceCounted(false)
                acquire()
            }
        try {
            startForeground(
                SERVICE_NOTIFICATION_ID,
                buildService(this),
                ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE,
            )
            isRunning = true
        } catch (error: Exception) {
            isRunning = false
            showResumeNotification(this)
            stopSelf()
        }
    }

    /// Keeps the service alive, but never pretends after a cold restart.
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (!isRunning) return START_NOT_STICKY
        if (intent == null) {
            // Android restarted the service after the app process died, so the
            // Flutter detector is gone. Ask the user to open the app again.
            showResumeNotification(this)
            stopSelf()
            return START_NOT_STICKY
        }
        return START_STICKY
    }

    /// Checks shortly after a swipe-away that the detector is still alive.
    override fun onTaskRemoved(rootIntent: Intent?) {
        handler.postDelayed({
            if (!isRunning) return@postDelayed
            val age = System.currentTimeMillis() - lastHeartbeatMillis
            if (age > HEARTBEAT_GRACE_MS) {
                showResumeNotification(this)
                stopSelf()
            }
        }, HEARTBEAT_GRACE_MS)
        super.onTaskRemoved(rootIntent)
    }

    /// Releases the CPU lock and remembers that the service stopped.
    override fun onDestroy() {
        isRunning = false
        handler.removeCallbacksAndMessages(null)
        wakeLock?.let { lock ->
            if (lock.isHeld) lock.release()
        }
        wakeLock = null
        super.onDestroy()
    }

    /// The service is not bound.
    override fun onBind(intent: Intent?): IBinder? = null
}
