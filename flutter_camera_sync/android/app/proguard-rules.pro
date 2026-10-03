# ==============================================================================
# AeroSync Flutter Android — Production ProGuard & R8 Optimization Rules
# ==============================================================================

# Flutter Core & Plugins
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# WorkManager Background Sync Service
-keep class dev.fluttercommunity.workmanager.** { *; }
-keep class androidx.work.** { *; }
-keepclassmembers class * extends androidx.work.Worker {
    <init>(android.content.Context, androidx.work.WorkerParameters);
}
-keepclassmembers class * extends androidx.work.ListenableWorker {
    <init>(android.content.Context, androidx.work.WorkerParameters);
}

# CameraX & Camera Plugin
-keep class androidx.camera.** { *; }
-dontwarn androidx.camera.**
-dontwarn io.flutter.plugins.camera.**

# SQLite (sqflite)
-keep class com.tekartik.sqflite.** { *; }

# Connectivity Plus
-keep class dev.fluttercommunity.plus.connectivity.** { *; }

# Google Play Core Deferred Components (Suppressed when not packaging dynamic split features)
-dontwarn com.google.android.play.core.**

# Preserve line numbers and source file attributes for crash reporting & stacktraces
-keepattributes SourceFile,LineNumberTable,InnerClasses,Signature,*Annotation*
