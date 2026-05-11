package com.example.nihongolens

import android.content.Context
import org.vosk.Model
import org.vosk.Recognizer

class VoskManager(context: Context) {

    private var model: Model? = null
    private var recognizer: Recognizer? = null

    init {

        try {

            model =
                Model("model-ja")

            recognizer =
                Recognizer(
                    model,
                    16000.0f
                )

        } catch (e: Exception) {

            e.printStackTrace()
        }
    }

    fun recognizeAudio(
        audioData: ByteArray
    ): String {

        return try {

            if (
                recognizer?.acceptWaveForm(
                    audioData,
                    audioData.size
                ) == true
            ) {

                recognizer?.result
                    ?: ""

            } else {

                recognizer?.partialResult
                    ?: ""
            }

        } catch (e: Exception) {

            ""
        }
    }
}
