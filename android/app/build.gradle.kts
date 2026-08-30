import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")

if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.keyva.app"
    compileSdk = maxOf(flutter.compileSdkVersion, flutter.targetSdkVersion, 34)
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.keyva.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        // Myket requires targetSdk >= 34 from 1 Aban 1405 (23 Oct 2026).
        targetSdk = maxOf(flutter.targetSdkVersion, 34)
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    flavorDimensions += "store"
    productFlavors {
        create("bazaar") {
            dimension = "store"
            isDefault = true
        }
        create("myket") {
            dimension = "store"
        }
    }
    signingConfigs {
    create("release") {
        keyAlias = keystoreProperties["keyAlias"] as String
        keyPassword = keystoreProperties["keyPassword"] as String
        storeFile = file(keystoreProperties["storeFile"] as String)
        storePassword = keystoreProperties["storePassword"] as String
    }
}

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}

afterEvaluate {
    // Flutter looks for app-debug.apk; store flavors emit app-bazaar-debug.apk.
    fun copyDefaultFlavorApk(buildType: String) {
        val buildRoot =
            rootProject.layout.buildDirectory
                .get()
                .asFile
        val flutterApkDir = buildRoot.resolve("app/outputs/flutter-apk")
        flutterApkDir.mkdirs()
        val source =
            listOf(
                flutterApkDir.resolve("app-bazaar-$buildType.apk"),
                buildRoot.resolve(
                    "app/outputs/apk/bazaar/$buildType/app-bazaar-$buildType.apk",
                ),
            ).firstOrNull { it.exists() } ?: return
        source.copyTo(flutterApkDir.resolve("app-$buildType.apk"), overwrite = true)
    }

    listOf("Debug", "Profile", "Release").forEach { buildType ->
        val typeLower = buildType.lowercase()
        tasks.matching { it.name == "assemble$buildType" }.configureEach {
            doLast {
                copyDefaultFlavorApk(typeLower)
            }
        }
    }
}
