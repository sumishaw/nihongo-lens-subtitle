package com.example.nihongolens

import android.content.Context
import com.google.mlkit.nl.translate.TranslateLanguage
import com.google.mlkit.nl.translate.Translation
import com.google.mlkit.nl.translate.Translator
import com.google.mlkit.nl.translate.TranslatorOptions

class TranslatorManager(context: Context) {

    private var translator: Translator

    init {

        val options =
            TranslatorOptions.Builder()
                .setSourceLanguage(
                    TranslateLanguage.JAPANESE
                )
                .setTargetLanguage(
                    TranslateLanguage.ENGLISH
                )
                .build()

        translator =
            Translation.getClient(options)

        translator.downloadModelIfNeeded()
    }

    fun translate(
        text: String,
        callback: (String) -> Unit
    ) {

        translator.translate(text)
            .addOnSuccessListener {

                callback(it)
            }
            .addOnFailureListener {

                callback(text)
            }
    }
}
