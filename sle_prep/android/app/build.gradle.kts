import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val releaseTaskRequested = gradle.startParameter.taskNames.any {
    it.contains("release", ignoreCase = true)
}
if (releaseTaskRequested && !keystorePropertiesFile.isFile) {
    throw GradleException(
        "Android release signing is not configured. Copy " +
            "android/key.properties.example to android/key.properties, " +
            "set the private keystore values, then retry.",
    )
}
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}

fun requiredKeystoreProperty(name: String): String {
    val value = keystoreProperties.getProperty(name)
    if (value.isNullOrEmpty()) {
        throw GradleException("Missing '$name' in android/key.properties")
    }
    return value
}

val releaseStoreFile =
    if (keystorePropertiesFile.exists()) {
        rootProject.file(requiredKeystoreProperty("storeFile")).also {
            if (!it.isFile) {
                throw GradleException(
                    "The release keystore configured by android/key.properties does not exist: $it",
                )
            }
        }
    } else {
        null
    }

android {
    namespace = "ca.gregeal.sle_prep"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "ca.gregeal.sle_prep"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                keyAlias = requiredKeystoreProperty("keyAlias")
                keyPassword = requiredKeystoreProperty("keyPassword")
                storeFile = releaseStoreFile
                storePassword = requiredKeystoreProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            // Release tasks fail above without key.properties and never fall
            // back to the shared debug key.
            if (keystorePropertiesFile.exists()) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
