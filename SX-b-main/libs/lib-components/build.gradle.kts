plugins {
    id("com.android.library")
    id("org.jetbrains.kotlin.android")
    id("maven-publish")
}

android {
    namespace = "ex.ss.lib.components"
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
        viewBinding = true
    }

}

dependencies {

    compileOnly(libs.androidx.activity)
    compileOnly(libs.androidxfragment)

    compileOnly(libs.androidx.lifecycle.runtime)
    compileOnly(libs.androidx.lifecycle.livedata)
    compileOnly(libs.androidx.lifecycle.viewmodel)

    compileOnly(libs.coroutines.android)

    compileOnly(libs.androidx.recyclerview)
    compileOnly(libs.androidx.constraintlayout)
    compileOnly(libs.material)

    compileOnly(libs.mmkv)

}


val publishGroupId = "ex.ss.lib"
val publishArtifactId = "components"
val publishVersion = "1.0.5"

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