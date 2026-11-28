// What is this file for?
// Opens the Android pages that keep an always-on app alive: battery
// optimisation, app info, notification settings and the manufacturer
// auto-start page. Every page is opened with a safe fallback.
package com.Sarthak.pocket_jinn

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.PowerManager
import android.provider.Settings

/// Opens the settings pages used by the onboarding screen.
object KeepAliveSettings {
    /// Manufacturer auto-start pages, tried from top to bottom.
    private val autoStartPages = listOf(
        "com.samsung.android.lool" to
            "com.samsung.android.sm.ui.battery.BatteryActivity",
        "com.miui.securitycenter" to
            "com.miui.permcenter.autostart.AutoStartManagementActivity",
        "com.coloros.safecenter" to
            "com.coloros.safecenter.permission.startup.StartupAppListActivity",
        "com.oppo.safe" to
            "com.oppo.safe.permission.startup.StartupAppListActivity",
        "com.vivo.permissionmanager" to
            "com.vivo.permissionmanager.activity.BgStartUpManagerActivity",
        "com.oneplus.security" to
            "com.oneplus.security.chainlaunch.view.ChainLaunchAppListActivity",
        "com.huawei.systemmanager" to
            "com.huawei.systemmanager.startupmgr.ui.StartupNormalAppListActivity",
    )

    /// Opens one page and returns true when Android accepted the request.
    fun open(context: Context, page: String): Boolean {
        val intent = when (page) {
            "battery" -> batteryIntent(context)
            "batteryList" -> Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
            "appDetails" -> appDetailsIntent(context)
            "notifications" -> notificationIntent(context)
            "autoStart" -> autoStartIntent(context)
            else -> null
        } ?: return false
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        return try {
            context.startActivity(intent)
            true
        } catch (error: Exception) {
            // Some phones reject the direct battery dialog, so open the list.
            if (page == "battery") openBatteryList(context) else false
        }
    }

    /// Opens the battery optimisation list as a safe fallback.
    private fun openBatteryList(context: Context): Boolean {
        val intent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        return try {
            context.startActivity(intent)
            true
        } catch (error: Exception) {
            false
        }
    }

    /// True when Android already lets Pocket Jinn ignore battery savings.
    fun isIgnoringBatteryOptimizations(context: Context): Boolean {
        val power = context.getSystemService(PowerManager::class.java) ?: return false
        return power.isIgnoringBatteryOptimizations(context.packageName)
    }

    /// Asks Android to show the battery exemption dialog for this app.
    private fun batteryIntent(context: Context): Intent {
        return Intent(
            Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS,
            Uri.parse("package:${context.packageName}"),
        )
    }

    /// Opens this app's own information page.
    private fun appDetailsIntent(context: Context): Intent {
        return Intent(
            Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
            Uri.parse("package:${context.packageName}"),
        )
    }

    /// Opens this app's notification settings page.
    private fun notificationIntent(context: Context): Intent {
        return Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
            .putExtra(Settings.EXTRA_APP_PACKAGE, context.packageName)
    }

    /// Opens the first manufacturer auto-start page that exists on this phone.
    private fun autoStartIntent(context: Context): Intent {
        for ((packageName, className) in autoStartPages) {
            val intent = Intent().setComponent(ComponentName(packageName, className))
            if (context.packageManager.resolveActivity(intent, 0) != null) {
                return intent
            }
        }
        return appDetailsIntent(context)
    }
}
