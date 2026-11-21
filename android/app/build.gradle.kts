plugins {
    id("com.android.application")
    // Flutter Gradle Plugin applies Kotlin when android.builtInKotlin=false.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.clicknow.caloriescount"
    // Required by health ^14.0.0 and flutter_secure_storage ^11.1.1.
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.clicknow.caloriescount"
        minSdk = 26
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Personal APK signing with debug keys. For Play Store distribution,
            // load a release keystore via key.properties instead.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
    compilerOptions {
        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
    }
}

flutter {
    source = "../.."
}
