allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)

    // evaluationDependsOn causes :app to be evaluated early.
    // Skip it for :app itself to avoid a circular dependency.
    if (project.name != "app") {
        project.evaluationDependsOn(":app")
    }

    // Workaround: older plugins (e.g. isar_flutter_libs 3.1.0) don't declare
    // a namespace, which AGP 8+ requires. Inject one if missing.
    afterEvaluate {
        if (plugins.hasPlugin("com.android.library") || plugins.hasPlugin("com.android.application")) {
            val android = extensions.findByName("android") as? com.android.build.gradle.BaseExtension
            if (android != null && android.namespace == null) {
                android.namespace = "com.example." + name.replace("-", "_").replace(".", "_")
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
