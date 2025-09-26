package lu.live.player

import android.content.Context
import android.graphics.Color
import android.view.SurfaceView
import android.view.TextureView
import android.view.ViewGroup
import androidx.annotation.OptIn
import androidx.media3.common.MediaItem
import androidx.media3.common.Player
import androidx.media3.exoplayer.DefaultLoadControl
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.exoplayer.source.MediaSource
import androidx.media3.exoplayer.source.ProgressiveMediaSource
import androidx.media3.exoplayer.hls.HlsMediaSource
import androidx.media3.common.util.UnstableApi
import androidx.media3.datasource.DataSource
import androidx.media3.exoplayer.DefaultRenderersFactory
import androidx.media3.ui.AspectRatioFrameLayout
import androidx.media3.ui.PlayerView

@OptIn(UnstableApi::class)
class CachedPlayer(private val context: Context) {

    private var player: ExoPlayer? = null
    private var attachedView: PlayerView? = null
    private var textureView: TextureView? = null
    private var firstFrameCallback: (() -> Unit)? = null
    private var desiredVolume: Float = 1f

    fun setFirstFrameListener(cb: (() -> Unit)?) {
        firstFrameCallback = cb
    }

    private fun buildPlayer(): ExoPlayer {
        val loadControl = DefaultLoadControl.Builder()
            .setBufferDurationsMs(
                /* minBufferMs = */ 1500,
                /* maxBufferMs = */ 8000,
                /* bufferForPlaybackMs = */ 300,
                /* bufferForPlaybackAfterRebufferMs = */ 500
            ).build()

        val renderersFactory = DefaultRenderersFactory(context)
            .setEnableDecoderFallback(true)

        return ExoPlayer.Builder(context, renderersFactory)
            .setLoadControl(loadControl)
            .build().apply {
                addListener(object : Player.Listener {
                    override fun onRenderedFirstFrame() {
                        firstFrameCallback?.invoke()
                    }
                })
                volume = desiredVolume
            }
    }

    /** 把 PlayerView 佈置成透明背景 + TextureView，避免初始化黑屏 */
    private fun ensureTextureSurface(playerView: PlayerView): TextureView {
        // 外觀設定（避免黑底）
        playerView.apply {
            useController = false
            controllerAutoShow = false
            controllerShowTimeoutMs = 0
            setShutterBackgroundColor(Color.TRANSPARENT)
            setBackgroundColor(Color.TRANSPARENT)
            setKeepContentOnPlayerReset(true)
            setUseArtwork(false)
            resizeMode = AspectRatioFrameLayout.RESIZE_MODE_ZOOM
            isClickable = false
            isFocusable = false
        }

        // 移除可能存在的 SurfaceView
        (playerView.videoSurfaceView as? SurfaceView)?.let { playerView.removeView(it) }

        // 如果已經是 TextureView 就直接用它
        (playerView.videoSurfaceView as? TextureView)?.let {
            textureView = it
            return it
        }

        // 否則新增一個 TextureView 放到最底層
        val tv = TextureView(playerView.context).apply {
            layoutParams = ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT
            )
        }
        playerView.addView(tv, 0)
        textureView = tv
        return tv
    }

    /** 綁定 Player 到 PlayerView，強制使用 TextureView 做輸出 */
    fun attachTo(playerView: PlayerView) {
        val p = player ?: buildPlayer().also { player = it }

        // 清掉舊的 video surface 關聯
        p.clearVideoSurface()
        textureView = null

        // 確保 PlayerView 裡面用的是 TextureView
        val tv = ensureTextureSurface(playerView)
        p.setVideoTextureView(tv)

        // 綁定
        attachedView?.player = null
        attachedView = playerView
        playerView.player = p
    }

    /** 解綁，釋放 Surface 關聯 */
    fun detach() {
        attachedView?.player = null
        attachedView = null
        player?.playWhenReady = false
        try {
            player?.clearVideoSurface()
        } catch (_: Throwable) { }
        textureView = null
    }

    /** 設定資料來源（走你的 CacheDataSource），預載時 autoPlay=false */
    fun setDataSource(
        url: String,
        userAgent: String,
        headers: Map<String, String>? = null,
        autoPlay: Boolean = false,
        looping: Boolean = true
    ) {
        val dsf: DataSource.Factory = DataSources.cacheFactory(context, userAgent, headers)

        val item = MediaItem.Builder()
            .setUri(url)
            .setCustomCacheKey(stableKeyFrom(url)) // 👈 關鍵
            .build()

        val mediaSource: MediaSource =
            if (url.endsWith(".m3u8", true)) {
                HlsMediaSource.Factory(dsf).createMediaSource(item)
            } else {
                ProgressiveMediaSource.Factory(dsf).createMediaSource(item)
            }

        val p = player ?: buildPlayer().also { player = it }
        p.setMediaSource(mediaSource, /* startPositionMs = */ 0)
        p.repeatMode = if (looping) Player.REPEAT_MODE_ONE else Player.REPEAT_MODE_OFF
        p.prepare()
        p.volume = desiredVolume
        p.playWhenReady = autoPlay
    }

    fun setVolume(vol: Float) {
        desiredVolume = vol.coerceIn(0f, 1f)
        player?.volume = desiredVolume
    }

    private fun stableKeyFrom(url: String): String {
        // 去掉 query/fragment，避免 key 每次不同
        return url.substringBefore('#').substringBefore('?')
    }

    fun play() = player?.play()
    fun pause() = player?.pause()
    fun seekTo(ms: Long) = player?.seekTo(ms)

    fun release() {
        detach()
        player?.release()
        player = null
    }

    fun getPlayer(): ExoPlayer? = player
}