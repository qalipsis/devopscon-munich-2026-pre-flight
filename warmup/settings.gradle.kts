pluginManagement {
    plugins {
        id("org.gradle.toolchains.foojay-resolver-convention") version "1.0.0"
    }

    repositories {
        gradlePluginPortal()
    }
}

// Applied, not only declared: it gives Gradle the repository to download JDK 21 from, for the daemon
// (gradle/gradle-daemon-jvm.properties) and for the Kotlin toolchain.
plugins {
    id("org.gradle.toolchains.foojay-resolver-convention")
}

rootProject.name = "pre-flight-warmup"
