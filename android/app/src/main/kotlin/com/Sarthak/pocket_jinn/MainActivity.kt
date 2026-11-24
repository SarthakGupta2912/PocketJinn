// What is this file for?
// Hosts the Flutter screen and runs the two approved phone actions. The number
// is fixed here, so a model mistake can never call or message anyone else.
package com.Sarthak.pocket_jinn

import android.Manifest
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
        private const val TEST_CONTACT_NAME = "sarthak"
        private const val TEST_CONTACT_NUMBER = "9023850632"
        private const val CALL_PERMISSION_REQUEST = 4101
        private const val SMS_PERMISSION_REQUEST = 4102
    }

    private var pendingResult: MethodChannel.Result? = null
    private var pendingAction: (() -> Unit)? = null

    /// Registers the small channel used by the Stage 2 call and SMS tools.
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL_NAME,
        ).setMethodCallHandler { call, result ->
            handleMethodCall(call, result)
        }
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
