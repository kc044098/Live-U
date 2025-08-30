package com.faceunity.fuliveplugin.fulive_plugin.render

import android.content.Context
import android.opengl.GLSurfaceView
import android.view.SurfaceHolder
import android.view.View
import android.view.ViewGroup
import com.faceunity.core.entity.FURenderFrameData
import com.faceunity.core.entity.FURenderInputData
import com.faceunity.core.entity.FURenderOutputData
import com.faceunity.core.faceunity.FUAIKit
import com.faceunity.core.faceunity.FURenderKit
import com.faceunity.core.listener.OnGlRendererListener
import com.faceunity.core.media.photo.PhotoRecordHelper
import com.faceunity.core.media.video.OnVideoRecordingListener
import com.faceunity.core.media.video.VideoRecordHelper
import com.faceunity.core.model.facebeauty.FaceBeautyBlurTypeEnum
import com.faceunity.core.renderer.BaseFURenderer
import com.faceunity.core.utils.FULogger
import com.faceunity.core.utils.GlUtil
import com.faceunity.fuliveplugin.fulive_plugin.config.FaceunityConfig
import com.faceunity.fuliveplugin.fulive_plugin.config.FaceunityKit
import com.faceunity.fuliveplugin.fulive_plugin.utils.FileUtils
import com.faceunity.fuliveplugin.fulive_plugin.utils.FuDeviceUtils
import io.flutter.plugin.platform.PlatformView
import java.io.File
import java.util.concurrent.ConcurrentLinkedQueue

abstract class BasePlatformView(private val context: Context) : PlatformView, OnGlRendererListener {

    protected val mFUAIKit = FUAIKit.getInstance()
    protected val mFURenderKit = FURenderKit.getInstance()

    protected val glSurfaceView: GLSurfaceView = GLSurfaceView(context).apply {
        setEGLContextClientVersion(3)
        preserveEGLContextOnPause = true

        // ★★ 1) 監聽 SurfaceHolder：能看到 surface 是否真的建立/改變/銷毀
        holder.addCallback(object : SurfaceHolder.Callback {
            override fun surfaceCreated(holder: SurfaceHolder) {
                FULogger.d(tag(), "SurfaceHolder.surfaceCreated()")
            }
            override fun surfaceChanged(holder: SurfaceHolder, format: Int, width: Int, height: Int) {
                FULogger.d(tag(), "SurfaceHolder.surfaceChanged() ${width}x${height}")
            }
            override fun surfaceDestroyed(holder: SurfaceHolder) {
                FULogger.d(tag(), "SurfaceHolder.surfaceDestroyed()")
            }
        })

        // ★★ 2) 監聽 attach / detach
        addOnAttachStateChangeListener(object : View.OnAttachStateChangeListener {
            override fun onViewAttachedToWindow(v: View) {
                FULogger.d(tag(), "GLSurfaceView.onViewAttachedToWindow() w=${v.width} h=${v.height}")
            }
            override fun onViewDetachedFromWindow(v: View) {
                FULogger.d(tag(), "GLSurfaceView.onViewDetachedFromWindow()")
            }
        })

        // ★★ 3) 監聽實際 layout 結果（可抓到 0x0 的情況）
        viewTreeObserver.addOnGlobalLayoutListener {
            FULogger.d(tag(), "OnGlobalLayout: size=${width}x${height} isShown=$isShown")
        }
    }

    @Volatile protected var surfaceReady = false
    @Volatile protected var rendererAttached = false
    protected var surfaceWidth = 0
    protected var surfaceHeight = 0

    // region 錄製功能
    @Volatile protected var isTakePhoto = false
    @Volatile protected var isRecordingPrepared = false
    protected var isRecording = false
    @Volatile var isViewRendering = false
    protected val takePhotoActions = ConcurrentLinkedQueue<(Boolean) -> Unit>()
    protected val recordVideoActions = ConcurrentLinkedQueue<(Boolean) -> Unit>()

