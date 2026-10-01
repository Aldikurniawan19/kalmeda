plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.menstracker"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.menstracker"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    applicationVariants.all {
        val variantName = name
        outputs.all {
            val output = this as? com.android.build.gradle.internal.api.BaseVariantOutputImpl
            if (output != null && variantName == "release") {
                output.outputFileName = "Kalmeda.apk"
            }
        }

        if (variantName == "release") {
            assembleProvider.configure {
                doLast {
                    val buildDir = layout.buildDirectory.asFile.get()
                    val flutterApkDir = File(buildDir, "outputs/flutter-apk")
                    val apkReleaseDir = File(buildDir, "outputs/apk/release")
                    val kalmedaInRelease = File(apkReleaseDir, "Kalmeda.apk")
                    val appReleaseInFlutter = File(flutterApkDir, "app-release.apk")

                    flutterApkDir.mkdirs()
                    if (kalmedaInRelease.exists()) {
                        kalmedaInRelease.copyTo(File(flutterApkDir, "Kalmeda.apk"), overwrite = true)
                    } else if (appReleaseInFlutter.exists()) {
                        appReleaseInFlutter.copyTo(File(flutterApkDir, "Kalmeda.apk"), overwrite = true)
                    }
                }
            }
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
