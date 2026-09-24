# Flutter Proguard / R8 Rules for Release Optimization

# Keep Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Supabase and Postgrest serialization / models
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Flutter deferred component / Play Core compatibility rules
-dontwarn com.google.android.play.core.**

# Flutter Local Notifications & Desugaring
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-dontwarn com.dexterous.flutterlocalnotifications.**

