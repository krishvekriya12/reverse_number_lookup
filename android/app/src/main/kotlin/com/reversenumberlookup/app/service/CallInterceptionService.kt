package com.reversenumberlookup.app.service

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.telecom.Call
import android.telecom.CallScreeningService
import android.telephony.TelephonyManager
import android.util.Log
import androidx.core.app.NotificationCompat
import com.reversenumberlookup.app.MainActivity
import org.json.JSONArray
import org.json.JSONObject

class CallInterceptionService : CallScreeningService() {
    private val TAG = "CallInterception"

    override fun onScreenCall(callDetails: Call.Details) {
        Log.d(TAG, "onScreenCall Triggered")

        val rawNumber = getPhoneNumber(callDetails)
        var isIncoming = true
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            isIncoming = callDetails.callDirection == Call.Details.DIRECTION_INCOMING
        }

        if (!isIncoming || rawNumber.isEmpty()) {
            respondToCall(callDetails, buildAllowResponse())
            return
        }

        val match = checkShouldBlock(rawNumber)
        if (match != null) {
            val (ruleType, ruleValue, reason) = match
            Log.d(TAG, "Blocking call from: $rawNumber due to $reason")

            recordBlockHistory(rawNumber, ruleType, ruleValue, reason)
            showBlockedNotification(rawNumber, reason)

            val rejectResponse = CallResponse.Builder()
                .setDisallowCall(true)
                .setRejectCall(true)
                .setSkipCallLog(false)
                .setSkipNotification(true)
                .build()

            try {
                respondToCall(callDetails, rejectResponse)
            } catch (e: Exception) {
                Log.e(TAG, "respondToCall reject failed", e)
            }
        } else {
            startOverlayService(rawNumber, true)
            try {
                respondToCall(callDetails, buildAllowResponse())
            } catch (e: Exception) {
                Log.e(TAG, "respondToCall allow failed", e)
            }
        }
    }

    private fun checkShouldBlock(rawNumber: String): Triple<Int, String, String>? {
        try {
            val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val rulesJsonList = prefs.getStringSet("flutter.block_rules_list", null) ?: return null

            val cleanIncoming = rawNumber.filter { it.isDigit() }

            for (jsonStr in rulesJsonList) {
                val obj = JSONObject(jsonStr)
                val ruleType = obj.optInt("ruleType", -1)
                val ruleValue = obj.optString("ruleValue", "")
                val cleanRule = ruleValue.filter { it.isDigit() }

                when (ruleType) {
                    0 -> { // Exact Number
                        if (ruleValue.equals(rawNumber, ignoreCase = true) ||
                            (cleanRule.length >= 7 && cleanIncoming.endsWith(cleanRule))) {
                            return Triple(0, ruleValue, "Exact Number Match ($ruleValue)")
                        }
                    }
                    1 -> { // Starts With
                        if (ruleValue.isNotEmpty() && rawNumber.startsWith(ruleValue) ||
                            (cleanRule.isNotEmpty() && cleanIncoming.startsWith(cleanRule))) {
                            return Triple(1, ruleValue, "Starts With Match ($ruleValue)")
                        }
                    }
                    2 -> { // Country Code
                        val codeStr = if (ruleValue.startsWith("+")) ruleValue else "+$ruleValue"
                        val codeDigits = codeStr.filter { it.isDigit() }
                        if (rawNumber.startsWith(codeStr) || (codeDigits.isNotEmpty() && cleanIncoming.startsWith(codeDigits))) {
                            return Triple(2, ruleValue, "Country Code Match ($ruleValue)")
                        }
                    }
                    3 -> { // Caller Name
                        // If ruleValue matches keyword in caller name
                        return Triple(3, ruleValue, "Caller Name Match ($ruleValue)")
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error checking block rules", e)
        }
        return null
    }

    private fun recordBlockHistory(rawNumber: String, ruleType: Int, ruleValue: String, reason: String) {
        try {
            val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val currentHistory = prefs.getStringSet("flutter.block_history_list", mutableSetOf())?.toMutableList() ?: mutableListOf()

            val entry = JSONObject().apply {
                put("id", System.currentTimeMillis())
                put("blockedNumber", rawNumber)
                put("name", JSONObject.NULL)
                put("ruleType", ruleType)
                put("ruleValue", ruleValue)
                put("reason", reason)
                put("timestamp", System.currentTimeMillis())
            }

            currentHistory.add(0, entry.toString())
            prefs.edit().putStringSet("flutter.block_history_list", currentHistory.toSet()).apply()
        } catch (e: Exception) {
            Log.e(TAG, "Error recording block history", e)
        }
    }

    private fun showBlockedNotification(rawNumber: String, reason: String) {
        try {
            val channelId = "blocked_phone_calls_channel"
            val notificationManager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val channel = NotificationChannel(
                    channelId,
                    "Blocked Phone Calls",
                    NotificationManager.IMPORTANCE_DEFAULT
                )
                notificationManager.createNotificationChannel(channel)
            }

            val intent = Intent(this, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val pendingIntent = PendingIntent.getActivity(
                this, 0, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            val notification = NotificationCompat.Builder(this, channelId)
                .setSmallIcon(android.R.drawable.ic_dialog_alert)
                .setContentTitle("Call Blocked: $rawNumber")
                .setContentText(reason)
                .setPriority(NotificationCompat.PRIORITY_DEFAULT)
                .setContentIntent(pendingIntent)
                .setAutoCancel(true)
                .build()

            notificationManager.notify((System.currentTimeMillis() % Int.MAX_VALUE).toInt(), notification)
        } catch (e: Exception) {
            Log.e(TAG, "Error showing notification", e)
        }
    }

    private fun startOverlayService(rawNumber: String, isIncoming: Boolean) {
        val intent = Intent(this, CallOverlayService::class.java)
        intent.putExtra("EXTRA_PHONE", rawNumber)
        intent.putExtra("EXTRA_FROM_SCREENING", true)
        intent.putExtra("EXTRA_IS_INCOMING", isIncoming)

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                startForegroundService(intent)
            } else {
                startService(intent)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start overlay service", e)
        }
    }

    private fun buildAllowResponse(): CallResponse {
        return CallResponse.Builder()
            .setDisallowCall(false)
            .setRejectCall(false)
            .setSkipCallLog(false)
            .setSkipNotification(false)
            .build()
        }

    private fun getPhoneNumber(callDetails: Call.Details): String {
        return try {
            val handle: Uri? = callDetails.handle
            handle?.schemeSpecificPart ?: ""
        } catch (e: Exception) {
            ""
        }
    }
}
