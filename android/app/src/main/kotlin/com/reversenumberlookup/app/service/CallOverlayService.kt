package com.reversenumberlookup.app.service

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
import com.reversenumberlookup.app.R
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
        if (callerInfo != null) {
            tvName?.text = callerInfo.first
            tvLocation?.text = callerInfo.second
        } else {
            tvName?.text = "Unknown Caller"
            tvLocation?.text = ""
        }

        btnClose?.setOnClickListener {
            removeOverlay()
        }

        try {
            windowManager?.addView(overlayView, params)
        } catch (e: Exception) {}
    }

    private fun removeOverlay() {
        if (overlayView != null) {
            try {
                windowManager?.removeView(overlayView)
            } catch (e: Exception) {}
            overlayView = null
        }
        stopSelf()
    }

    private fun lookupNumber(phoneNumber: String): Pair<String, String>? {
        return try {
            val dbFile = File(filesDir.parentFile, "databases/app_database")
            if (!dbFile.exists()) return null
            val db = SQLiteDatabase.openDatabase(dbFile.absolutePath, null, SQLiteDatabase.OPEN_READONLY)
            val cursor = db.rawQuery("SELECT name, country FROM user_records WHERE phoneNumber = ? LIMIT 1", arrayOf(phoneNumber))
            var result: Pair<String, String>? = null
            if (cursor.moveToFirst()) {
                val name = cursor.getString(0) ?: "Unknown"
                val country = cursor.getString(1) ?: ""
                result = Pair(name, country)
            }
            cursor.close()
            db.close()
            result
        } catch (e: Exception) {
            null
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "caller_id_overlay",
                "Caller ID Overlay Service",
                NotificationManager.IMPORTANCE_LOW
            )
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        removeOverlay()
    }
}
