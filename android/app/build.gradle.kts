plugins {
    id("com.android.application")
    id("kotlin-android")
    // Flutter plugin harus setelah Android & Kotlin plugin
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.getapp"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.getapp"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // ⚠️ Hanya set NDK abiFilters jika bikin APK spesifik
        ndk {
            abiFilters += setOf("arm64-v8a")  // hanya arm64
        }
    }

    // ⚠️ Jika mau APK spesifik arsitektur
    splits {
        abi {
            isEnable = true
            reset()
            include("arm64-v8a")  // hanya arm64
            isUniversalApk = false
        }
    }

    buildTypes {
        getByName("release") {
            isMinifyEnabled = false
            isShrinkResources = false
            // Ganti dengan release signing config untuk Play Store
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
