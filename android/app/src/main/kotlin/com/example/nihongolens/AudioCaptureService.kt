package com.example.nihongolens

import android.app.*
import android.content.Intent
import android.media.*
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.os.*
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import androidx.core.app.NotificationCompat

class AudioCaptureService : Service() {

    private var mediaProjection: MediaProjection? = null
    private var speechRecognizer: SpeechRecognizer? = null
    private var translatorManager: TranslatorManager? = null
    private val handler = Handler(Looper.getMainLooper())
    private var isListening = false
    private var restartRunnable: Runnable? = null

    companion object {
        const val CHANNEL_ID = "nihongo_channel"
        const val NOTIF_ID = 1
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        translatorManager = TranslatorManager(this)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        startForeground(NOTIF_ID, buildNotification())
        startMicRecognition()
        showOverlay("🎤 Listening for Japanese...")
        return START_STICKY
    }

    private fun startMicRecognition() {
        if (!SpeechRecognizer.isRecognitionAvailable(this)) {
            showOverlay("⚠️ Install Google app for speech recognition")
            return
        }
        speechRecognizer = SpeechRecognizer.createSpeechRecognizer(this)
        speechRecognizer?.setRecognitionListener(object : RecognitionListener {
            override fun onReadyForSpeech(p: Bundle?) {}
            override fun onBeginningOfSpeech() {}
            override fun onRmsChanged(v: Float) {}
            override fun onBufferReceived(b: ByteArray?) {}
            override fun onEndOfSpeech() {}
            override fun onEvent(t: Int, p: Bundle?) {}

            override fun onPartialResults(b: Bundle?) {
                val partial = b?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                    ?.firstOrNull() ?: return
                if (partial.isNotBlank()) showOverlay("🎌 $partial", isPartial = true)
            }

            override fun onResults(b: Bundle?) {
                val text = b?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                    ?.firstOrNull() ?: ""
                if (text.isNotBlank()) {
                    showOverlay("🔄 Translating...")
                    translatorManager?.translate(text) { english ->
                        showOverlay(english, japanese = text)
                    }
                }
                scheduleRestart(300)
            }

            override fun onError(error: Int) {
                val delay = when (error) {
                    SpeechRecognizer.ERROR_NO_MATCH -> 200L
                    SpeechRecognizer.ERROR_SPEECH_TIMEOUT -> 300L
                    SpeechRecognizer.ERROR_RECOGNIZER_BUSY -> 1000L
                    SpeechRecognizer.ERROR_INSUFFICIENT_PERMISSIONS -> {
                        showOverlay("⚠️ Mic permission denied")
                        return
                    }
                    else -> 500L
                }
                scheduleRestart(delay)
            }
        })
        beginListening()
    }

    private fun beginListening() {
        val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
            putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
            putExtra(RecognizerIntent.EXTRA_LANGUAGE, "ja-JP")
            putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
            putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 1)
            putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_COMPLETE_SILENCE_LENGTH_MILLIS, 1500L)
        }
        handler.post {
            try {
                speechRecognizer?.startListening(intent)
                isListening = true
            } catch (e: Exception) {
                scheduleRestart(1000)
            }
        }
    }

    private fun scheduleRestart(delayMs: Long) {
        restartRunnable?.let { handler.removeCallbacks(it) }
        restartRunnable = Runnable {
            try { speechRecognizer?.stopListening() } catch (_: Exception) {}
            beginListening()
        }
        handler.postDelayed(restartRunnable!!, delayMs)
    }

    private fun showOverlay(text: String, japanese: String = "", isPartial: Boolean = false) {
        handler.post {
            val intent = Intent(this, OverlayService::class.java).apply {
                putExtra("subtitle", text)
                putExtra("japanese", japanese)
                putExtra("partial", isPartial)
            }
            startService(intent)
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val ch = NotificationChannel(CHANNEL_ID, "Nihongo Lens", NotificationManager.IMPORTANCE_LOW)
                .apply { setShowBadge(false) }
            getSystemService(NotificationManager::class.java).createNotificationChannel(ch)
        }
    }

    private fun buildNotification(): Notification {
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("🎌 Nihongo Lens Active")
            .setContentText("Translating Japanese → English")
            .setSmallIcon(android.R.drawable.ic_btn_speak_now)
            .setOngoing(true)
            .build()
    }

    override fun onDestroy() {
        isListening = false
        restartRunnable?.let { handler.removeCallbacks(it) }
        try { speechRecognizer?.destroy() } catch (_: Exception) {}
        translatorManager?.close()
        stopService(Intent(this, OverlayService::class.java))
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
