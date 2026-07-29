package com.example.reverse_number_lookup

import android.app.Activity
import android.app.role.RoleManager
import android.content.Context
import android.content.Intent
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.reverse_number_lookup/caller_id"
    private val REQUEST_ID = 1
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkCallScreeningRole" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                        val roleManager = getSystemService(Context.ROLE_SERVICE) as RoleManager
                        result.success(roleManager.isRoleHeld(RoleManager.ROLE_CALL_SCREENING))
                    } else {
                        result.success(true) // Pre-Q doesn't need this role
                    }
                }
                "requestCallScreeningRole" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                        val roleManager = getSystemService(Context.ROLE_SERVICE) as RoleManager
                        if (roleManager.isRoleHeld(RoleManager.ROLE_CALL_SCREENING)) {
                            result.success(true)
                        } else {
                            val intent = roleManager.createRequestRoleIntent(RoleManager.ROLE_CALL_SCREENING)
                            pendingResult = result
                            startActivityForResult(intent, REQUEST_ID)
                        }
                    } else {
                        result.success(true)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQUEST_ID) {
            val isGranted = resultCode == Activity.RESULT_OK
            pendingResult?.success(isGranted)
            pendingResult = null
        }
    }
}
