package lu.live

import android.app.PictureInPictureParams
import android.content.res.Configuration
import android.graphics.Rect
import android.os.Build
import android.util.Rational
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import lu.live.player.CachedVideoPlugin

class MainActivity : FlutterActivity() {

    private val CHANNEL = "pip"
    private var ch: MethodChannel? = null

    // 自動 PiP 的開關與參數
    private var autoPipEnabled = false
    private var aspectW = 9
    private var aspectH = 16
    private var hintRect: Rect? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        ch = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        ch?.setMethodCallHandler { call, result ->
            when (call.method) {
                "isInPiP" -> {
                    val inPip = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) isInPictureInPictureMode else false
                    result.success(inPip)
                }
                "enterPiP" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        val w = (call.argument<Int>("w") ?: 9).coerceAtLeast(1)
                        val h = (call.argument<Int>("h") ?: 16).coerceAtLeast(1)
                        val l = call.argument<Int>("left")
                        val t = call.argument<Int>("top")
                        val wd = call.argument<Int>("width")
                        val ht = call.argument<Int>("height")
                        val builder = PictureInPictureParams.Builder().setAspectRatio(Rational(w, h))
                        if (l != null && t != null && wd != null && ht != null) {
                            builder.setSourceRectHint(Rect(l, t, l + wd, t + ht))
                        }
                        try {
                            enterPictureInPictureMode(builder.build())
                            result.success(true)
                        } catch (e: Throwable) {
                            result.error("PIP_ERR", e.localizedMessage, null)
                        }
                    } else {
                        result.error("UNSUPPORTED", "Requires API 26+", null)
                    }
                }
                // ✅ 啟/停「自動 PiP」
                "armAutoPip" -> {
                    autoPipEnabled = call.argument<Boolean>("enable") == true
                    aspectW = (call.argument<Int>("w") ?: 9).coerceAtLeast(1)
                    aspectH = (call.argument<Int>("h") ?: 16).coerceAtLeast(1)
                    val l = call.argument<Int>("left")
                    val t = call.argument<Int>("top")
                    val wd = call.argument<Int>("width")
                    val ht = call.argument<Int>("height")
                    hintRect = if (l != null && t != null && wd != null && ht != null) Rect(l, t, l + wd, t + ht) else null

                    // Android 12+ 可開啟「自動進 PiP」
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                        val builder = PictureInPictureParams.Builder()
                            .setAspectRatio(Rational(aspectW, aspectH))
                            .setAutoEnterEnabled(autoPipEnabled)
                        hintRect?.let { builder.setSourceRectHint(it) }
                        setPictureInPictureParams(builder.build())
                    }
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        CachedVideoPlugin(
            this,
            flutterEngine.dartExecutor.binaryMessenger,
            flutterEngine
        )
    }

    // 使用者按 Home / 手勢離開當前 Activity 時呼叫
    override fun onUserLeaveHint() {
        super.onUserLeaveHint()
        if (!autoPipEnabled) return
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && !isInPictureInPictureMode) {
            try {
                // ★ 先叫 Flutter 顯示白底 + timer HUD
                ch?.invokeMethod("prePiP", null)

                // ★ 稍等一下讓 Flutter 完成繪製（50~80ms 足夠）
                window.decorView.postDelayed({
                    val builder = PictureInPictureParams.Builder()
                        .setAspectRatio(Rational(aspectW, aspectH))
                    hintRect?.let { builder.setSourceRectHint(it) }
                    enterPictureInPictureMode(builder.build())
                }, 60)
            } catch (_: Throwable) { /* ignore */ }
        }
    }

    override fun onPictureInPictureModeChanged(isInPiP: Boolean, newConfig: Configuration) {
        super.onPictureInPictureModeChanged(isInPiP, newConfig)
        ch?.invokeMethod("pipState", isInPiP)
    }
}