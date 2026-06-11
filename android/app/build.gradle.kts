plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
    id("org.jetbrains.kotlin.android") 
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
            // Alterado e adicionado aqui para corrigir o erro de 'shrink resources'
            isMinifyEnabled = true
            isShrinkResources = true
        }
    }

    kotlinOptions {
        jvmTarget = "17"
    }
}

flutter { 
    source = "../.." 
}