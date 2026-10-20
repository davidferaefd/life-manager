import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "br.com.david.lifemanager"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "br.com.david.lifemanager"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    val keystorePropertiesFile = rootProject.file("key.properties")
    val keystoreProperties = Properties()
    if (keystorePropertiesFile.exists()) {
        keystorePropertiesFile.inputStream().use(keystoreProperties::load)
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                val requiredProperties = listOf(
                    "storeFile",
                    "storePassword",
                    "keyAlias",
                    "keyPassword",
                )
                val missingProperties = requiredProperties.filter {
                    keystoreProperties.getProperty(it).isNullOrBlank()
                }
                if (missingProperties.isNotEmpty()) {
                    throw GradleException(
                        "android/key.properties não contém: " +
                            missingProperties.joinToString(", ")
                    )
                }

                val uploadKeyFile =
                    file(keystoreProperties.getProperty("storeFile"))
                if (!uploadKeyFile.isFile) {
                    throw GradleException(
                        "Arquivo de chave de upload não encontrado: $uploadKeyFile"
                    )
                }
                storeFile = uploadKeyFile
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

gradle.taskGraph.whenReady {
    val isReleaseBuild = allTasks.any { it.name.endsWith("Release") }
    if (isReleaseBuild && !rootProject.file("key.properties").exists()) {
        throw GradleException(
            "Falta android/key.properties. Configure a chave de assinatura de release " +
                "antes de gerar um pacote para publicação."
        )
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
