plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.tour.inteligente"
    compileSdk = 35
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.tour.inteligente"
        minSdk = 23
        targetSdk = 35
        versionCode = 1
        versionName = "1.0.0"
    }

    buildTypes {
        release { 
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false 
        }
    }

    // ADICIONADO AQUI: O formato clássico que o Gradle 8.7 entende sem quebrar
    kotlinOptions {
        jvmTarget = "17"
    }
}

// O bloco antigo do kotlin foi removido daqui de baixo
flutter { 
    source = "../.." 
}