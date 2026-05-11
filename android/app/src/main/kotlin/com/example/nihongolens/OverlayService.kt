package com.example.nihongolens

import android.app.Service
import android.content.Intent
import android.graphics.PixelFormat
import android.os.IBinder
import android.view.Gravity
import android.view.WindowManager
import android.widget.TextView

class OverlayService : Service() {

    private lateinit var windowManager: WindowManager
    private lateinit var subtitleView: TextView

    override fun onCreate() {
        super.onCreate()

        windowManager =
            getSystemService(WINDOW_SERVICE)
                    as WindowManager

        subtitleView = TextView(this)

        subtitleView.text =
            "Waiting for Japanese audio..."

        subtitleView.textSize = 22f

        subtitleView.setTextColor(
            android.graphics.Color.WHITE
        )

        subtitleView.setBackgroundColor(
            android.graphics.Color.argb(
                180,
                0,
                0,
                0
            )
        )

        subtitleView.setPadding(
            40,
            20,
            40,
            20
        )

        val params =
            WindowManager.LayoutParams(
                WindowManager.LayoutParams.WRAP_CONTENT,
                WindowManager.LayoutParams.WRAP_CONTENT,

                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,

                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE
                        or WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,

                PixelFormat.TRANSLUCENT
            )

        params.gravity =
            Gravity.BOTTOM or Gravity.CENTER_HORIZONTAL

        params.y = 200

        windowManager.addView(
            subtitleView,
            params
        )
    }

    override fun onStartCommand(
        intent: Intent?,
        flags: Int,
        startId: Int
    ): Int {

        val text =
            intent?.getStringExtra("subtitle")

        if (text != null) {
            subtitleView.text = text
        }

        return START_STICKY
    }

    override fun onDestroy() {
        super.onDestroy()

        windowManager.removeView(subtitleView)
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }
}
