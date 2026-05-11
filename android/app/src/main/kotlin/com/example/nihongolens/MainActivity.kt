package com.example.nihongolens

import android.content.Intent
import android.media.projection.MediaProjectionManager
import android.os.Bundle
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "nihongo_lens/audio"
    private val REQUEST_CODE = 1001

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->

                if (call.method == "startCapture") {
                    startAudioCapture()
                    result.success(true)
                } else {
                    result.notImplemented()
                }
            }
    }

    private fun startAudioCapture() {
        val mediaProjectionManager =
            getSystemService(MEDIA_PROJECTION_SERVICE)
                    as MediaProjectionManager

        startActivityForResult(
            mediaProjectionManager.createScreenCaptureIntent(),
            REQUEST_CODE
        )
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        if (requestCode == REQUEST_CODE && data != null) {
            val intent = Intent(this, AudioCaptureService::class.java)
            intent.putExtra("resultCode", resultCode)
            intent.putExtra("data", data)
            startForegroundService(intent)
        }
    }
}
