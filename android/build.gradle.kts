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
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}


subprojects {
    extensions.findByName("android")?.let { ext ->
        try {
            val namespaceField = ext.javaClass.getMethod("getNamespace")
            val currentNamespace = namespaceField.invoke(ext)
            if (currentNamespace == null) {
                val setNamespace = ext.javaClass.getMethod("setNamespace", String::class.java)
                setNamespace.invoke(ext, project.group.toString())
            }
        } catch (e: Exception) {
            // safely ignore non-android modules
        }
    }
}
subprojects {
    plugins.withId("com.android.library") {
        extensions.configure<com.android.build.gradle.LibraryExtension> {
            compileSdk = 36
        }
    }
}