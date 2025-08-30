package com.faceunity.fuliveplugin.fulive_plugin.render

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.view.View
import android.view.ViewGroup
import com.faceunity.core.entity.FUCameraConfig
import com.faceunity.core.entity.FURenderInputData
import com.faceunity.core.utils.FULogger
import com.faceunity.fuliveplugin.fulive_plugin.config.FaceunityKit
import com.faceunity.fuliveplugin.fulive_plugin.render.renderer.CameraRenderer2

class GLCameraPlatformView(
    context: Context,
    private val callback: () -> Unit
) : BasePlatformView(context) {

    private val cameraRenderer = CameraRenderer2(context, glSurfaceView, FUCameraConfig(), this)

    @Volatile private var wantCameraRunning = false
    private var cameraRenderType = 0 // 0: 單輸入  1: 雙輸入
    private var cameraWidth = 0
    private var cameraHeight = 0
    private var sentFirstFrame = false
    private var isWaitingCameraFrame = false

    private val mainHandler = Handler(Looper.getMainLooper())
    private val reopenCameraAction = Runnable {
        if (surfaceReady && wantCameraRunning) {
            glSurfaceView.queueEvent {
                try {
                    cameraRenderer.reopenCamera()
                    FULogger.d(tag(), "reopenCameraAction -> reopenCamera() on GL thread")
                } catch (t: Throwable) {
                    FULogger.e(tag(), "reopenCameraAction error: ${t.message}")
                }
            }
        } else {
            FULogger.d(tag(), "reopenCameraAction skipped: surfaceReady=$surfaceReady, want=$wantCameraRunning")
        }
    }

    init {
        attachRendererIfNeeded(cameraRenderer) // ★★ 由 Base 幫忙接手 setRenderer 與第一次 kick
        glSurfaceView.preserveEGLContextOnPause = true
    }

    override fun getView(): View = glSurfaceView.also {
        // ★★ 保底：確保不是 0x0
        if (it.layoutParams == null) {
            it.layoutParams = ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT
            )
            FULogger.d(tag(), "getView(): set MATCH_PARENT x MATCH_PARENT")
        }
    }

    override fun onFlutterViewAttached(flutterView: View) {
        super.onFlutterViewAttached(flutterView)
        onHostResume()
        cameraRenderer.onResume()
        kickGL("onFlutterViewAttached -> after onResume") // ★★ 再踢一次
        FULogger.d(tag(), "onFlutterViewAttached() -> gl.onResume + renderer.onResume")
    }

    fun startCamera() {
        FULogger.d(tag(), "startCamera()")
        wantCameraRunning = true
        isWaitingCameraFrame = true
        mainHandler.removeCallbacks(reopenCameraAction)

        if (surfaceReady) {
            glSurfaceView.queueEvent {
                try {
                    FaceunityKit.restoreFaceUnityConfig()
                    cameraRenderer.reopenCamera()
                    FULogger.d(tag(), "startCamera() -> reopenCamera (surfaceReady)")
                } catch (t: Throwable) {
                    FULogger.e(tag(), "startCamera reopen error: ${t.message}")
                }
            }
            mainHandler.postDelayed(reopenCameraAction, 1500)
        } else {
            FULogger.d(tag(), "startCamera() -> wait for surface...")
            kickGL("startCamera(waiting surface)")
            mainHandler.postDelayed(reopenCameraAction, 1500)
        }
    }

    fun stopCamera() {
        FULogger.d(tag(), "stopCamera()")
        wantCameraRunning = false
        mainHandler.removeCallbacks(reopenCameraAction)
        FaceunityKit.storeFaceUnityConfig()
        cameraRenderer.onPause()
        onHostPause() // 停 GLSurfaceView
    }

    fun switchCamera(isFront: Boolean): Boolean {
        cameraRenderer.switchCamera()
        return true
    }

    fun switchRenderInputType(inputType: Int) { cameraRenderType = inputType }

    fun switchCapturePreset(preset: Int) {
        when (preset) {
            0 -> cameraRenderer.fUCamera.changeResolution(640, 480)
            1 -> cameraRenderer.fUCamera.changeResolution(1280, 720)
            2 -> cameraRenderer.fUCamera.changeResolution(1920, 1080)
        }
    }

    fun setCameraExposure(exposure: Double) {
        cameraRenderer.fUCamera.setExposureCompensation(exposure.toFloat())
    }

    fun manualFocus(dx: Double, dy: Double, focusRectSize: Int) {
        cameraRenderer.fUCamera.handleFocus(surfaceWidth, surfaceHeight, dx.toFloat(), dy.toFloat(), focusRectSize)
    }

    fun takePhoto(action: (Boolean) -> Unit) = captureImage(action)

    fun startRecord() {
        if (!isRecording) {
            isRecording = true
            mVideoRecordHelper.startRecording(
                glSurfaceView,
                cameraRenderer.fUCamera.getCameraHeight(),
                cameraRenderer.fUCamera.getCameraWidth()
            )
        }
    }

    fun stopRecord(action: (Boolean) -> Unit) {
        if (isRecording) {
            isRecording = false
            recordVideoActions.add(action)
            mVideoRecordHelper.stopRecording()
        } else {
            action(false)
        }
    }

    override fun provideRender() = cameraRenderer

    override fun notifyFlutterRenderInfo() {
        val debug = "resolution:\n${cameraHeight}x${cameraWidth}\nfps:${calculatedFPS}\nrender time:\n${calculatedRenderTime}ms"
        val data = mapOf("debugInfo" to debug, "faceTracked" to (trackedFaceNumber > 0))
        mRenderFrameListener?.notifyFlutter(data)
    }

    // ---------- OnGlRendererListener ----------
    override fun onSurfaceCreated() {
        super.onSurfaceCreated()
        FULogger.d(tag(), "onSurfaceCreated() want=$wantCameraRunning")
        if (wantCameraRunning) {
            mainHandler.post { reopenCameraAction.run() }
        }
    }

    override fun onRenderBefore(inputData: FURenderInputData?) {
        super.onRenderBefore(inputData)

        if (isWaitingCameraFrame) {
            mainHandler.removeCallbacks(reopenCameraAction)
            isWaitingCameraFrame = false
            FULogger.d(tag(), "first camera frame detected -> cancel fallback")
        }

        cameraWidth = inputData?.width ?: 0
        cameraHeight = inputData?.height ?: 0

        if (!sentFirstFrame && cameraWidth > 0 && cameraHeight > 0) {
            sentFirstFrame = true
            mRenderFrameListener?.notifyFlutter(
                mapOf("type" to "first_frame", "w" to cameraWidth, "h" to cameraHeight)
            )
            FULogger.d(tag(), "#### first frame rendered #### size=${cameraWidth}x${cameraHeight}")
        }

        if (mFURenderKit.makeup == null) {
            if (cameraRenderType == 0) {
                inputData?.imageBuffer = null
            }
        } else {
            inputData?.imageBuffer = null
            inputData?.renderConfig?.isNeedBufferReturn = false
        }
    }

    override fun onDrawFrameAfter() {
        trackStatus()
        benchmarkFPS()
        notifyFlutterRenderInfo()
    }

    override fun dispose() {
        wantCameraRunning = false
        mainHandler.removeCallbacks(reopenCameraAction)
        try { cameraRenderer.onPause() } catch (_: Throwable) {}
        try { onHostPause() } catch (_: Throwable) {}
        cameraRenderer.onDestroy()
        super.dispose()
        callback.invoke()
    }
}