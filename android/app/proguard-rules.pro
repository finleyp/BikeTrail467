#Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Basic ProGuard rules for Firebase Android SDK 2.0.0+
-keep class com.firebase.** { *; }
-keep class org.apache.** { *; }
-keepnames class com.fasterxml.jackson.** { *; }
-keepnames class javax.servlet.** { *; }
-keepnames class org.ietf.jgss.** { *; }
-dontwarn org.apache.**
-dontwarn org.w3c.dom.**
-keepattributes

#
# Proguard config for a Google Maps Android API sample project.
#
# This file only contains the proguard options required by the Google Maps
# Android API v2. You should use these settings in addition to those provided by the
# Android SDK (<sdk>/tools/proguard/proguard-android-optimize.txt).
#
# For more details on the use of proguard in Android, please read:
# http://proguard.sourceforge.net/manual/examples.html#androidapplication
-optimizations !code/simplification/variable
-keep public class * extends android.app.Activity
-keep public class * extends android.app.Fragment
-keep public class * extends android.support.v4.app.Fragment
# The Maps Android API uses custom parcelables.
# Use this rule (which is slightly broader than the standard recommended one)
# to avoid obfuscating them.
-keepclassmembers class * implements android.os.Parcelable {
    static *** CREATOR;
}
# The Maps Android API uses serialization.
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}