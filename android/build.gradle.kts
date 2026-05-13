// Global build configuration for all sub-projects

allprojects {
    // FIX 1: Use file() to assign a File object to buildDir
    rootProject.buildDir = file("../build")

    subprojects {
        // FIX 1: Use file() to assign a File object
        project.buildDir = file("${rootProject.buildDir}/${project.name}")
    }

    subprojects {
        // FIX 2: Use double quotes "" for the string argument
        project.evaluationDependsOn(":app") 
    }


    
    // Define repositories for all projects (app, plugins, etc.)
    repositories {
        google()
        mavenCentral()
    }
}

// FIX 3: Correct Task Registration for the clean task
tasks.register<Delete>("clean") {
    // FIX 3: Use the delete() method with parentheses
    delete(rootProject.buildDir)
}
