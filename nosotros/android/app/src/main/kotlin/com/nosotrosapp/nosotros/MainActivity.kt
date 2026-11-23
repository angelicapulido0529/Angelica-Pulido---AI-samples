package com.nosotrosapp.nosotros

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Canal para los avisos de stories nuevas y likes.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "stories", "Stories y likes", NotificationManager.IMPORTANCE_HIGH,
            ).apply { description = "Cuando tu pareja sube una story o le da like a la tuya" }
            getSystemService(NotificationManager::class.java)
                .createNotificationChannel(channel)
        }
    }
}
