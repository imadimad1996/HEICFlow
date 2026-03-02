plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

fun projectSecret(name: String): String? =
    providers.gradleProperty(name)
        .orElse(providers.environmentVariable(name))
        .orNull

val releaseStoreFilePath = projectSecret("MY_RELEASE_STORE_FILE")
val releaseStorePassword = projectSecret("MY_RELEASE_STORE_PASSWORD")
val releaseKeyPassword = projectSecret("MY_RELEASE_KEY_PASSWORD")
val releaseKeyAlias = projectSecret("MY_RELEASE_KEY_ALIAS")
val hasReleaseSigning =
    listOf(
        releaseStoreFilePath,
        releaseStorePassword,
        releaseKeyPassword,
        releaseKeyAlias,
    ).all { !it.isNullOrBlank() }

android {
    namespace = "com.heicflow.heicflow"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.heicflow.heicflow"
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                storeFile = file(requireNotNull(releaseStoreFilePath))
                storePassword = releaseStorePassword
                keyAlias = releaseKeyAlias
                keyPassword = releaseKeyPassword
            }
        }
    }

    buildTypes {
        release {
            if (hasReleaseSigning) {
                signingConfig = signingConfigs.getByName("release")
            } else {
                logger.warn(
                    "Release signing properties not found. Falling back to debug signing. " +
                        "Set MY_RELEASE_* in ~/.gradle/gradle.properties or environment variables.",
                )
                signingConfig = signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}
