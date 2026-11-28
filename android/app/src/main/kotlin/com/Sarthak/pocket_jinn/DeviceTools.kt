// What is this file for?
// Small, local Android helpers for the safe Tier 1 tools. They never use the
// network and they never touch the test contact.
package com.Sarthak.pocket_jinn

import android.content.Context
import android.content.Intent
import android.os.BatteryManager
import android.provider.AlarmClock

/// Reads battery state and hands an alarm request to the system clock app.
object DeviceTools {
    /// Returns battery percent and charging state, or null if Android has none.
    fun batteryLevel(context: Context): Map<String, Any>? {
        val battery = context.registerReceiver(
            null,
            android.content.IntentFilter(Intent.ACTION_BATTERY_CHANGED),
        ) ?: return null
        val level = battery.getIntExtra(BatteryManager.EXTRA_LEVEL, -1)
        val scale = battery.getIntExtra(BatteryManager.EXTRA_SCALE, -1)
        if (level < 0 || scale <= 0) return null
        val percent = (level * 100) / scale
        val plugged = battery.getIntExtra(BatteryManager.EXTRA_PLUGGED, 0)
        val status = battery.getIntExtra(BatteryManager.EXTRA_STATUS, -1)
        val charging = plugged != 0 ||
            status == BatteryManager.BATTERY_STATUS_CHARGING ||
            status == BatteryManager.BATTERY_STATUS_FULL
        return mapOf("percent" to percent, "charging" to charging)
    }

    /// Opens the system clock's "add alarm" page with safe, validated values.
    /// Returns a short message, or throws when no clock app can handle it.
    fun setAlarm(context: Context, hour: Int, minute: Int, label: String): String {
        val intent = Intent(AlarmClock.ACTION_SET_ALARM).apply {
            putExtra(AlarmClock.EXTRA_HOUR, hour)
            putExtra(AlarmClock.EXTRA_MINUTES, minute)
            putExtra(AlarmClock.EXTRA_MESSAGE, label.take(40))
            putExtra(AlarmClock.EXTRA_SKIP_UI, false)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        if (context.packageManager.resolveActivity(intent, 0) == null) {
            throw IllegalStateException("This device has no clock app for alarms.")
        }
        context.startActivity(intent)
        return "Opening the clock to set an alarm for " +
            "%02d:%02d".format(hour, minute) + "."
    }
}
