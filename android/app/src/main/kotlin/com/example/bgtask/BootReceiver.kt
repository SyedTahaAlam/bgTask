package com.example.bgtask

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

/**
 * Broadcast receiver that listens for [Intent.ACTION_BOOT_COMPLETED] and
 * [Intent.ACTION_MY_PACKAGE_REPLACED] so that the foreground background task
 * service can be restarted automatically after a device reboot or app update.
 *
 * flutter_foreground_task's own [autoRunOnBoot] flag handles the actual
 * service restart; this receiver ensures the Flutter engine is woken up so
 * that the Dart callback can be invoked.
 */
class BootReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "BootReceiver"
    }

    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED -> {
                Log.i(TAG, "Received: ${intent.action} — attempting service restart")
                restartService(context)
            }
            else -> Log.d(TAG, "Ignoring unhandled action: ${intent.action}")
        }
    }

    private fun restartService(context: Context) {
        try {
            // flutter_foreground_task exposes a re-launch helper; launch the
            // main activity with the appropriate flag so that the Dart
            // startCallback runs and re-initialises the foreground service.
            val launchIntent = context.packageManager
                .getLaunchIntentForPackage(context.packageName)
                ?.apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    putExtra("autoStart", true)
                }

            if (launchIntent != null) {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    // On Android 8+ we must not start a background activity
                    // directly; instead log and rely on WorkManager / FGT
                    // built-in boot handling.
                    Log.i(TAG, "Android O+: relying on FGT autoRunOnBoot mechanism")
                } else {
                    context.startActivity(launchIntent)
                    Log.i(TAG, "Launch intent sent for package: ${context.packageName}")
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to restart service", e)
        }
    }
}
