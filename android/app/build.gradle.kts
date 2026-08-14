import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use { input ->
        keystoreProperties.load(input)
    }
}
val releaseRequested = gradle.startParameter.taskNames.any {
    it.contains("release", ignoreCase = true)
}
val fullBundleRequested = gradle.startParameter.taskNames.any {
    it.contains("bundleFull", ignoreCase = true)
}
val fullApkRequested = gradle.startParameter.taskNames.any {
    it.contains("assembleFull", ignoreCase = true)
}
if (releaseRequested && !keystorePropertiesFile.exists()) {
    throw GradleException(
        "Release signing is not configured. Create android/key.properties; " +
            "use `flutter build apk --debug` only for local testing."
    )
}

android {
    namespace = "com.logicbuilder8.shikshapulprep"
    
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    buildFeatures {
        buildConfig = true
        resValues = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.logicbuilder8.shikshapulprep"
        
        // Native offline llama.cpp uses Android SharedMemory (API 26+).
        minSdk = 26
        targetSdk = 36
        
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    flavorDimensions += "modelTier"
    productFlavors {
        create("lite") {
            dimension = "modelTier"
            resValue("string", "app_name", "ShikshaPul")
            ndk {
                // M11/M12 variants can run a 32-bit userspace even when the
                // chipset is 64-bit. Lite ships both common phone ABIs.
                abiFilters += listOf("armeabi-v7a", "arm64-v8a")
            }
        }
        create("full") {
            dimension = "modelTier"
            // Full AI updates the same Play listing and installed application.
            // The Lite/Full distinction is a release packaging choice, not a
            // separate product identity.
            resValue("string", "app_name", "ShikshaPul")
            ndk {
                // llama_flutter_android publishes its inference libraries for
                // ARM64. Do not offer Full AI to unsupported 32-bit/x86 phones;
                // those devices remain supported by the Lite release.
                abiFilters += listOf("arm64-v8a")
            }
        }
    }

    // Google Play delivers the 412 MB model as an install-time asset pack so
    // it does not exceed the base-module size limit. A standalone Full APK
    // still embeds the same asset for direct/offline device testing.
    if (fullBundleRequested) {
        assetPacks += listOf(":qwen_model")
    }
    if (fullApkRequested) {
        sourceSets.getByName("full").assets.srcDir("../../assets")
    }
    if (fullBundleRequested || fullApkRequested) {
        packaging {
            jniLibs.excludes += setOf(
                "lib/armeabi-v7a/**",
                "lib/x86_64/**",
            )
        }
    }

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.findByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
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
