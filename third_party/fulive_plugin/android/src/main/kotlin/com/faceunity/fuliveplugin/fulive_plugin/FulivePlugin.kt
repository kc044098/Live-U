package com.faceunity.fuliveplugin.fulive_plugin

import android.content.Context
import android.content.res.AssetManager
import android.util.Log
import androidx.lifecycle.Lifecycle
import com.faceunity.core.callback.OperateCallback
import com.faceunity.core.enumeration.FUFaceProcessorDetectModeEnum
import com.faceunity.core.faceunity.FUAIKit
import com.faceunity.core.faceunity.FURenderConfig
import com.faceunity.core.faceunity.FURenderManager
import com.faceunity.core.utils.FULogger
import com.faceunity.faceunity_plugin.authpack
import com.faceunity.fuliveplugin.fulive_plugin.config.FaceunityConfig
import com.faceunity.fuliveplugin.fulive_plugin.config.FaceunityKit
import com.faceunity.fuliveplugin.fulive_plugin.modules.BaseModulePlugin
import com.faceunity.fuliveplugin.fulive_plugin.modules.FUFaceBeautyPlugin
import com.faceunity.fuliveplugin.fulive_plugin.modules.FUMakeupPlugin
import com.faceunity.fuliveplugin.fulive_plugin.modules.FUStickerPlugin
import com.faceunity.fuliveplugin.fulive_plugin.modules.RenderPlugin
import com.faceunity.fuliveplugin.fulive_plugin.render.GLSurfaceViewPlatformViewFactory
import com.faceunity.fuliveplugin.fulive_plugin.render.NotifyFlutterListener
import com.faceunity.fuliveplugin.fulive_plugin.utils.RestrictedSkinTool
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.loader.FlutterLoader
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.embedding.engine.plugins.lifecycle.HiddenLifecycleReference
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.MainScope
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.suspendCancellableCoroutine
import java.io.File
import java.io.FileOutputStream
import kotlin.coroutines.resume


/** FulivePlugin */
class FulivePlugin : FlutterPlugin, MethodCallHandler, EventChannel.StreamHandler, BaseModulePlugin, ActivityAware {
    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity

    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var eventSink: EventChannel.EventSink? = null

    private val glSurfaceViewPlatformViewFactory = GLSurfaceViewPlatformViewFactory()
    private val faceBeautyPlugin by lazy { FUFaceBeautyPlugin() }
    private val stickerPlugin by lazy { FUStickerPlugin() }
    private val makeupPlugin by lazy { FUMakeupPlugin(context) }
    private val renderPlugin by lazy { RenderPlugin(methodChannel) }

    private lateinit var context: Context
    private val mainScope = MainScope()
    private lateinit var lifecycle: Lifecycle

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel = MethodChannel(flutterPluginBinding.binaryMessenger, "fulive_plugin")
        methodChannel.setMethodCallHandler(this)

        eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "render_event_channel")
        eventChannel.setStreamHandler(this)

        context = flutterPluginBinding.applicationContext

        glSurfaceViewPlatformViewFactory.setRenderFrameListener(object : NotifyFlutterListener {
            override fun notifyFlutter(data: Map<String, Any>) {
                mainScope.launch {
                    eventSink?.success(data)
                }
            }
        })
        flutterPluginBinding.platformViewRegistry.registerViewFactory("faceunity_display_view", glSurfaceViewPlatformViewFactory)
        renderPlugin.init(glSurfaceViewPlatformViewFactory)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when {
            faceBeautyPlugin.containsMethod(call.method) -> faceBeautyPlugin.handleMethod(call, result)
            makeupPlugin.containsMethod(call.method) -> makeupPlugin.handleMethod(call, result)
            stickerPlugin.containsMethod(call.method) -> stickerPlugin.handleMethod(call, result)
            renderPlugin.containsMethod(call.method) -> renderPlugin.handleMethod(call, result)
            else -> handleMethod(call, result)
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        eventSink = null
        mainScope.cancel()
        renderPlugin.dispose()
    }


    private val methods =
        mapOf(
            "getPlatformVersion" to ::getPlatformVersion,
            "devicePerformanceLevel" to ::devicePerformanceLevel,
            "getModuleCode" to ::getModuleCode,
            "setFaceProcessorDetectMode" to ::setFaceProcessorDetectMode,
            "requestAlbumForType" to ::requestAlbumForType,
            "setMaxFaceNumber" to ::setMaxFaceNumber,
            "restrictedSkinParams" to ::restrictedSkinParams,
            "initFromAssets" to ::initFromAssets
        )
    override fun methods(): Map<String, (Map<String, Any>, MethodChannel.Result) -> Any> = methods

    override fun tag() = "FulivePlugin"

    private fun getPlatformVersion(params: Map<String, Any>, result: MethodChannel.Result) {
        result.success("Android ${android.os.Build.VERSION.RELEASE}")
    }
    private fun devicePerformanceLevel(params: Map<String, Any>, result: MethodChannel.Result) {
        result.success(FaceunityKit.devicePerformanceLevel)
    }
    private fun getModuleCode(params: Map<String, Any>, result: MethodChannel.Result) {
        val code = params.getInt("code") ?: return
        result.success(renderKit.getModuleCode(code))
    }

    private fun setFaceProcessorDetectMode(params: Map<String, Any>, result: MethodChannel.Result) {
        val mode = params.getInt("mode")?: return
        if (mode == 0) {
            FUAIKit.getInstance().faceProcessorSetDetectMode(FUFaceProcessorDetectModeEnum.IMAGE)
        } else {
            FUAIKit.getInstance().faceProcessorSetDetectMode(FUFaceProcessorDetectModeEnum.VIDEO)
        }
        result.success(true)
    }

    private fun requestAlbumForType(params: Map<String, Any>, result: MethodChannel.Result) {
        val type = params.getInt("type")?: return
        result.success(true)
        mainScope.launch {
            glSurfaceViewPlatformViewFactory.startSelectMedia()
            val pair = suspendCancellableCoroutine { cancellableContinuation->
                if (type == 0) {
                    ActivityPluginBridge.pickImageFile { isSuccess, path ->
                        cancellableContinuation.resume(Pair(isSuccess, path))
                    }
                }else{
                    ActivityPluginBridge.pickVideoFile { isSuccess, path ->
                        cancellableContinuation.resume(Pair(isSuccess, path))
                    }
                }
            }
            glSurfaceViewPlatformViewFactory.stopSelectMedia()
            val mediaPath = pair.second
            glSurfaceViewPlatformViewFactory.setMediaPath(mediaPath)
            methodChannel.invokeMethod(if (type == 0) "photoSelected" else "videoSelected", pair.first)
        }
    }

    private fun setMaxFaceNumber(params: Map<String, Any>, result: MethodChannel.Result) {
        val number = params.getInt("number")?: return
        FUAIKit.getInstance().maxFaces = number.coerceIn(1, 4)
        result.success(true)
    }

    private fun restrictedSkinParams(params: Map<String, Any>, result: MethodChannel.Result) {
        mainScope.launch(Dispatchers.IO) {
            result.success(RestrictedSkinTool.restrictedSkinParams)
        }
    }

    private fun initFromAssets(params: Map<String, Any>, result: MethodChannel.Result) {
        val subDir = (params["subDir"] as? String) ?: "faceunity"

        // 重要：把 FaceunityConfig 的根目錄設成你傳進來的資料夾
        FaceunityConfig.BASE_DIR = subDir

        // 先列出幾個目錄，方便你從 log 對照 APK 內到底有什麼
        try {
            Log.d("FulivePlugin", "assets/$subDir/model: ${context.assets.list("$subDir/model")?.toList()}")
            Log.d("FulivePlugin", "assets/$subDir/graphics: ${context.assets.list("$subDir/graphics")?.toList()}")
        } catch (_: Exception) { /* ignore */ }

        val mustHave = listOf(
            FaceunityConfig.BUNDLE_CONTROLLER_CPP,
            FaceunityConfig.BUNDLE_AI_FACE,
            FaceunityConfig.BUNDLE_AI_HUMAN,
            FaceunityConfig.BUNDLE_FACE_BEAUTIFICATION,
            FaceunityConfig.BLACK_LIST
        )

        val missing = mustHave.filterNot(::assetExists)
        if (missing.isNotEmpty()) {
            Log.w("FulivePlugin", "FaceUnity assets not found in APK: $missing (check FaceunityConfig paths)")
            result.error("ASSET_MISSING", "Missing FaceUnity assets: $missing", null)
            return
        }

        FaceunityKit.setupKit(context) {
            FaceunityKit.loadFaceBeauty()
            result.success(true)
        }
    }


    // 用 open() 驗證；不要用 assets.list()；不要有 "assets/" 前綴
    private fun assetExists(path: String): Boolean {
        return try {
            context.assets.open(path).use { /* ok */ }
            true
        } catch (_: Throwable) {
            false
        }
    }

    // 只做除錯列印（可留著，注意不要加 "assets/" 前綴）
    private fun assetDebugLog(dir: String) {
        try {
            val names = context.assets.list(dir) ?: emptyArray()
            android.util.Log.d("FulivePlugin", "$dir: ${names.toList()}")
        } catch (e: Throwable) {
            android.util.Log.w("FulivePlugin", "list($dir) failed: ${e.message}")
        }
    }


    /** 把整個 assets/<dir> 複製到 app 私有目錄 */
    private fun copyAssetDir(am: AssetManager, dir: String, outDir: File) {
        if (!outDir.exists()) outDir.mkdirs()
        val list = am.list(dir) ?: return
        for (name in list) {
            val child = "$dir/$name"
            val out = File(outDir, name)
            val subList = am.list(child)
            if (subList != null && subList.isNotEmpty()) {
                copyAssetDir(am, child, out)
            } else {
                am.open(child).use { input ->
                    FileOutputStream(out).use { output ->
                        val buf = ByteArray(8 * 1024)
                        while (true) {
                            val n = input.read(buf)
                            if (n <= 0) break
                            output.write(buf, 0, n)
                        }
                        output.flush()
                    }
                }
            }
        }
    }

    private fun copyAssetFile(am: AssetManager, assetPath: String, outFile: File) {
        am.open(assetPath).use { input ->
            FileOutputStream(outFile).use { output ->
                val buf = ByteArray(8 * 1024)
                var n: Int
                while (true) {
                    n = input.read(buf)
                    if (n <= 0) break
                    output.write(buf, 0, n)
                }
                output.flush()
            }
        }
    }


    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        this.eventSink = events
    }

    override fun onCancel(arguments: Any?) {
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        lifecycle = getActivityLifecycle(binding)
        lifecycle.addObserver(glSurfaceViewPlatformViewFactory)
    }

    override fun onDetachedFromActivityForConfigChanges() {

    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    }

    override fun onDetachedFromActivity() {
        lifecycle.removeObserver(glSurfaceViewPlatformViewFactory)
    }


    private fun getActivityLifecycle(
        activityPluginBinding: ActivityPluginBinding,
    ): Lifecycle {
        val reference = activityPluginBinding.lifecycle as HiddenLifecycleReference
        return reference.lifecycle
    }
}
