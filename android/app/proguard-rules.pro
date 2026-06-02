# Razorpay SDK keep rules
-keep class com.razorpay.** { *; }
-dontwarn com.razorpay.**

# Fix for missing proguard annotations
-keep class proguard.annotation.Keep { *; }
-keep class proguard.annotation.KeepClassMembers { *; }
