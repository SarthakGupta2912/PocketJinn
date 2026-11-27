// What is this file for?
// Keeps Pocket Jinn alive in the background with a small microphone
// notification, so the offline "Hey Jinn" detector can keep listening.
package com.Sarthak.pocket_jinn

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.IBinder

class WakeWordService : Service() {
    companion object {
        /// Low-importance channel for the ongoing service notification.
        private const val SERVICE_CHANNEL_ID = "pocket_jinn_wake_service"

        /// High-importance channel for the "I heard you" notification.
        private const val ALERT_CHANNEL_ID = "pocket_jinn_wake_alert"

        /// Extra that tells MainActivity a wake notification was tapped.
        const val WAKE_EXTRA = "wake_pending"

        private const val SERVICE_NOTIFICATION_ID = 4104
        private const val ALERT_NOTIFICATION_ID = 4105

        /// True while the foreground service is running.
        var isRunning = false
            private set

        /// Starts the foreground service from the visible app.
        fun start(context: Context) {
            val intent = Intent(context, WakeWordService::class.java)
            context.startForegroundService(intent)
        }

        /// Stops the foreground service and its ongoing notification.
        fun stop(context: Context) {
            context.stopService(Intent(context, WakeWordService::class.java))
        }

        /// Shows the tap-to-speak notification after a background wake.
        fun showWakeNotification(context: Context) {
            val manager =
                context.getSystemService(NotificationManager::class.java) ?: return
            manager.notify(ALERT_NOTIFICATION_ID, buildAlert(context))
        }

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
    }

    /// Creates the two channels and shows the ongoing notification.
    override fun onCreate() {
        super.onCreate()
        createChannels()
        startForeground(
            SERVICE_NOTIFICATION_ID,
            buildService(this),
            ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE,
        )
        isRunning = true
    }

    /// Does not restart on its own, because the Flutter detector would be gone.
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        return START_NOT_STICKY
    }

    /// Remembers that the service is no longer running.
    override fun onDestroy() {
        isRunning = false
        super.onDestroy()
    }

    /// The service is not bound.
    override fun onBind(intent: Intent?): IBinder? = null

    /// Creates a quiet channel for the service and a loud one for the alert.
    private fun createChannels() {
        val manager = getSystemService(NotificationManager::class.java) ?: return
        val serviceChannel = NotificationChannel(
            SERVICE_CHANNEL_ID,
            "Wake word",
            NotificationManager.IMPORTANCE_LOW,
        )
        serviceChannel.description = "Keeps the offline \"Hey Jinn\" detector running."
        manager.createNotificationChannel(serviceChannel)

        val alertChannel = NotificationChannel(
            ALERT_CHANNEL_ID,
            "Wake word alerts",
            NotificationManager.IMPORTANCE_HIGH,
        )
        alertChannel.description = "Tells you when \"Hey Jinn\" was heard."
        manager.createNotificationChannel(alertChannel)
    }
}
