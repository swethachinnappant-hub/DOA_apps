pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    // ── Self-heal for the shared Flutter Gradle plugin build ─────────────────
    // `flutter_tools/gradle` lives INSIDE the SDK and is shared by every
    // Flutter project on this machine. If another toolchain (another Flutter
    // version / Kotlin 2.x) compiles it — or a compile fails halfway — the
    // directory keeps Kotlin module metadata the pinned compiler (1.9.20)
    // cannot read. Every later build then dies with:
    //     Version of the generated module should not be incompatible: 2.2.0
    //     Failed to analyze declaration 'AppLinkSettings'
    // Detect that poisoned state here, BEFORE includeBuild resolves it, and
    // purge it so the plugin is rebuilt cleanly. Healthy builds never trip
    // this check, so the fast path is untouched.
    //
    // NOTE: only the shared plugin's own state is deleted here. The
    // user-home kotlin-dsl/fileHashes caches are IN USE by the running build
    // (deleting them mid-run corrupts this very settings script's compile);
    // build_apk.ps1 clears those BEFORE Gradle starts when a full reset is
    // needed.
    run {
        val shared = java.io.File(flutterSdkPath, "packages/flutter_tools/gradle")
        if (shared.isDirectory) {
            val errorsScar = java.io.File(shared, ".kotlin/errors")
            val hasFailedCompile =
                errorsScar.isDirectory && (errorsScar.listFiles()?.isNotEmpty() == true)
            val buildDir = java.io.File(shared, "build")
            val libsDir = java.io.File(buildDir, "libs")
            val isPartialBuild =
                buildDir.isDirectory &&
                    !(libsDir.isDirectory && (libsDir.listFiles()?.isNotEmpty() == true))

            if (hasFailedCompile || isPartialBuild) {
                val reason =
                    if (hasFailedCompile) "scar of a failed foreign-Kotlin compile"
                    else "partial plugin build (missing jars)"
                val purged =
                    listOf(
                        java.io.File(shared, ".kotlin"),
                        buildDir,
                        java.io.File(shared, ".gradle"),
                    ).filter { it.deleteRecursively() || !it.exists() }
                println(
                    "[self-heal] $reason detected in the shared Flutter Gradle plugin; " +
                        "purged ${purged.size} stale state dir(s) so it rebuilds cleanly.",
                )
            }
        }
    }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.9.1" apply false
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
}

include(":app")
