# Flutter ProGuard Rules

# Stripe optimization rules (Fix for R8 missing classes error)
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivity$g
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivityStarter$Args
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivityStarter$Error
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivityStarter
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningEphemeralKeyProvider

# Add other keep rules if necessary for other plugins
-keep class com.google.firebase.** { *; }
-keep class io.flutter.plugins.** { *; }
