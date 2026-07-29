package com.example.reverse_number_lookup.service

import android.content.Context
import android.content.Intent
import android.database.sqlite.SQLiteDatabase
import android.net.Uri
import android.telecom.Call
import android.telecom.CallScreeningService
import android.util.Log
import java.io.File

class CallInterceptionService : CallScreeningService() {
    private val TAG = "CallInterception"

    override fun onScreenCall(callDetails: Call.Details) {
        val phoneNumber = getPhoneNumber(callDetails)
        val isIncoming = callDetails.callDirection == Call.Details.DIRECTION_INCOMING

        Log.d(TAG, "Screening call: $phoneNumber, Incoming: $isIncoming")

        if (phoneNumber.isEmpty()) {
            respondToCall(callDetails, buildAllowResponse())
            return
        }

        if (isIncoming) {
            val isBlocked = checkIsBlocked(phoneNumber)
            if (isBlocked) {
                Log.d(TAG, "Blocking call from: $phoneNumber")
                val rejectResponse = CallResponse.Builder()
                    .setDisallowCall(true)
                    .setRejectCall(true)
                    .setSkipCallLog(false)
                    .setSkipNotification(true)
                    .build()
                respondToCall(callDetails, rejectResponse)
            } else {
                startOverlayService(phoneNumber, isIncoming)
                respondToCall(callDetails, buildAllowResponse())
            }
        } else {
            startOverlayService(phoneNumber, false)
            respondToCall(callDetails, buildAllowResponse())
        }
    }

    private fun checkIsBlocked(number: String): Boolean {
        try {
            val dbFolder = getDir("flutter", Context.MODE_PRIVATE)
            val dbFile = File(dbFolder, "numtrace.db")
            if (!dbFile.exists()) return false

            val db = SQLiteDatabase.openDatabase(dbFile.absolutePath, null, SQLiteDatabase.OPEN_READONLY)
            var blocked = false

            db.rawQuery("SELECT ruleValue, ruleType FROM block_rules", null).use { cursor ->
                while (cursor.moveToNext()) {
                    val ruleValue = cursor.getString(0) ?: continue
                    val ruleType = cursor.getInt(1)
                    
                    if (ruleType == 0 && number.endsWith(ruleValue)) blocked = true
                    if (ruleType == 1 && number.startsWith(ruleValue)) blocked = true
                    // Simplified checks for demo. A complete port would match the Dart logic.
                }
            }
            db.close()
            return blocked
        } catch (e: Exception) {
            Log.e(TAG, "DB Check error", e)
            return false
        }
    }

    private fun startOverlayService(rawNumber: String, isIncoming: Boolean) {
        val intent = Intent(this, CallOverlayService::class.java).apply {
            putExtra("EXTRA_PHONE", rawNumber)
            putExtra("EXTRA_IS_INCOMING", isIncoming)
        }
        try {
            startService(intent) // Start as standard service since overlay permission covers UI
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
            Log.e(TAG, "Error parsing number", e)
            ""
        }
    }
}
