import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing credentials, kept out of version control in
// android/key.properties (see android/key.properties.example).
//
// Absent on a machine that only runs debug builds, which is why every use is
// guarded rather than assumed — a missing file must not break `flutter run`.
val keystoreProperties = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) file.inputStream().use { load(it) }
}
val hasReleaseKeystore = keystoreProperties.getProperty("storeFile") != null

android {
    namespace = "com.juliusboakye.linguago"
    // permission_handler_android requires compileSdk 37.
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.juliusboakye.linguago"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // flutter_gemma requires minSdk 24.
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // LiteRT-LM's FFI runtime (.litertlm models, GPU delegate, audio encoder)
        // ships arm64-v8a only. x86_64/armeabi-v7a would only support MediaPipe
        // .task text inference, which cannot do audio — so restrict to arm64.
        // Note: this means x86_64 Android emulators won't run the app; use an
        // arm64 emulator (native on Apple Silicon) or a physical device.
        ndk {
            abiFilters += listOf("arm64-v8a")
        }
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                storeFile = rootProject.file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            // Falls back to the debug key when no keystore is configured, so a
            // fresh clone can still run a release build. An APK signed that way
            // installs for testing but can never be updated in place by a
            // properly-signed build — Android treats a different signature as a
            // different app, and the user would have to uninstall, losing the
            // 2.6 GB model with it. Set up key.properties before sharing builds.
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
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
