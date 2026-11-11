package ir.yasinn.noonooyar

import android.app.Activity
import android.os.Bundle
import android.webkit.JavascriptInterface
import android.webkit.WebChromeClient
import android.webkit.WebResourceRequest
import android.webkit.WebView
import android.webkit.WebViewClient
import android.view.ViewGroup
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import java.util.Locale
import java.util.UUID

class MainActivity : Activity() {
    private var tts: TextToSpeech? = null
    private var ttsReady = false
    private var web: WebView? = null
    private var offlineVoices = emptyList<android.speech.tts.Voice>()

    private fun report(message: String) {
        runOnUiThread {
            web?.evaluateJavascript("window.onNativeTtsStatus && window.onNativeTtsStatus(" +
                org.json.JSONObject.quote(message) + ")", null)
        }
    }

    private inner class SpeechBridge {
        @JavascriptInterface
        fun speak(text: String, language: String, rate: Float, pitch: Float) {
            runOnUiThread {
                val engine = tts
                if (!ttsReady || engine == null) {
                    report("موتور صدای گوشی هنوز آماده نیست؛ کمی بعد دوباره امتحان کن.")
                    return@runOnUiThread
                }
                val lang = if (language.startsWith("en")) Locale.US else Locale.forLanguageTag("fa-IR")
                val voice = offlineVoices.firstOrNull { it.locale.language == lang.language }
                if (voice == null) {
                    report(if (lang.language == "fa")
                        "صدای فارسی آفلاین روی گوشی نصب نیست. از تنظیمات تبدیل متن به گفتار، دادهٔ صوتی فارسی را نصب کن."
                    else "صدای انگلیسی آفلاین روی گوشی نصب نیست. از تنظیمات تبدیل متن به گفتار، دادهٔ صوتی انگلیسی را نصب کن.")
                    return@runOnUiThread
                }
                engine.stop()
                engine.voice = voice
                engine.setSpeechRate(rate.coerceIn(0.5f, 1.5f))
                engine.setPitch(pitch.coerceIn(0.5f, 1.5f))
                val result = engine.speak(text, TextToSpeech.QUEUE_FLUSH, null, UUID.randomUUID().toString())
                if (result == TextToSpeech.ERROR) report("پخش صدای آفلاین انجام نشد؛ موتور گفتار گوشی را بررسی کن.")
            }
        }

        @JavascriptInterface
        fun stop() { runOnUiThread { tts?.stop() } }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
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
                val scheme = request?.url?.scheme ?: return true
                return scheme != "file"
            }
        }
        setContentView(view)
        tts = TextToSpeech(this) { status ->
            if (status == TextToSpeech.SUCCESS) {
                ttsReady = true
                offlineVoices = tts?.voices?.filter { !it.isNetworkConnectionRequired }?.toList() ?: emptyList()
                report("صدای آفلاین آماده است؛ زبان‌های نصب‌شده: " +
                    offlineVoices.map { it.locale.language }.distinct().joinToString("، "))
            } else report("موتور تبدیل متن به گفتار گوشی راه‌اندازی نشد.")
        }
        view.loadUrl("file:///android_asset/index.html")
    }

    override fun onDestroy() {
        tts?.stop()
        tts?.shutdown()
        tts = null
        super.onDestroy()
    }

    @Deprecated("Deprecated in Java")
    override fun onBackPressed() {
        val view = (window.decorView as? ViewGroup)?.getChildAt(0) as? WebView
        if (view?.canGoBack() == true) view.goBack() else super.onBackPressed()
    }
}
