# Flutter Rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.provider.** { *; }
-keep class io.flutter.plugin.editing.** { *; }

# Play Core Split Install (required by Flutter embedding)
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }
-dontwarn com.google.android.play.core.**
# Generated Plugin Registrant
-keep class io.flutter.plugins.** { *; }

# Keep native methods and classes for plugins
-keepclasseswithmembers class * {
    native <methods>;
}

-keepclassmembers class * extends enum {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# RevenueCat / Purchases Rules
-keep class com.revenuecat.purchases.** { *; }

# Play Billing Library Rules
-keep class com.android.billingclient.api.** { *; }

# Drift / SQLite Native Rules
-keep class net.sqlcipher.** { *; }
-keep class org.sqlite.** { *; }
-dontwarn org.sqlite.**

# Firebase / Google Play Services Rules
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**
