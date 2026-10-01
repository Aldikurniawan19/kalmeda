## Flutter wrapper & engine
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

## Play Store deferred components (suppress missing Play Core warnings)
-dontwarn com.google.android.play.core.**

## flutter_local_notifications
-keep class com.dexterous.** { *; }
-keep class com.dexterous.flutterlocalnotifications.** { *; }

## Gson / Firebase / Google APIs
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-dontwarn java.lang.invoke.**
-keep class com.google.gson.** { *; }
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**
