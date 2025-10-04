## Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

## Supabase
-keep class io.supabase.** { *; }
-keepattributes *Annotation*

## Gson (if used by supabase)
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

## Keep generic signature of Call, Response (R8 full mode strips signatures from non-kept items).
-keep,allowobfuscation,allowshrinking interface retrofit2.Call
-keep,allowobfuscation,allowshrinking class retrofit2.Response

## With R8 full mode generic signatures are stripped for classes that are not
## kept. Suspend functions are wrapped in continuations where the type argument
## is used.
-keep,allowobfuscation,allowshrinking class kotlin.coroutines.Continuation

## For native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

## Keep setters in Views so that animations can still work.
-keepclassmembers public class * extends android.view.View {
    void set*(***);
    *** get*();
}

## For enumeration classes
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

## Keep model classes (adjust package name to match your project)
-keep class com.afdyl.** { *; }
-keep class afdyl.** { *; }

## AudioPlayers
-keep class xyz.luan.audioplayers.** { *; }

## Geolocator
-keep class com.baseflow.geolocator.** { *; }

## Permission Handler  
-keep class com.baseflow.permissionhandler.** { *; }

## Speech to Text
-keep class com.csdcorp.speech_to_text.** { *; }

## Flutter TTS
-keep class com.tundralabs.fluttertts.** { *; }
