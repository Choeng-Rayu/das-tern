# Flutter specific
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Google Play Core (Fix R8 missing classes)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# Keep Google Sign In
-keep class com.google.android.gms.auth.** { *; }
-keep class com.google.api.** { *; }

# Keep HTTP client
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }
-keep class okio.** { *; }

# Keep Dart runtime
-keep class dart.** { *; }

# Keep model classes
-keep class com.dastern.app.** { *; }

# Keep SQLite
-keep class net.sqlcipher.** { *; }
-keep class net.sqlcipher.database.** { *; }

# Obfuscation
# R8 (used by Flutter) does NOT support -allowobfuscation
# R8 handles obfuscation automatically when minifyEnabled=true
# This allows obfuscation of all classes referenced by reflection
