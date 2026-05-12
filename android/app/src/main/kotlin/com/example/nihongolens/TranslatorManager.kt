package com.example.nihongolens

import android.content.Context
import android.os.Handler
import android.os.Looper
import com.google.mlkit.nl.translate.TranslateLanguage
import com.google.mlkit.nl.translate.Translation
import com.google.mlkit.nl.translate.Translator
import com.google.mlkit.nl.translate.TranslatorOptions

class TranslatorManager(context: Context) {

    private val translator: Translator
    private val handler = Handler(Looper.getMainLooper())

    init {
        val options = TranslatorOptions.Builder()
            .setSourceLanguage(TranslateLanguage.JAPANESE)
            .setTargetLanguage(TranslateLanguage.ENGLISH)
            .build()
        translator = Translation.getClient(options)
        translator.downloadModelIfNeeded()
    }

    fun translate(text: String, callback: (String) -> Unit) {
        translator.translate(text)
            .addOnSuccessListener { english ->
                handler.post { callback(english) }
            }
            .addOnFailureListener {
                handler.post { callback(text) }
            }
    }

    fun close() {
        try { translator.close() } catch (_: Exception) {}
    }
}
