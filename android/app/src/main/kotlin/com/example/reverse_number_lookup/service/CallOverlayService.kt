package com.example.reverse_number_lookup.service

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.database.sqlite.SQLiteDatabase
import android.graphics.PixelFormat
import android.os.Build
import android.os.IBinder
import android.view.Gravity
import android.view.LayoutInflater
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.TextView
import androidx.core.app.NotificationCompat
import com.example.reverse_number_lookup.R
import java.io.File

class CallOverlayService : Service() {
    private var windowManager: WindowManager? = null
    private var overlayView: View? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
        createNotificationChannel()
        val notification = NotificationCompat.Builder(this, "caller_id_overlay")
            .setContentTitle("Caller ID Active")
            .setContentText("Monitoring incoming calls")
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .build()
        startForeground(1, notification)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val phoneNumber = intent?.getStringExtra("EXTRA_PHONE") ?: return START_NOT_STICKY
        showOverlay(phoneNumber)
        return START_NOT_STICKY
    }

    private fun showOverlay(phoneNumber: String) {
        if (overlayView != null) return

        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY else WindowManager.LayoutParams.TYPE_PHONE,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED,
            PixelFormat.TRANSLUCENT
        )
        params.gravity = Gravity.TOP or Gravity.CENTER_HORIZONTAL
        params.y = 100

        val inflater = getSystemService(LAYOUT_INFLATER_SERVICE) as LayoutInflater
        overlayView = inflater.inflate(R.layout.overlay_caller_info, null)

        val tvName = overlayView?.findViewById<TextView>(R.id.tv_caller_name)
        val tvNumber = overlayView?.findViewById<TextView>(R.id.tv_caller_number)
        val tvLocation = overlayView?.findViewById<TextView>(R.id.tv_caller_location)
        val btnClose = overlayView?.findViewById<Button>(R.id.btn_close)

        tvNumber?.text = phoneNumber
        
        val callerInfo = lookupNumber(phoneNumber)
        tvName?.text = callerInfo.first
        tvLocation?.text = callerInfo.second

        btnClose?.setOnClickListener {
            stopSelf()
        }

        windowManager?.addView(overlayView, params)
    }

    private fun lookupNumber(number: String): Pair<String, String> {
        try {
            val dbFolder = getDir("flutter", Context.MODE_PRIVATE)
            val dbFile = File(dbFolder, "numtrace.db")
            if (!dbFile.exists()) return Pair("Unknown", "Not in database")

            val db = SQLiteDatabase.openDatabase(dbFile.absolutePath, null, SQLiteDatabase.OPEN_READONLY)
            var name = "Unknown"
            var location = ""
            // Drift table for user_records is used here
            db.rawQuery("SELECT name, country FROM user_records WHERE phoneNumber = ? OR phoneNumber LIKE ?", arrayOf(number, "%$number")).use { cursor ->
                if (cursor.moveToFirst()) {
                    name = cursor.getString(0) ?: "Unknown"
                    location = cursor.getString(1) ?: ""
                }
            }
            db.close()
            return Pair(name, location)
        } catch (e: Exception) {
            return Pair("Unknown", "Error")
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "caller_id_overlay",
                "Caller ID Overlay",
                NotificationManager.IMPORTANCE_LOW
            )
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        if (overlayView != null) {
            windowManager?.removeView(overlayView)
            overlayView = null
        }
    }
}
