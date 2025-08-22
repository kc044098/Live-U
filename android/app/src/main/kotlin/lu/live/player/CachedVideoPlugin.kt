package lu.live.player

import android.app.Activity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class CachedVideoPlugin(
    private val activity: Activity,
    messenger: BinaryMessenger,
    flutterEngine: FlutterEngine
) : MethodChannel.MethodCallHandler {

    private val channel = MethodChannel(messenger, "cached_video_player")
    // 存預取 handle，之後可以 cancel
    private val prefetchMap = mutableMapOf<String, PrefetchHandle>()

    init {
        channel.setMethodCallHandler(this)
        val registry = flutterEngine.platformViewsController.registry
            ?: throw IllegalStateException("FlutterEngine is null")
        registry.registerViewFactory(
            "cached_video_player/view",                 // ← viewType
            CachedPlayerViewFactory(messenger) )
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "prefetchMp4Head" -> {
                val url = call.argument<String>("url")!!
                val bytes = (call.argument<Int>("bytes") ?: (3 * 1024 * 1024)).toLong()
                val headers = call.argument<Map<String, String>>("headers")

                val handle = PrefetchUtils.prefetchMp4Head(
                    context = activity,
                    url = url,
                    bytes = bytes,
                    headers = headers
                )

                val id = System.nanoTime().toString()
                prefetchMap[id] = handle
                result.success(id)
            }

            "cancelPrefetch" -> {
                val id = call.argument<String>("id")!!
                prefetchMap.remove(id)?.cancel()
                result.success(null)
            }

            else -> result.notImplemented()
        }
    }
}
