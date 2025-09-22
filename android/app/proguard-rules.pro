# Ne Yesem App ProGuard Rules

# Keep Flutter classes
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Keep our app classes
-keep class com.example.ne_yesem.** { *; }

# Keep JSON serialization classes
-keepattributes *Annotation*
-keepclassmembers class ** {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Keep camera and ML Kit classes
-keep class com.google.mlkit.** { *; }
-keep class androidx.camera.** { *; }

# Keep speech recognition classes
-keep class androidx.speech.** { *; }

# Keep database classes
-keep class net.sqlcipher.** { *; }

# Don't obfuscate debugging info
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile