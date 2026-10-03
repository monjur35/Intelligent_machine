# ==============================================================================
# GeoPulse Native Android — Production ProGuard & R8 Optimization & Obfuscation Rules
# ==============================================================================

# Preserve line numbers and source file attributes for crash reporting & stacktraces
-keepattributes SourceFile,LineNumberTable,EnclosingMethod,InnerClasses,Signature,*Annotation*

# Kotlin Coroutines & Flow
-keepnames class kotlinx.coroutines.internal.MainDispatcherFactory {}
-keepnames class kotlinx.coroutines.CoroutineExceptionHandler {}
-keepclassmembers class kotlinx.coroutines.** {
    volatile <fields>;
}

# AndroidX DataStore Preferences & Protobuf serialization
-keepclassmembers class * extends androidx.datastore.preferences.core.Preferences {
    *;
}
-keep class androidx.datastore.** { *; }

# Google Play Services Location & FusedLocationProviderClient
-keep class com.google.android.gms.location.** { *; }
-dontwarn com.google.android.gms.location.**

# Dagger Hilt Dependency Injection
-keep class * extends dagger.hilt.internal.GeneratedComponent { *; }
-keep class * implements dagger.hilt.internal.GeneratedComponent { *; }
-keep class androidx.hilt.lifecycle.** { *; }
-keepclassmembers class * {
    @javax.inject.Inject <init>(...);
    @javax.inject.Inject <fields>;
    @javax.inject.Inject <methods>;
}
-dontwarn dagger.hilt.**

# Jetpack Compose Runtime & State
-keep class androidx.compose.runtime.** { *; }
-keepclassmembers class androidx.compose.runtime.Recomposer {
    *;
}
-dontwarn androidx.compose.**

# Domain Models (Preserve immutable data model fields)
-keep class com.monjur.employeeattendance.domain.model.** { *; }
-keepclassmembers class com.monjur.employeeattendance.domain.model.** {
    <fields>;
    <methods>;
}

# Allow aggressive code shrinking and class merging optimizations
-allowaccessmodification
