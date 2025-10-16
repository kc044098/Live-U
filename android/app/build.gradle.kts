import java.util.Properties
import java.io.FileInputStream

val keystorePropsFile = rootProject.file("key.properties")
val keystoreProps = Properties().apply {
    if (keystorePropsFile.exists()) {
        load(FileInputStream(keystorePropsFile))
    }
}

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("com.google.gms.google-services")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "lu.live"
    compileSdk = 36
    ndkVersion = "27.0.12077973"

    defaultConfig {
        minSdk = 24
        targetSdk = 34
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // FaceUnity/CNama 常見只針對 arm 平台，避免包 x86 導致缺 so 閃退
        ndk {
            abiFilters += listOf("arm64-v8a", "armeabi-v7a")
        }

        manifestPlaceholders.putAll(
            mapOf(
                "facebookAppId" to "763928952697178",
                "fbLoginProtocolScheme" to "fb763928952697178"
            )
        )
    }

    flavorDimensions += "env"
    productFlavors {
        create("dev") {          // ← 測試版
            dimension = "env"
            applicationId = "lu.live"
            resValue("string", "app_name", "LiveU Talk Dev")
        }
        create("prod") {         // ← 正式版
            dimension = "env"
            applicationId = "liveu.live"
            resValue("string", "app_name", "LiveU Talk")
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
        isCoreLibraryDesugaringEnabled = true
    }
    kotlinOptions { jvmTarget = "1.8" }
    aaptOptions {
        noCompress += setOf("bundle", "js", "csv")
    }

    // 讓 app module 讀到我們自製/第三方 java 原始碼
    sourceSets["main"].java.srcDirs("src/main/kotlin", "libs")

    sourceSets["main"].assets.srcDirs("src/main/assets")

    signingConfigs {
        create("release") {
            // 若 key.properties 缺少欄位會拋例外；請確認都填了
            storeFile = file(keystoreProps["storeFile"] as String)
            storePassword = keystoreProps["storePassword"] as String
            keyAlias = keystoreProps["keyAlias"] as String
            keyPassword = keystoreProps["keyPassword"] as String
            //（可省略）v1/v2 預設為啟用，不特別設也可以
            // isV1SigningEnabled = true
            // isV2SigningEnabled = true
        }
    }

    buildTypes {
        getByName("debug") {
            isMinifyEnabled = false
        }
        getByName("release") {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            // ★ 重點：讓 release 用上面的簽章
            signingConfig = signingConfigs.getByName("release")
        }
    }


    // ⚠️ 新增：避免資源被壓縮或打包時處理不當
    packaging {
        jniLibs {
            useLegacyPackaging = false
            // 如需保留符號（只在你想要可讀崩潰堆疊時開）
            // keepDebugSymbols += listOf("**/*.so")
        }
        resources {
            // 若遇到 META-INF 衝突，可保留
            excludes += listOf(
                "META-INF/**",
                "okhttp3/internal/publicsuffix/**"
            )

        }

    }
    androidResources {
        noCompress += setOf("bundle", "model", "dat", "js")
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
    implementation("com.google.android.play:feature-delivery:2.1.0")
    implementation("com.google.android.play:core-common:2.0.4")
    implementation("com.google.android.play:app-update:2.1.0")
    implementation("com.google.android.play:review:2.0.1")
    implementation("androidx.annotation:annotation-jvm:1.9.1")
    implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk8")
    implementation("com.google.firebase:firebase-auth:23.2.1")
    implementation("com.google.firebase:firebase-core:21.1.1")

    implementation("androidx.media3:media3-exoplayer:1.8.0")
    implementation("androidx.media3:media3-exoplayer-hls:1.8.0")
    implementation("androidx.media3:media3-ui:1.8.0")
    implementation("androidx.media3:media3-datasource-okhttp:1.8.0")
    implementation("androidx.media3:media3-datasource:1.8.0")
    implementation("com.squareup.okhttp3:okhttp:5.1.0")
    implementation("org.jellyfin.media3:media3-ffmpeg-decoder:1.8.0+1")
    implementation("com.github.bumptech.glide:glide:4.16.0")
    implementation("androidx.camera:camera-video:1.4.2")
}

flutter {
    source = "../.."
}
