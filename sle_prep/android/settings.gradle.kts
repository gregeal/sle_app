pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "9.0.1" apply false
    // Kept while flutter_tts, flutter_webrtc, and speech_to_text still apply
    // KGP themselves (they are at their latest versions; removing this pin
    // makes Gradle fall back to an older KGP and a louder warning). Drop it
    // once those plugins migrate to Flutter's built-in Kotlin support.
    id("org.jetbrains.kotlin.android") version "2.3.20" apply false
}

include(":app")
