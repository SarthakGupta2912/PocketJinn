// What is this file for?
// A repeating safety check. If the user left listening switched on but the
// service is no longer running, shows one reminder instead of staying silent.
package com.Sarthak.pocket_jinn

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class WatchdogReceiver : BroadcastReceiver() {
    /// Checks the switch and the service, then reminds the user if needed.
    override fun onReceive(context: Context, intent: Intent) {
        if (!WakeWordService.wantsEnabled(context)) {
            WakeWordService.cancelWatchdog(context)
            return
        }
        if (WakeWordService.isRunning) return
        WakeWordService.showResumeNotification(context)
    }
}
