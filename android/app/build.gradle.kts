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
            applicationIdSuffix = ".fullai"
            versionNameSuffix = "-fullai"
            resValue("string", "app_name", "ShikshaPul Full AI")
        }
    }

    // Only the Full-AI flavor receives the large model. It is deliberately a
    // native Android asset so Kotlin can stream it to disk without a 412 MB
    // Dart heap allocation.
    sourceSets {
        getByName("full").assets.srcDir("../../assets")
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
