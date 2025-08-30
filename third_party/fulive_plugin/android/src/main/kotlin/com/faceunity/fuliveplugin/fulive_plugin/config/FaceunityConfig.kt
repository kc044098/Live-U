package com.faceunity.fuliveplugin.fulive_plugin.config

import io.flutter.FlutterInjector
import java.io.File

object FaceunityConfig {

    @JvmStatic var BASE_DIR: String = "faceunity"  // 這會被 initFromAssets 設掉

    val BUNDLE_AI_FACE get() = "$BASE_DIR/model/ai_face_processor.bundle"
    val BUNDLE_AI_HUMAN get() = "$BASE_DIR/model/ai_human_processor.bundle"

    val BUNDLE_FACE_BEAUTIFICATION get() = "$BASE_DIR/graphics/face_beautification.bundle"
    val BUNDLE_FACE_MAKEUP get() = "$BASE_DIR/graphics/face_makeup.bundle"
    val BUNDLE_BODY_BEAUTY get() = "$BASE_DIR/graphics/body_slim.bundle"
    val BUNDLE_CONTROLLER_CPP get() = "$BASE_DIR/graphics/controller_cpp.bundle"

    @JvmField
    var BLACK_LIST: String = "$BASE_DIR/config/blackList.json"


    // 提供一個安全的 setter，讓你在 initFromAssets 時一口氣更新
    @JvmStatic
    fun setBaseDir(dir: String) {
        BASE_DIR = dir
        BLACK_LIST = "$BASE_DIR/config/blackList.json"
        // 其餘 bundle 路徑是動態 getter，無需同步
    }

    const val FACE_CONFIDENCE_SCORE = 0.95f

    fun makeupCombinationBundlePath(name: String) =
        "$BASE_DIR/makeup/combination_bundle/$name.bundle"

    @JvmStatic
    fun makeupItemBundlePath(name: String) =
        "$BASE_DIR/makeup/item_bundle/$name.bundle"

    fun flutterAssetsPath(fileName: String): String {
        return FlutterInjector.instance().flutterLoader()
            .getLookupKeyForAsset("lib/resource/jsons/makeup/combination/${fileName}")
    }
}