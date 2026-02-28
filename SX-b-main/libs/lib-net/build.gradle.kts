plugins {
    id("com.android.library")
    id("org.jetbrains.kotlin.android")
    id("maven-publish")
}

android {
    namespace = "ex.ss.lib.net"
    compileSdk = 34

    defaultConfig {
        minSdk = 21

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
        consumerProguardFiles("consumer-rules.pro")

        buildConfigField(
            "String",
            "${project.name.replace("-", "_").uppercase()}_VERSION",
            "\"${publishVersion}\""
        )
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }
    kotlinOptions {
        jvmTarget = "1.8"
    }

    android.libraryVariants.all {
        outputs.all {
            if (this is com.android.build.gradle.internal.api.LibraryVariantOutputImpl) {
                outputFileName = "${project.name}_${publishVersion}_${buildType.name}.aar"
            }
        }
    }

    buildFeatures {
        buildConfig = true
    }
}

dependencies {

    compileOnly(libs.retrofit2)
    compileOnly(libs.okhttp3)
    compileOnly(libs.okhttp3.logging)
//    compileOnly(libs.retrofit2.converter)
    compileOnly(libs.gson)

    compileOnly(libs.coroutines.core)

}


val publishGroupId = "ex.ss.lib"
val publishArtifactId = "net"
val publishVersion = "1.0.0"

publishing {
    publications {
        register<MavenPublication>("release") {
            groupId = publishGroupId
            artifactId = publishArtifactId
            version = publishVersion

            afterEvaluate {
                from(components["release"])
            }
        }

        repositories {
            maven {
                val publishLocal =
                    File(rootDir, "maven-repo${File.separator}repository").absolutePath
                setUrl(publishLocal)
            }
        }
    }
}

afterEvaluate {
    tasks.onEach {
        if (it.group == "publishing") {
            it.doFirst {
                println("---> publishingCheck <---")
                val publishLocal =
                    File(rootDir, "maven-repo${File.separator}repository").absolutePath
                val groupIdPath = publishGroupId.replace(".", File.separator)
                val path =
                    "$groupIdPath${File.separator}$publishArtifactId${File.separator}$publishVersion"
                val versionFile = File(publishLocal, path)
                check(!versionFile.exists()) { "$publishGroupId:$publishArtifactId:$publishVersion is already exists!!!" }
            }
        }
    }
}