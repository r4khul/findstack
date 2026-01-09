# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Keep MainActivity as it's the entry point
-keep class com.rakhul.unfilter.MainActivity { *; }

# Keep our custom classes to ensure internal logic (MethodChannels helpers) is preserved
# Since we manually invoke these from MainActivity, R8 should track them, but explicit keep
# prevents accidental stripping or aggressive obfuscation if future reflection is added.
-keep class com.rakhul.unfilter.** { *; }

# Default Android checks and harmless warnings
-dontwarn android.support.**
-dontwarn androidx.**
-dontwarn io.flutter.**
