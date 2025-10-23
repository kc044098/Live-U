package com.toivan.mtcamera.mt_plugin.view

import android.content.Context
import android.view.View
import android.view.ViewGroup
import io.flutter.plugin.common.MessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import com.nimo.facebeauty.FBEffect

/**
 *  接入Flutter的 PlatformViewFactory
 */
class MtCameraPlatformView(createArgsCodec: MessageCodec<Any>?) : PlatformViewFactory(createArgsCodec) {

    private val lp = ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT)


    private lateinit var cameraView: MtSurfaceCameraView

    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {

        cameraView = MtSurfaceCameraView(context)


        return object : PlatformView {

            override fun getView(): View = cameraView

            override fun dispose() {
                cameraView.release()
                FBEffect.shareInstance().releaseTextureOESRenderer();
            }


        }.apply {
            view.layoutParams = lp
        }

    }


}