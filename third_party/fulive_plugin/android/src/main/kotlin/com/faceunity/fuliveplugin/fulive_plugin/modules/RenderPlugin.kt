package com.faceunity.fuliveplugin.fulive_plugin.modules

import com.faceunity.fuliveplugin.fulive_plugin.config.FaceunityKit
import com.faceunity.fuliveplugin.fulive_plugin.render.GLSurfaceViewPlatformViewFactory
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.MainScope
import kotlinx.coroutines.awaitCancellation
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlin.coroutines.resume

/**
 *
 * @author benyq
 * @date 12/19/2023
 *
 */

class RenderPlugin(private val methodChannel: MethodChannel): BaseModulePlugin {

    private lateinit var glSurfaceViewPlatformViewFactory: GLSurfaceViewPlatformViewFactory
    private val mainScope = MainScope()

    override fun tag() = "RenderPlugin"

    private val methods =
        mapOf(
            "startCamera" to ::startCamera,
            "stopCamera" to ::stopCamera,
            "switchCamera" to ::switchCamera,
            "switchCapturePreset" to ::switchCapturePreset,
            "switchRenderInputType" to ::switchRenderInputType,
            "setCameraExposure" to ::setCameraExposure,
            "manualFocus" to ::manualFocus,
            "setRenderState" to ::setRenderState,
            "startImageRender" to ::startImageRender,
            "stopImageRender" to ::stopImageRender,
            "disposeImageRender" to ::disposeImageRender,
            "startPlayingVideo" to ::startPlayingVideo,
            "stopPlayingVideo" to ::stopPlayingVideo,
            "startPreviewingVideo" to ::startPreviewingVideo,
            "stopPreviewingVideo" to ::stopPreviewingVideo,
            "disposeVideoRender" to ::disposeVideoRender,
            // 拍照與錄影
            "takePhoto" to ::takePhoto,
            "startRecord" to ::startRecord,
            "stopRecord" to ::stopRecord,
            "captureImage" to ::captureImage,
            "startExportingVideo" to ::startExportingVideo,
            "stopExportingVideo" to ::stopExportingVideo,
        )
    override fun methods(): Map<String, (Map<String, Any>, MethodChannel.Result) -> Any> = methods

    fun init(viewFactory: GLSurfaceViewPlatformViewFactory) {
        this.glSurfaceViewPlatformViewFactory = viewFactory
    }

    fun dispose() {
        mainScope.cancel()
    }

    // --- 建議的小工具：統一包 try/catch + 回傳 result ---
    private inline fun reply(result: MethodChannel.Result, crossinline block: () -> Unit) {
        try {
            block()
            result.success(true)
        } catch (t: Throwable) {
            android.util.Log.e("FU-RenderPlugin", "error: ${t.message}", t)
            result.success(false)
        }
    }

    private fun startCamera(params: Map<String, Any>, result: MethodChannel.Result) = reply(result) {
        android.util.Log.d("FU-RenderPlugin", "startCamera()")
        glSurfaceViewPlatformViewFactory.startCamera()
    }

    private fun stopCamera(params: Map<String, Any>, result: MethodChannel.Result) = reply(result) {
        android.util.Log.d("FU-RenderPlugin", "stopCamera()")
        glSurfaceViewPlatformViewFactory.stopCamera()
    }

    private fun switchCamera(params: Map<String, Any>, result: MethodChannel.Result) = reply(result) {
        val isFront = params.getBoolean("isFront") ?: return@reply
        android.util.Log.d("FU-RenderPlugin", "switchCamera(isFront=$isFront)")
        glSurfaceViewPlatformViewFactory.switchCamera(isFront)
    }

    private fun switchCapturePreset(params: Map<String, Any>, result: MethodChannel.Result) = reply(result) {
        val preset = params.getInt("preset") ?: return@reply
        android.util.Log.d("FU-RenderPlugin", "switchCapturePreset($preset)")
        glSurfaceViewPlatformViewFactory.switchCapturePreset(preset)
    }

    private fun switchRenderInputType(params: Map<String, Any>, result: MethodChannel.Result) = reply(result) {
        val inputType = params.getInt("inputType") ?: return@reply
        android.util.Log.d("FU-RenderPlugin", "switchRenderInputType($inputType)")
        glSurfaceViewPlatformViewFactory.switchRenderInputType(inputType)
    }

    private fun setCameraExposure(params: Map<String, Any>, result: MethodChannel.Result) = reply(result) {
        val exposure = params.getDouble("exposure") ?: return@reply
        android.util.Log.d("FU-RenderPlugin", "setCameraExposure($exposure)")
        glSurfaceViewPlatformViewFactory.setCameraExposure(exposure)
    }

