import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

// ── Signature de release ────────────────────────────────────────────────
// Lit android/key.properties (JAMAIS committé — voir .gitignore) s'il
// existe. Sans ce fichier, IMPOSSIBLE de publier sur Google Play : un AAB
// signé avec la clé debug est automatiquement rejeté à l'upload.
//
// Pour générer le keystore de production (une seule fois, à conserver
// précieusement — sa perte empêche toute mise à jour future de l'app) :
//   keytool -genkey -v -keystore ~/matontine-release.jks -keyalg RSA \
//     -keysize 2048 -validity 10000 -alias matontine
//
// Puis créer android/key.properties :
//   storePassword=...
//   keyPassword=...
//   keyAlias=matontine
//   storeFile=/chemin/absolu/vers/matontine-release.jks
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
val hasReleaseSigning = keystorePropertiesFile.exists()
if (hasReleaseSigning) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
} else {
    println("⚠️  android/key.properties introuvable — build signé avec la clé DEBUG.")
    println("⚠️  Ceci sera REJETÉ par Google Play. Voir le commentaire en tête de build.gradle.kts.")
}

android {
    namespace = "com.tontineapp.tontineapp"
    // Fixé explicitement plutôt que `flutter.compileSdkVersion` : Google Play
    // exige un targetSdkVersion à jour (≥ 34 depuis août 2024, cette
    // exigence est relevée d'un cran chaque année) — dépendre de la version
    // du SDK Flutter installée localement est fragile, un fixe garantit la
    // conformité indépendamment de la machine qui build.
    // ⚠️ 36 requis (pas 35) : androidx.browser/core (via url_launcher_android)
    // exigent de compiler contre le SDK 36 au minimum. compileSdk doit
    // toujours être ≥ targetSdk et ≥ ce que réclament les dépendances.
    // À vérifier/relever périodiquement sur la page "Target API level
    // requirements" de la console Google Play.
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.tontineapp.tontineapp"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Utilise la vraie clé de release si key.properties existe,
            // sinon retombe sur debug (build local uniquement — jamais à
            // uploader sur le Play Store dans cet état).
            signingConfig = if (hasReleaseSigning) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}


dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    
    // Firebase BoM
    implementation(platform("com.google.firebase:firebase-bom:34.15.0"))
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-messaging")
}