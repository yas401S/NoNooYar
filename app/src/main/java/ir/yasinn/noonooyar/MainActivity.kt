package ir.yasinn.noonooyar

import android.app.Activity
import android.os.Bundle
import android.webkit.JavascriptInterface
import android.webkit.WebChromeClient
import android.webkit.WebResourceRequest
import android.webkit.WebView
import android.webkit.WebViewClient
import android.view.ViewGroup
import android.widget.TextView
import android.speech.tts.TextToSpeech
import java.util.Locale
import java.util.UUID

class MainActivity : Activity() {
    private var tts: TextToSpeech? = null
    private var ttsReady = false
    private var web: WebView? = null
    private var availableVoices = emptyList<android.speech.tts.Voice>()

    private fun report(message: String) {
        runOnUiThread {
            try {
                web?.evaluateJavascript("window.onNativeTtsStatus && window.onNativeTtsStatus(" +
                    org.json.JSONObject.quote(message) + ")", null)
            } catch (_: Exception) { }
        }
    }

    private inner class SpeechBridge {
        @JavascriptInterface
        fun speak(text: String, language: String, rate: Float, pitch: Float) {
            runOnUiThread {
                try {
                    val engine = tts
                    if (!ttsReady || engine == null) {
                        report("موتور صدای گوشی هنوز آماده نیست؛ کمی بعد دوباره امتحان کن.")
                        return@runOnUiThread
                    }
                    val lang = if (language.startsWith("en")) Locale.US else Locale.forLanguageTag("fa-IR")
                    val matching = availableVoices.filter { it.locale.language == lang.language }
                    val voice = matching.firstOrNull { !it.isNetworkConnectionRequired }
                        ?: matching.firstOrNull()
                    engine.stop()
                    if (voice != null) {
                        engine.voice = voice
                    } else {
                        val languageResult = engine.setLanguage(lang)
                        if (languageResult == TextToSpeech.LANG_MISSING_DATA ||
                            languageResult == TextToSpeech.LANG_NOT_SUPPORTED) {
                            report(if (lang.language == "fa")
                                "موتور گفتار گوشی صدای فارسی ندارد. باید موتور Google Speech Services و داده گفتار فارسی سازگار نصب شود."
                            else "صدای انگلیسی در موتور گفتار گوشی موجود نیست.")
                            return@runOnUiThread
                        }
                    }
                    engine.setSpeechRate(rate.coerceIn(0.5f, 1.5f))
                    engine.setPitch(pitch.coerceIn(0.5f, 1.5f))
                    val result = engine.speak(text, TextToSpeech.QUEUE_FLUSH, null, UUID.randomUUID().toString())
                    if (result == TextToSpeech.ERROR) report("پخش صدا انجام نشد؛ تنظیمات گفتار گوشی را بررسی کن.")
                } catch (_: Exception) {
                    report("فعلاً پخش صدا در دسترس نیست؛ می‌توانی از بقیه بخش‌های برنامه استفاده کنی.")
                }
            }
        }
        @JavascriptInterface
        fun stop() { runOnUiThread { try { tts?.stop() } catch (_: Exception) { } } }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        try {
            val view = WebView(this)
            web = view
            view.layoutParams = ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT
            )
            view.settings.javaScriptEnabled = true
            view.settings.domStorageEnabled = true
            view.settings.allowFileAccess = true
            view.settings.allowContentAccess = false
            view.settings.blockNetworkLoads = true
            view.settings.mixedContentMode = android.webkit.WebSettings.MIXED_CONTENT_NEVER_ALLOW
            view.addJavascriptInterface(SpeechBridge(), "AndroidSpeech")
            view.webChromeClient = WebChromeClient()
            view.webViewClient = object : WebViewClient() {
                override fun shouldOverrideUrlLoading(view: WebView?, request: WebResourceRequest?): Boolean {
                    return request?.url?.scheme != "file"
                }
            }
            setContentView(view)
            view.loadUrl("file:///android_asset/index.html")
            try {
                tts = TextToSpeech(applicationContext) { status ->
                    if (status == TextToSpeech.SUCCESS) {
                        try {
                            ttsReady = true
                            availableVoices = tts?.voices?.toList() ?: emptyList()
                            val hasPersian = availableVoices.any { it.locale.language == "fa" }
                            report(if (hasPersian) "صدای فارسی در موتور گفتار پیدا شد." else
                                "موتور فعلی صدای فارسی ندارد؛ موتور گفتار گوشی را به‌روزرسانی یا عوض کن.")
                        } catch (_: Exception) { report("برنامه اجراست؛ تنظیمات صدا در دسترس نیست.") }
                    } else report("برنامه اجراست؛ موتور صدای گوشی آماده نیست.")
                }
            } catch (_: Exception) {
                report("برنامه اجراست؛ موتور صدای گوشی در دسترس نیست.")
            }
        } catch (e: Exception) {
            val fallback = TextView(this)
            fallback.text = "یاسین‌لند\nبرای اجرا، لطفاً برنامه را دوباره باز کن."
            fallback.textSize = 22f
            fallback.gravity = android.view.Gravity.CENTER
            setContentView(fallback)
        }
    }

    override fun onDestroy() {
        try { tts?.stop(); tts?.shutdown() } catch (_: Exception) { }
        tts = null
        web = null
        super.onDestroy()
    }

    @Deprecated("Deprecated in Java")
    override fun onBackPressed() {
        val view = web
        if (view?.canGoBack() == true) view.goBack() else super.onBackPressed()
    }
}
