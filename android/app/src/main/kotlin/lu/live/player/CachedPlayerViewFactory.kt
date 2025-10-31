package lu.live.player

import android.content.Context
import androidx.annotation.OptIn
import androidx.media3.common.util.UnstableApi
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import io.flutter.plugin.common.StandardMessageCodec

class CachedPlayerViewFactory(
    private val messenger: BinaryMessenger
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {

    @OptIn(UnstableApi::class)
    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        return CachedPlayerPlatformView(context, messenger, viewId)
    }
}