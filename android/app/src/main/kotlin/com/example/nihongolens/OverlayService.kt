package com.example.nihongolens

import android.app.Service
import android.content.Intent
import android.graphics.Color
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

        subtitleView.textSize = 24f

        subtitleView.setTextColor(
            Color.WHITE
        )

        subtitleView.setBackgroundColor(
            Color.argb(
                160,
                0,
                0,
                0
            )
        )

        subtitleView.setPadding(
            50,
            30,
            50,
            30
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

        params.y = 180

        try {

            windowManager.addView(
                subtitleView,
                params
            )

        } catch (e: Exception) {

            e.printStackTrace()
        }
    }

    override fun onStartCommand(
        intent: Intent?,
        flags: Int,
        startId: Int
    ): Int {

        val subtitle =
            intent?.getStringExtra(
                "subtitle"
            )

        if (subtitle != null) {

            subtitleView.text =
                subtitle
        }

        return START_STICKY
    }

    override fun onDestroy() {

        super.onDestroy()

        try {

            windowManager.removeView(
                subtitleView
            )

        } catch (e: Exception) {

            e.printStackTrace()
        }
    }

    override fun onBind(
        intent: Intent?
    ): IBinder? {

        return null
    }
}
