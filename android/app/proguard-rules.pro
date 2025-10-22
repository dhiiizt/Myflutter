# ======== KEEP SHIZUKU API ==========
-keep class rikka.shizuku.** { *; }
-keep interface rikka.shizuku.** { *; }
-dontwarn rikka.shizuku.**

# ======== KEEP REFLECTION TARGETS ==========
# karena kamu pakai Class.forName("rikka.shizuku.Shizuku")
-keepnames class rikka.shizuku.Shizuku
-keepclassmembers class rikka.shizuku.Shizuku { *; }

# ======== KEEP BINDER/SERVICE ==========
-keep class * extends android.os.Binder { *; }
-keep class * extends android.app.Service { *; }

# ======== KEEP YOUR MAIN ACTIVITY ==========
-keep class com.example.getapp.MainActivity { *; }

# ======== KEEP ALL FLUTTER PLUGINS ==========
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**