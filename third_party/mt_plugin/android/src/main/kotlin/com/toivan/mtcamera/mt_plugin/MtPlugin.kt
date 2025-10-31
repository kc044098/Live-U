package com.toivan.mtcamera.mt_plugin

import android.content.Context
import android.util.Log
import androidx.annotation.NonNull
import com.toivan.mtcamera.mt_plugin.model.*
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import com.nimo.facebeauty.FBEffect
import com.nimo.facebeauty.model.FBBeautyEnum
import com.nimo.facebeauty.model.FBItemEnum
import com.nimo.facebeauty.model.FBReshapeEnum
import com.nimo.facebeauty.model.FBFilterEnum

/** MtPlugin */
class MtPlugin : FlutterPlugin, MethodCallHandler {

    private lateinit var channel: MethodChannel

    //用于初始化的Context
    private lateinit var applicationContext: Context

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "mt_plugin")
        beautyChannel = MethodChannel(flutterPluginBinding.binaryMessenger, "beauty_plugin")

        applicationContext = flutterPluginBinding.applicationContext

        channel.setMethodCallHandler(this)
        beautyChannel.setMethodCallHandler(object : MethodChannel.MethodCallHandler {

            override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
                Log.d("call.method:", call.method)
                when (call.method) {
                    "startAgoraPush" -> {
                        shouldPushToAgora = true
                        result.success(null)
                    }
                    "stopAgoraPush" -> {
                        shouldPushToAgora = false
                        result.success(null)
                    }
                    //else -> result.notImplemented()
                }
            }

        })
    }


    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {

        Log.d("call.method:", call.method)

        when (call.method) {
            "getPlatformVersion" -> {
                result.success("Android ${android.os.Build.VERSION.RELEASE}")
            }

            MtAction.SET_RENDER_ENABLE.name -> {
                val isEnable: Boolean? = call.argument("enable")
                isEnable?.let {
                    FBEffect.shareInstance().setRenderEnable(isEnable)
                }
            }


            MtAction.SET_FACE_BEAUTY_ENABLE.name -> {
                val isEnable: Boolean? = call.argument("enable")
                isEnable?.let {
                    FBEffect.shareInstance().setRenderEnable(isEnable)
                }
            }


            MtAction.INIT_PATH.name -> {
                val paths = ConstraintsMap()
                paths.putString("maskPath", FBEffect.shareInstance().getARItemPathBy(1))
                paths.putString("stickerPath", FBEffect.shareInstance().getARItemPathBy(0))
                paths.putString("giftPath", FBEffect.shareInstance().getARItemPathBy(2))
                paths.putString("watermarkPath", FBEffect.shareInstance().getARItemPathBy(3))
                result.success(paths.toMap())
            }

            MtAction.INIT_SDK.name -> {
                Log.i("INIT_SDK:", "初始化触发")
                val key: String = call.argument("key") ?: return
                applicationContext.let {

                    //todo fb ---facebeauty--- 初始化SDK
                    FBEffect.shareInstance().initFaceBeauty(it, "466c75f936c848458ffb3f598032042e", object : FBEffect.InitCallback {
                        override fun onInitSuccess() = Unit
                        override fun onInitFailure() = Unit
                    })
                }
            }

            MtAction.SET_WHITENESS_VALUE.name -> {
                val value: Int? = call.argument("value")
                value?.let {
                    FBEffect.shareInstance()
                        .setBeauty(FBBeautyEnum.FBBeautySkinWhitening.value, value)
                }
            }


            MtAction.SET_BLURRINESS_VALUE.name -> {
                val value: Int? = call.argument("value")
                value?.let {
                    FBEffect.shareInstance()
                        .setBeauty(FBBeautyEnum.FBBeautyClearSmoothing.value, value)
                }
            }

            MtAction.SET_PORTRAIT_NAME.name -> {
                val value: String? = call.argument("name")
                value?.let {
                    FBEffect.shareInstance().setAISegEffect(value)
                }
            }

            MtAction.SET_ROSINESS_VALUE.name -> {
                val value: Int? = call.argument("value")
                value?.let {
                    FBEffect.shareInstance()
                        .setBeauty(FBBeautyEnum.FBBeautySkinRosiness.value, value)
                }
            }

            MtAction.SET_CLEAR_NESS_VALUE.name -> {
                val value: Int? = call.argument("value")
                value?.let {
                    FBEffect.shareInstance()
                        .setBeauty(FBBeautyEnum.FBBeautyImageSharpness.value, value)
                }
            }

            MtAction.SET_BRIGHTNESS_VALUE.name -> {
                val value: Int? = call.argument("value")
                value?.let {
                    FBEffect.shareInstance()
                        .setBeauty(FBBeautyEnum.FBBeautyImageBrightness.value, value)
                }
            }
            //去黑眼圈
            MtAction.SET_UNDEREYE_CIRCLES_VALUE.name -> {
                val value: Int? = call.argument("value")
                value?.let {
                    FBEffect.shareInstance()
                        .setBeauty(FBBeautyEnum.FBBeautyDarkCircleLessening.value, value)
                }
            }
            //去法令纹
            MtAction.SET_NASOLABIAL_FOLD_VALUE.name -> {
                val value: Int? = call.argument("value")
                value?.let {
                    FBEffect.shareInstance()
                        .setBeauty(FBBeautyEnum.FBBeautyNasolabialLessening.value, value)
                }
            }

            MtAction.SET_FACE_SHAPE_ENABLE.name -> {
                val value: Boolean? = call.argument("value")
                value?.let {
                    FBEffect.shareInstance().setRenderEnable(value)
                }
            }

            MtAction.SET_EYE_ENLARGING_VALUE.name -> {
                val value: Int? = call.argument("value")
                value?.let {
                    FBEffect.shareInstance()
                        .setReshape(FBReshapeEnum.FBReshapeEyeEnlarging.value, value);
                }
            }

            MtAction.SET_EYE_ROUNDING_VALUE.name -> {
                val value: Int? = call.argument("value")
                value?.let {
                    FBEffect.shareInstance()
                        .setReshape(FBReshapeEnum.FBReshapeEyeRounding.value, value);
                }
            }

            MtAction.SET_CHEEK_V_VALUE.name -> {
                val value: Int? = call.argument("value")
                value?.let {
                    FBEffect.shareInstance()
                        .setReshape(FBReshapeEnum.FBReshapeCheekVShaping.value, value);
                }
            }

            MtAction.SET_FACE_SHORTENING_VALUE.name -> {
                val value: Int? = call.argument("value")
                value?.let {
                    FBEffect.shareInstance()
                        .setReshape(FBReshapeEnum.FBReshapeCheekShortening.value, value);
                }
            }

            MtAction.SET_CHEEK_NARROWING_VALUE.name -> {
                val value: Int? = call.argument("value")
                value?.let {
                    FBEffect.shareInstance()
                        .setReshape(FBReshapeEnum.FBReshapeCheekNarrowing.value, value);
                }
            }

            MtAction.SET_CHEEK_THINNING_VALUE.name -> {
                val value: Int? = call.argument("value")
                value?.let {
                    FBEffect.shareInstance()
                        .setReshape(FBReshapeEnum.FBReshapeCheekThinning.value, value);
                }
            }

            MtAction.SET_CHIN_TRIMMING_VALUE.name -> {
                val value: Int? = call.argument("value")
                value?.let {
                    FBEffect.shareInstance()
                        .setReshape(FBReshapeEnum.FBReshapeChinTrimming.value, value);
                }
            }

            MtAction.SET_FOREHEAD_TRIMMING_VALUE.name -> {
                val value: Int? = call.argument("value")
                value?.let {
                    FBEffect.shareInstance()
                        .setReshape(FBReshapeEnum.FBReshapeForeheadTrimming.value, value);
                }
            }

            MtAction.SET_MOUTH_TRIMMING_VALUE.name -> {
                val value: Int? = call.argument("value")
                value?.let {
                    FBEffect.shareInstance()
                        .setReshape(FBReshapeEnum.FBReshapeMouthTrimming.value, value);
                }
            }

            MtAction.SET_NOSE_THINNING_VALUE.name -> {
                val value: Int? = call.argument("value")
                value?.let {
                    FBEffect.shareInstance()
                        .setReshape(FBReshapeEnum.FBReshapeNoseThinning.value, value);
                }
            }

            MtAction.SET_NOSE_ENLARGING_VALUE.name -> {
                val value: Int? = call.argument("value")
                value?.let {
                    FBEffect.shareInstance()
                        .setReshape(FBReshapeEnum.FBReshapeNoseEnlarging.value, value);
                }
            }


            MtAction.SET_EYE_SPACING_TRIMMING_VALUE.name -> {
                val value: Int? = call.argument("value")
                value?.let {
                    FBEffect.shareInstance()
                        .setReshape(FBReshapeEnum.FBReshapeEyeSpaceTrimming.value, value);
                }
            }

            MtAction.SET_EYE_CORNER_TRIMMING_VALUE.name -> {
                val value: Int? = call.argument("value")
                value?.let {
                    FBEffect.shareInstance()
                        .setReshape(FBReshapeEnum.FBReshapeEyeCornerTrimming.value, value);
                }
            }

            MtAction.SET_DYNAMIC_STICKER_NAME.name -> {
                val value: String? = call.argument("name")
                value?.let {
                    Log.d("应用贴纸:", value)
                    FBEffect.shareInstance().setARItem(FBItemEnum.FBItemSticker.value, value)
                }
            }

            MtAction.SET_EXPRESSION_RECREATION_NAME.name -> {
                val value: String? = call.argument("name")
                value?.let {
                }
            }

            MtAction.SET_MASK_NAME.name -> {
                val value: String? = call.argument("name")
                value?.let {
                    FBEffect.shareInstance().setARItem(FBItemEnum.FBItemMask.value, value)
                }
            }

            MtAction.SET_GIFT_NAME.name -> {
                val value: String? = call.argument("name")
                value?.let {
                    FBEffect.shareInstance().setARItem(FBItemEnum.FBItemGift.value, value)
                }
            }

            MtAction.SET_WATERMARK_NAME.name -> {
                val value: String? = call.argument("name")
                value?.let {
                    FBEffect.shareInstance().setARItem(FBItemEnum.FBItemWatermark.value, value)
                }
            }

            MtAction.SET_WATER_NAME.name -> {

                val name: String? = call.argument("name")
                val x: Int? = call.argument("x")
                val y: Int? = call.argument("y")
                val ratio: Int? = call.argument("ratio")

                name?.let {
                    FBEffect.shareInstance().setARItem(FBItemEnum.FBItemWatermark.value, name)
                }

            }

            MtAction.SET_PHILTRUM_TRIMMING_VALUE.name -> {
                val value: Int? = call.argument("value")
                value?.let {
                    FBEffect.shareInstance()
                        .setReshape(FBReshapeEnum.FBReshapePhiltrumTrimming.value, value);
                }
            }


            MtAction.SET_NOSE_APEX_LESSENING_VALUE.name -> {
                val value: Int? = call.argument("value")
                value?.let {
                    FBEffect.shareInstance()
                        .setReshape(FBReshapeEnum.FBReshapeNoseApexLessening.value, value);
                }
            }

            MtAction.SET_TEMPLE_ENLARG_ING_VALUE.name -> {
                val value: Int? = call.argument("value")
                value?.let {
                    FBEffect.shareInstance()
                        .setReshape(FBReshapeEnum.FBReshapeTempleEnlarging.value, value);
                }
            }

            MtAction.SET_FACE_LESSENING_VALUE.name -> {
                val value: Int? = call.argument("value")
                value?.let {
                    FBEffect.shareInstance()
                        .setReshape(FBReshapeEnum.FBReshapeFaceLessening.value, value);
                }
            }

            MtAction.SET_HEAD_LESSENING_VALUE.name -> {
                val value: Int? = call.argument("value")
                value?.let {
                    FBEffect.shareInstance()
                        .setReshape(FBReshapeEnum.FBReshapeHeadLessening.value, value);
                }
            }

            MtAction.SET_NOSE_ROOT_RNLARING.name -> {
                val value: Int? = call.argument("value")
                value?.let {
                    FBEffect.shareInstance()
                        .setReshape(FBReshapeEnum.FBReshapeNoseRootEnlarging.value, value);
                }
            }

            MtAction.SET_JAW_BONE_THINNING_VALUE.name -> {
                val value: Int? = call.argument("value")
                value?.let {
                    FBEffect.shareInstance()
                        .setReshape(FBReshapeEnum.FBReshapeJawboneThinning.value, value);
                }
            }

            MtAction.SET_CHEEK_BONE_THINNING.name -> {
                val value: Int? = call.argument("value")
                value?.let {
                    FBEffect.shareInstance()
                        .setReshape(FBReshapeEnum.FBReshapeCheekboneThinning.value, value);
                }
            }

            MtAction.SET_MOUTH_SMILING_ENLARGING_VALUE.name -> {
                val value: Int? = call.argument("value")
                value?.let {
                    FBEffect.shareInstance()
                        .setReshape(FBReshapeEnum.FBReshapeMouthSmiling.value, value);
                }
            }

            MtAction.SET_ATMOSPHERE_ITEM_NAME.name -> {
                val value: String? = call.argument("name")
                value?.let {
                    FBEffect.shareInstance().setARItem(FBItemEnum.FBItemGift.value, value)
                }
            }

            MtAction.SET_BEAUTY_FILTER_NAME.name -> {
                val name: String? = call.argument("name")
                val value: Int? = call.argument("value")
                value?.let {
                    name?.let {
                        FBEffect.shareInstance().setFilter(FBFilterEnum.FBFilterBeauty.value, name)
                    }
                }
            }

            MtAction.SET_EFFECT_FILTER_TYPE.name -> {

                val name: String? = call.argument("name")

                val value: Int = call.argument("progress") ?: 0


                name?.let {
                    FBEffect.shareInstance().setFilter(FBFilterEnum.FBFilterEffect.value, name)
                }

            }

            MtAction.SET_FUNNY_FILTER_TYPE.name -> {
                val filterName: String? = call.argument("name")
                filterName?.let {
                    FBEffect.shareInstance().setFilter(FBFilterEnum.FBFilterFunny.value, filterName)
                }
            }
//            MtAction.SET_BEAUTY_STYLE.name -> {
//                val type: Int? = call.argument("type")
//                type?.let {
//                    FBEffect.shareInstance().setStyle(type)
//                }
//            }
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        beautyChannel.setMethodCallHandler(null)
    }

    companion object {
        lateinit var beautyChannel: MethodChannel
        var shouldPushToAgora: Boolean = false
    }
}
