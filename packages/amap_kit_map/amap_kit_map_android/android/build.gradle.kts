group = "com.github.amapkit.map"
version = "1.0-SNAPSHOT"

buildscript {
    val kotlinVersion = "2.3.20"
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:9.0.1")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlinVersion")
    }
}

plugins {
    id("com.android.library")
}

android {
    namespace = "com.github.amapkit.map"
    compileSdk = 36
    defaultConfig { minSdk = 24 }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    sourceSets {
        getByName("main") { java.srcDirs("src/main/kotlin", "src/main/java") }
        getByName("test") { java.srcDirs("src/test/kotlin") }
    }
}

kotlin {
    compilerOptions { jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17 }
}

dependencies {
    // The combined artifact is the official AMap distribution for apps that
    // use map and location together. It keeps the shared native classes in a
    // single jar, so independently endorsed Flutter plugins can coexist.
    implementation("com.amap.api:3dmap-location-search:11.1.001_loc11.1.001_sea9.7.4")
    testImplementation("org.jetbrains.kotlin:kotlin-test")
    implementation(kotlin("stdlib-jdk8"))
}
