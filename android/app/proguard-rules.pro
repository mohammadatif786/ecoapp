# Flutter ProGuard Rules

# Stripe Android SDK Rules
-keep class com.stripe.android.** { *; }
-keep interface com.stripe.android.** { *; }
-dontwarn com.stripe.android.**

# Add other keep rules if necessary for other plugins
-keep class com.google.firebase.** { *; }
-keep class io.flutter.plugins.** { *; }