    private fun ensureLayoutParams() {
        if (glSurfaceView.layoutParams == null) {
            glSurfaceView.layoutParams = ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT
            )
            FULogger.d(tag(), "ensureLayoutParams(): set MATCH_PARENT x MATCH_PARENT")
        }
    }

    protected fun attachRendererIfNeeded(renderer: GLSurfaceView.Renderer) {
        ensureLayoutParams()
        if (rendererAttached) return
        try {
            glSurfaceView.setRenderer(renderer)
            rendererAttached = true
            glSurfaceView.renderMode = GLSurfaceView.RENDERMODE_CONTINUOUSLY
            FULogger.d(tag(), "attachRendererIfNeeded: success (CONTINUOUS)")
        } catch (e: IllegalStateException) {
            rendererAttached = true
            FULogger.d(tag(), "attachRendererIfNeeded: already set by others, ignore")
            try {
                glSurfaceView.renderMode = GLSurfaceView.RENDERMODE_CONTINUOUSLY
                FULogger.d(tag(), "set renderMode=CONTINUOUSLY (post-attached)")
            } catch (t: Throwable) {
                FULogger.d(tag(), "set renderMode ignored: ${t.message}")
            }
        }
        kickGL("attachRendererIfNeeded") // ★★
    }

    protected fun kickGL(reason: String) {
        try {
            glSurfaceView.requestRender()
            FULogger.d(tag(), "requestRender() kick [$reason]")
        } catch (t: Throwable) {
            FULogger.d(tag(), "requestRender() ignored: ${t.message}")
        }
    }

    protected val mPhotoRecordHelper = PhotoRecordHelper {
        val path = FileUtils.addBitmapToAlbum(context, it)
        FULogger.d(tag(), "photo onRecordSuccess: $path")
        takePhotoActions.poll()?.invoke(path != null)
    }

    protected val mVideoRecordHelper = VideoRecordHelper(context, object : OnVideoRecordingListener {
        override fun onPrepared() {
            FULogger.d(tag(), "video onPrepared")
            isRecordingPrepared = true
            onVideoRecordPrepared()
        }

        override fun onProcess(time: Long?) {
            FULogger.d(tag(), "video onProcess$time")
        }

        override fun onFinish(file: File) {
            FULogger.d(tag(), "video onFinish$file")
            isRecordingPrepared = false
            onVideoRecordFinish(file)
            val filePath = FileUtils.addVideoToAlbum(context, file)
            if (file.exists()) file.delete()
            recordVideoActions.poll()?.invoke(filePath != null)
        }
    })

    fun captureImage(action: (Boolean) -> Unit) {
        takePhotoActions.add(action)
        isTakePhoto = true
    }

    open fun onVideoRecordPrepared() {}
    open fun onVideoRecordFinish(file: File) {}

    private fun recordingData(outputData: FURenderOutputData?, texMatrix: FloatArray) {
        if (outputData?.texture == null || outputData.texture!!.texId <= 0 || !isViewRendering) return
        if (isRecordingPrepared) {
            mVideoRecordHelper.frameAvailableSoon(
                outputData.texture!!.texId,
                texMatrix,
                GlUtil.IDENTITY_MATRIX
            )
        }
        if (isTakePhoto) {
            isTakePhoto = false
            mPhotoRecordHelper.sendRecordingData(
                outputData.texture!!.texId,
                texMatrix,
                GlUtil.IDENTITY_MATRIX,
                outputData.texture!!.width,
                outputData.texture!!.height
            )
        }
    }
    // endregion

    // region 人臉偵測與 FPS
    private val isShowBenchmark = true
    protected var isAIProcessTrack = true
    protected var aIProcessTrackIgnoreFrame = 0
    protected var trackedFaceNumber = 1

    private var mCurrentFrameCnt = 0
    private val mMaxFrameCnt = 10
    private var mLastOneHundredFrameTimeStamp: Long = 0
    private var mOneHundredFrameFUTime: Long = 0
    private var mFuCallStartTime: Long = 0

    protected var calculatedFPS = 0
    protected var calculatedRenderTime = 0

    protected fun trackStatus() {
        if (!isAIProcessTrack) return
        if (aIProcessTrackIgnoreFrame > 0) {
            aIProcessTrackIgnoreFrame--
            return
        }
        val trackCount = mFUAIKit.isTracking()
        if (trackedFaceNumber != trackCount) trackedFaceNumber = trackCount
    }

    protected var mEnableFaceRender = false

    protected fun benchmarkFPS() {
        if (!isShowBenchmark) return
        if (mEnableFaceRender) {
            mOneHundredFrameFUTime += System.nanoTime() - mFuCallStartTime
        } else {
            mOneHundredFrameFUTime = 0
        }
        if (++mCurrentFrameCnt == mMaxFrameCnt) {
            mCurrentFrameCnt = 0
            val fps = mMaxFrameCnt * 1_000_000_000L / (System.nanoTime() - mLastOneHundredFrameTimeStamp)
            val renderTime = mOneHundredFrameFUTime / mMaxFrameCnt / 1_000_000L
            mLastOneHundredFrameTimeStamp = System.nanoTime()
            mOneHundredFrameFUTime = 0
            calculatedFPS = fps.toInt()
            calculatedRenderTime = renderTime.toInt()
        }
        mEnableFaceRender = false
    }
    // endregion

    // region 給子類調用的 host lifecycle
    open fun onHostResume() {
        FULogger.d(tag(), "onHostResume -> glSurfaceView.onResume()")
        glSurfaceView.onResume()
    }

    open fun onHostPause() {
        FULogger.d(tag(), "onHostPause -> glSurfaceView.onPause()")
        glSurfaceView.onPause()
    }
    // endregion

    override fun onFlutterViewAttached(flutterView: View) {
        FULogger.d(tag(), "onFlutterViewAttached")
        ensureLayoutParams()           // ★★
        kickGL("onFlutterViewAttached")// ★★
    }

    override fun dispose() {
        FULogger.d(tag(), "dispose")
        takePhotoActions.clear()
        recordVideoActions.clear()
    }

    override fun onSurfaceCreated() {
        FULogger.d(tag(), "onSurfaceCreated")
        if (isViewRendering) FURenderKit.getInstance().releaseSafe()
        FaceunityKit.restoreFaceUnityConfig()
        isViewRendering = true
        surfaceReady = true            // ★★ 這個 flag 是 startCamera 的關鍵
    }

    override fun onSurfaceChanged(width: Int, height: Int) {
        FULogger.d(tag(), "onSurfaceChanged: $width x $height")
        surfaceWidth = width
        surfaceHeight = height
    }


    override fun onSurfaceDestroy() {
        FULogger.d(tag(), "onSurfaceDestroy")
        isViewRendering = false
        surfaceReady = false           // ★★
        mFURenderKit.release()
    }

    override fun onRenderBefore(inputData: FURenderInputData?) {
        FULogger.d(tag(), "onRenderBefore: ${inputData?.printMsg()}")
        mEnableFaceRender = true
        if (FaceunityKit.devicePerformanceLevel >= FuDeviceUtils.DEVICE_LEVEL_TWO) {
            cheekFaceConfidenceScore()
        }
        mFuCallStartTime = System.nanoTime()
    }

    override fun onRenderAfter(outputData: FURenderOutputData, frameData: FURenderFrameData) {
        recordingData(outputData, frameData.texMatrix)
        trackStatus()
        benchmarkFPS()
        notifyFlutterRenderInfo()
    }
    // endregion

    private fun cheekFaceConfidenceScore() {
        val score = mFUAIKit.getFaceProcessorGetConfidenceScore(0)
        mFURenderKit.faceBeauty?.let { fb ->
            if (score >= FaceunityConfig.FACE_CONFIDENCE_SCORE) {
                if (fb.blurType != FaceBeautyBlurTypeEnum.EquallySkin) {
                    fb.blurType = FaceBeautyBlurTypeEnum.EquallySkin
                    fb.enableBlurUseMask = true
                }
            } else {
                if (fb.blurType != FaceBeautyBlurTypeEnum.FineSkin) {
                    fb.blurType = FaceBeautyBlurTypeEnum.FineSkin
                    fb.enableBlurUseMask = false
                }
            }
        }
    }

    protected var mRenderFrameListener: NotifyFlutterListener? = null
    fun setRenderFrameListener(listener: NotifyFlutterListener?) { mRenderFrameListener = listener }

    fun setRenderState(isRendering: Boolean) {
        provideRender().setFURenderSwitch(isRendering)
    }

    protected fun tag() = this::class.java.simpleName

    protected abstract fun notifyFlutterRenderInfo()

    abstract fun provideRender(): BaseFURenderer
}