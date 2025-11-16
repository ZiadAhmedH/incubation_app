package com.example.incubation_app

import android.app.*
import android.content.Intent
import android.os.IBinder
import android.os.Build
import android.os.Handler
import android.os.Looper
import androidx.core.app.NotificationCompat

class FeedingForegroundService : Service() {

    companion object {
        const val CHANNEL_ID = "feeding_foreground_channel"
        const val NOTIFICATION_ID = 1001
    }

    private val handler = Handler(Looper.getMainLooper())
    private var feedingCountToday = 0
    private var lastDayKey: String? = null

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        startForeground(NOTIFICATION_ID, buildNotification("الخدمة بدأت"))

        // ابدأ التكرار (مثال: كل 15 دقيقة في الإنتاج، أو أقصر للـ Debug)
        startFeedingLoop()
    }

    private fun startFeedingLoop() {
        // Debug: كل 15 دقيقة (أو أقل لو عايز)
        val intervalMillis = 15 * 60 * 1000L

        handler.post(object : Runnable {
            override fun run() {
                val now = java.util.Calendar.getInstance()
                val dayKey = "${now.get(java.util.Calendar.YEAR)}-" +
                    "${now.get(java.util.Calendar.MONTH) + 1}-" +
                    "${now.get(java.util.Calendar.DAY_OF_MONTH)}"

                if (dayKey != lastDayKey) {
                    // يوم جديد
                    lastDayKey = dayKey
                    feedingCountToday = 0
                }

                if (feedingCountToday < 4) {
                    feedingCountToday += 1

                    // حدّث الـ notification text
                    val text = "وجبة التغذية ${feedingCountToday}/4 لليوم"
                    val notif = buildNotification(text)
                    val nm = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
                    nm.notify(NOTIFICATION_ID, notif)

                    // اطلق Broadcast أو PendingIntent
                    // عشان Flutter يقدر يشتغل لو app مفتوح
                    // لكن الأهم: نقدر هنا نستخدم Notification عادي
                    showFeedingNotification(feedingCountToday)
                }

                handler.postDelayed(this, intervalMillis)
            }
        })
    }

    private fun buildNotification(content: String): Notification {
        val pendingIntent: PendingIntent = Intent(
            this,
            MainActivity::class.java
        ).let { notificationIntent ->
            PendingIntent.getActivity(this, 0, notificationIntent,
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
        }

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("حضانة دودة القز")
            .setContentText(content)
            .setSmallIcon(R.mipmap.ic_launcher) // تأكد من الأيقونة
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .build()
    }

    private fun showFeedingNotification(feedingIndex: Int) {
        val nm = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
        val notif = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("🍃 وقت التغذية $feedingIndex/4")
            .setContentText("تأكد من تغذية دودة القز في هذا الوقت")
            .setSmallIcon(R.mipmap.ic_launcher)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .build()

        nm.notify(2000 + feedingIndex, notif)
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val name = "Feeding Foreground"
            val descriptionText = "قناة خدمة التغذية في الخلفية"
            val importance = NotificationManager.IMPORTANCE_LOW
            val channel = NotificationChannel(CHANNEL_ID, name, importance)
            channel.description = descriptionText
            val notificationManager: NotificationManager =
                getSystemService(NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }
}