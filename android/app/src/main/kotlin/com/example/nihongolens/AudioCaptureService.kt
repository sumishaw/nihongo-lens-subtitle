package com.example.nihongolens

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.media.*
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.os.Build
import android.os.IBinder
import android.util.Log

class AudioCaptureService : Service() {

    private var mediaProjection: MediaProjection? = null
    private var audioRecord: AudioRecord? = null

    override fun onStartCommand(
        intent: Intent?,
        flags: Int,
        startId: Int
    ): Int {

        createNotification()

        val resultCode =
            intent?.getIntExtra("resultCode", -1) ?: -1

        val data =
            intent?.getParcelableExtra<Intent>("data")

        val projectionManager =
            getSystemService(MEDIA_PROJECTION_SERVICE)
                    as MediaProjectionManager

        mediaProjection =
            projectionManager.getMediaProjection(
                resultCode,
                data!!
            )

        startAudioCapture()

        return START_STICKY
    }

    private fun startAudioCapture() {

        val config =
            AudioPlaybackCaptureConfiguration.Builder(
                mediaProjection!!
            )
                .addMatchingUsage(AudioAttributes.USAGE_MEDIA)
                .addMatchingUsage(AudioAttributes.USAGE_GAME)
                .build()

        val sampleRate = 16000

        val channelConfig =
            AudioFormat.CHANNEL_IN_MONO

        val audioFormat =
            AudioFormat.ENCODING_PCM_16BIT

        val bufferSize =
            AudioRecord.getMinBufferSize(
                sampleRate,
                channelConfig,
                audioFormat
            )

        audioRecord =
            AudioRecord.Builder()
                .setAudioFormat(
                    AudioFormat.Builder()
                        .setEncoding(audioFormat)
                        .setSampleRate(sampleRate)
                        .setChannelMask(channelConfig)
                        .build()
                )
                .setBufferSizeInBytes(bufferSize)
                .setAudioPlaybackCaptureConfig(config)
                .build()

        audioRecord?.startRecording()

        Thread {

            val buffer = ByteArray(bufferSize)

            while (true) {

                val read =
                    audioRecord?.read(
                        buffer,
                        0,
                        buffer.size
                    )

                Log.d(
                    "NIHONGO_LENS",
                    "Captured Audio Bytes: $read"
                )

                // NEXT STEP:
                // Speech recognition
                // Translation
                // Floating subtitles
            }

        }.start()
    }

    private fun createNotification() {

        val channelId = "nihongo_audio"

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {

            val channel =
                NotificationChannel(
                    channelId,
                    "Nihongo Lens",
                    NotificationManager.IMPORTANCE_LOW
                )

            val manager =
                getSystemService(
                    NotificationManager::class.java
                )

            manager.createNotificationChannel(channel)
        }

        val notification =
            Notification.Builder(this, channelId)
                .setContentTitle("Nihongo Lens Running")
                .setContentText("Capturing internal audio")
                .setSmallIcon(
                    android.R.drawable.ic_btn_speak_now
                )
                .build()

        startForeground(1, notification)
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }
}
