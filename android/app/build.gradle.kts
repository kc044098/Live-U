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
        versionCode = 1
        versionName = "1.0.0"
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
}

flutter {
    source = "../.."
}