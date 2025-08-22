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
        applicationId = "lu.live"
        minSdk = 24
        targetSdk = 34
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }
    sourceSets["main"].java.srcDirs("src/main/kotlin", "libs")
}
dependencies {
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