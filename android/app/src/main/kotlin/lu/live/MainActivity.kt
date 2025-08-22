package lu.live

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import lu.live.player.CachedVideoPlugin

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        CachedVideoPlugin(
            this,
            flutterEngine.dartExecutor.binaryMessenger,
            flutterEngine
        )
    }
}