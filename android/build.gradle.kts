buildscript {
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        // Firebase plugin para Google Services (obligatorio)
        classpath("com.google.gms:google-services:4.3.15")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// 🔧 Reubicar la carpeta de builds (si realmente lo necesitas)
val newBuildDir = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)

    evaluationDependsOn(":app")
}

// 🧹 Tarea para limpiar
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
