import java.util.Properties
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.exists()) {
        load(keystorePropertiesFile.inputStream())
    }
}
// Marka: tool/marka.sh gec <kod> -> android/marka.properties (git disi, uretilir).
// Kaynak: markalar/<kod>/marka.json. Burada marka degeri ELLE yazilmaz.
val markaPropsFile = rootProject.file("marka.properties")
val markaProps = Properties().apply {
    if (markaPropsFile.exists()) {
        markaPropsFile.reader(Charsets.UTF_8).use { load(it) }
    }
}
fun marka(anahtar: String): String = markaProps.getProperty(anahtar)
    ?: throw GradleException("android/marka.properties eksik ($anahtar): once 'tool/marka.sh gec <kod>' calistir")

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services") // 🔹 buraya da eklenebilir
}

android {
    // Sabit kod paketi (MainActivity burada). Markadan bagimsiz; magaza kimligi applicationId.
    namespace = "com.randevumcepte.randevusistem"
    compileSdk = 36
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true

    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = marka("paket")
        manifestPlaceholders["markaAd"] = marka("ad")
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = marka("build").toInt()
        versionName = marka("surum")
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
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}
dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
flutter {
    source = "../.."
}
