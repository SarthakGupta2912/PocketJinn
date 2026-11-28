// What is this file for?
// After a phone restart or an app update, reminds the user to start listening
// again. Android 12 and newer do not allow a microphone service to start by
// itself from the background, so a tap-to-open notification is the honest
// fallback.
package com.Sarthak.pocket_jinn

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class BootReceiver : BroadcastReceiver() {
    /// Shows the resume reminder when the user had left listening switched on.
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_BOOT_COMPLETED &&
            intent.action != Intent.ACTION_MY_PACKAGE_REPLACED
        ) {
            return
        }
        if (!WakeWordService.wantsEnabled(context)) return
        WakeWordService.showResumeNotification(context)
        WakeWordService.scheduleWatchdog(context)
    }
}
