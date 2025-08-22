package lu.live.player

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Color
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.ColorDrawable
import android.graphics.drawable.Drawable
import android.view.View
import androidx.media3.common.util.UnstableApi
import androidx.media3.ui.AspectRatioFrameLayout
import androidx.media3.ui.PlayerView
import com.bumptech.glide.Glide
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformView
import com.bumptech.glide.request.target.CustomTarget
import com.bumptech.glide.request.transition.Transition
import androidx.core.graphics.drawable.toDrawable

@UnstableApi
class CachedPlayerPlatformView(
    context: Context,
    messenger: BinaryMessenger,
    private val viewId: Int
) : PlatformView, MethodChannel.MethodCallHandler {

    private val playerView = PlayerView(context).apply {
        useController = false
        controllerAutoShow = false
        controllerShowTimeoutMs = 0

        setShutterBackgroundColor(Color.TRANSPARENT)
        setBackgroundColor(Color.TRANSPARENT)
        setKeepContentOnPlayerReset(true)

        // 重要：讓封面可見
        setUseArtwork(true)
        setDefaultArtwork(null)

        resizeMode = AspectRatioFrameLayout.RESIZE_MODE_ZOOM
        isClickable = false
        isFocusable = false
    }

    private val player = CachedPlayer(context)

    private val channel = MethodChannel(messenger, "cached_video_player/view_$viewId")

    // 把 listener 設一次就好（事件名統一 "onFirstFrame"）
    init {
        channel.setMethodCallHandler(this)
        player.setFirstFrameListener {
            try {
                // 首幀來了 -> 關掉 artwork（封面）
                playerView.setUseArtwork(false)
            } catch (_: Throwable) {}
            try {
                channel.invokeMethod("onFirstFrame", null)
            } catch (_: Throwable) {}
        }
    }

    override fun getView(): View = playerView

    override fun dispose() {
        try { player.release() } catch (_: Throwable) {}
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "setDataSource" -> {
                val url      = call.argument<String>("url")!!
                val ua       = call.argument<String>("userAgent") ?: "djs-live/1.0"
                val headers  = call.argument<Map<String,String>>("headers")
                val autoPlay = call.argument<Boolean>("autoPlay") ?: false
                val looping  = call.argument<Boolean>("looping") ?: true
                val coverUrl = call.argument<String>("coverUrl")

                // 先保持/顯示 artwork，避免在 Glide 還沒回來時變透明
                playerView.setUseArtwork(true)
                playerView.setDefaultArtwork(Color.BLACK.toDrawable())
                if (!coverUrl.isNullOrBlank()) {
                    // 用 Glide 載入 bitmap，回來後設成 defaultArtwork
                    Glide.with(playerView)
                        .asBitmap()
                        .load(coverUrl)
                        .into(object : CustomTarget<Bitmap>() {
                            override fun onResourceReady(res: Bitmap, t: Transition<in Bitmap>?) {
                                playerView.setDefaultArtwork(res.toDrawable(playerView.resources))
                                playerView.setUseArtwork(true) // 保持到首幀
                            }
                            override fun onLoadCleared(placeholder: Drawable?) { /* no-op */ }
                        })
                }
                // 不要清成 null；沒封面就沿用舊的 defaultArtwork（或外層疊圖），直到首幀

                player.setDataSource(url, ua, headers, autoPlay = autoPlay, looping = looping)
                result.success(null)
            }

            "attach" -> {
                player.attachTo(playerView)
                result.success(null)
            }

            "detach" -> {
                player.detach()
                try { playerView.setUseArtwork(true) } catch (_: Throwable) {}
                result.success(null)
            }

            "play" -> { player.play(); result.success(null) }
            "pause" -> { player.pause(); result.success(null) }
            "seekTo" -> {
                val ms = (call.argument<Int>("ms") ?: 0).toLong()
                player.seekTo(ms); result.success(null)
            }
            "release" -> { player.release(); result.success(null) }
            else -> result.notImplemented()
        }
    }
}