    private fun manualFocus(params: Map<String, Any>, result: MethodChannel.Result) = reply(result) {
        val dx = params.getDouble("dx") ?: return@reply
        val dy = params.getDouble("dy") ?: return@reply
        val focusRectSize = params.getInt("focusRectSize") ?: return@reply
        android.util.Log.d("FU-RenderPlugin", "manualFocus(dx=$dx, dy=$dy, size=$focusRectSize)")
        glSurfaceViewPlatformViewFactory.manualFocus(dx, dy, focusRectSize)
    }

    private fun setRenderState(params: Map<String, Any>, result: MethodChannel.Result) = reply(result) {
        val isRendering = params.getBoolean("isRendering") ?: return@reply
        android.util.Log.d("FU-RenderPlugin", "setRenderState($isRendering)")
        glSurfaceViewPlatformViewFactory.setRenderState(isRendering)
    }

    private fun startImageRender(params: Map<String, Any>, result: MethodChannel.Result) = reply(result) {
        android.util.Log.d("FU-RenderPlugin", "startImageRender()")
        glSurfaceViewPlatformViewFactory.startImageRender()
    }

    private fun stopImageRender(params: Map<String, Any>, result: MethodChannel.Result) = reply(result) {
        android.util.Log.d("FU-RenderPlugin", "stopImageRender()")
        glSurfaceViewPlatformViewFactory.stopImageRender()
    }

    private fun disposeImageRender(params: Map<String, Any>, result: MethodChannel.Result) = reply(result) {
        android.util.Log.d("FU-RenderPlugin", "disposeImageRender()")
        glSurfaceViewPlatformViewFactory.disposeImageRender()
    }

    private fun startPreviewingVideo(params: Map<String, Any>, result: MethodChannel.Result) = reply(result) {
        android.util.Log.d("FU-RenderPlugin", "startPreviewingVideo()")
        glSurfaceViewPlatformViewFactory.startPreviewingVideo()
    }

    private fun stopPreviewingVideo(params: Map<String, Any>, result: MethodChannel.Result) = reply(result) {
        android.util.Log.d("FU-RenderPlugin", "stopPreviewingVideo()")
        glSurfaceViewPlatformViewFactory.stopPreviewingVideo()
    }

    private fun startPlayingVideo(params: Map<String, Any>, result: MethodChannel.Result) = reply(result) {
        android.util.Log.d("FU-RenderPlugin", "startPlayingVideo()")
        glSurfaceViewPlatformViewFactory.startPlayingVideo()
    }

    private fun stopPlayingVideo(params: Map<String, Any>, result: MethodChannel.Result) = reply(result) {
        android.util.Log.d("FU-RenderPlugin", "stopPlayingVideo()")
        glSurfaceViewPlatformViewFactory.stopPlayingVideo()
    }

    private fun disposeVideoRender(params: Map<String, Any>, result: MethodChannel.Result) = reply(result) {
        android.util.Log.d("FU-RenderPlugin", "disposeVideoRender()")
        glSurfaceViewPlatformViewFactory.disposeVideoRender()
    }

    private fun takePhoto(params: Map<String, Any>, result: MethodChannel.Result) {
        android.util.Log.d("FU-RenderPlugin", "takePhoto()")
        mainScope.launch {
            val success = suspendCancellableCoroutine { continuation ->
                glSurfaceViewPlatformViewFactory.takePhoto {
                    continuation.resume(it)
                }
            }
            methodChannel.invokeMethod("takePhotoResult", success)
            result.success(success)
        }
    }

    private fun startRecord(params: Map<String, Any>, result: MethodChannel.Result) = reply(result) {
        android.util.Log.d("FU-RenderPlugin", "startRecord()")
        glSurfaceViewPlatformViewFactory.startRecord()
    }

    private fun stopRecord(params: Map<String, Any>, result: MethodChannel.Result) {
        android.util.Log.d("FU-RenderPlugin", "stopRecord()")
        mainScope.launch {
            val success = suspendCancellableCoroutine { continuation ->
                glSurfaceViewPlatformViewFactory.stopRecord {
                    continuation.resume(it)
                }
            }
            result.success(success)
        }
    }

    private fun captureImage(params: Map<String, Any>, result: MethodChannel.Result) {
        android.util.Log.d("FU-RenderPlugin", "captureImage()")
        mainScope.launch {
            val success = suspendCancellableCoroutine { continuation ->
                glSurfaceViewPlatformViewFactory.captureImage {
                    continuation.resume(it)
                }
            }
            methodChannel.invokeMethod("captureImageResult", success)
            result.success(success)
        }
    }

    private fun startExportingVideo(params: Map<String, Any>, result: MethodChannel.Result) = reply(result) {
        android.util.Log.d("FU-RenderPlugin", "startExportingVideo()")
        glSurfaceViewPlatformViewFactory.startExportingVideo()
    }

    private fun stopExportingVideo(params: Map<String, Any>, result: MethodChannel.Result) = reply(result) {
        android.util.Log.d("FU-RenderPlugin", "stopExportingVideo()")
        glSurfaceViewPlatformViewFactory.stopExportingVideo()
    }
}
