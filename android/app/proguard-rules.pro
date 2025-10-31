# FaceUnity / CNama：避免被混淆/移除，否則會出現 "FaceUnity undefined" 或 native crash
-keep class com.faceunity.** { *; }
-keep class com.faceunity.wrapper.** { *; }
-keep class com.faceunity.wrapper.authpack { *; }

# 你貼的 authpack 在套件名是這個（兩個都保險保留）
-keep class com.faceunity.faceunity_plugin.authpack { *; }
-keep class com.faceunity.fuliveplugin.** { *; }
-dontwarn com.faceunity.**

-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }
-dontwarn com.google.android.play.core.**

# 反射/JNI 常見保護
-keep class **.R
-keep class **.R$* { *; }
-keep class * extends java.lang.Exception

# 若使用 EventChannel/MethodChannel 反射名
-keep class io.flutter.plugin.common.** { *; }
-keep class io.flutter.embedding.engine.** { *; }