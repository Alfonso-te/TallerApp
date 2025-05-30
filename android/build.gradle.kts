// Top-level build file where you can add configuration options common to all sub-projects/modules.
buildscript {
    repositories {
        google()
        mavenCentral()  // Corregido a mayúsculas
    }
    dependencies {
        classpath("com.android.tools.build:gradle:7.3.1")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.7.20")
        classpath("com.google.gms:google-services:4.3.15") // Para Firebase
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()  // Corregido a mayúsculas
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.buildDir)
}