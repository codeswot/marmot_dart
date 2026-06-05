allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

// Some plugins (e.g. flutter_plugin_android_lifecycle) now publish AAR metadata
// requiring consumers to compile against API 36, but other plugins still pin
// their own compileSdk to flutter.compileSdkVersion (34). Force every Android
// subproject to compileSdk 36. Reflection keeps this AGP-version agnostic.
// Some plugin projects are evaluated eagerly by the Flutter plugin loader, so
// configure those immediately and defer the rest to afterEvaluate.
fun Project.forceCompileSdk36() {
    val android = project.extensions.findByName("android") ?: return
    runCatching {
        val current = android.javaClass.methods
            .firstOrNull { it.name == "getCompileSdk" && it.parameterCount == 0 }
            ?.invoke(android) as? Int
        if (current == null || current < 36) {
            android.javaClass.methods
                .firstOrNull { it.name == "setCompileSdk" && it.parameterCount == 1 }
                ?.invoke(android, 36)
        }
    }.onFailure {
        project.logger.warn("Could not force compileSdk=36 on ${project.name}: ${it.message}")
    }
}
subprojects {
    if (state.executed) forceCompileSdk36() else afterEvaluate { forceCompileSdk36() }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
