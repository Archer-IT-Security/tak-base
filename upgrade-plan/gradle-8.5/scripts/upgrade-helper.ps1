$BACKUP_DIR = "upgrade-plan/gradle-8.5/backups/original"
$GRADLE_VERSION = "8.5"
$LOG_DIR = "upgrade-plan/gradle-8.5/logs"

function Create-Directories {
    New-Item -ItemType Directory -Force -Path $BACKUP_DIR
    New-Item -ItemType Directory -Force -Path $LOG_DIR
}

function Backup-GradleFiles {
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backup_path = Join-Path $BACKUP_DIR $timestamp
    New-Item -ItemType Directory -Force -Path $backup_path
    Copy-Item "gradle" -Destination $backup_path -Recurse
    Copy-Item "gradlew*" -Destination $backup_path
    Copy-Item "*.gradle" -Destination $backup_path
    Copy-Item "gradle.properties" -Destination $backup_path -ErrorAction SilentlyContinue
}

function Get-BuildInfo {
    New-Item -ItemType Directory -Force -Path $LOG_DIR
    ./gradlew buildEnvironment > "$LOG_DIR/build-environment.txt"
    ./gradlew dependencies > "$LOG_DIR/dependencies.txt"
    ./gradlew projects > "$LOG_DIR/project-structure.txt"
    java -version 2> "$LOG_DIR/java-version.txt"
}

function Update-GradleWrapper {
    ./gradlew wrapper --gradle-version $GRADLE_VERSION
}

function Test-Build {
    ./gradlew clean build > "$LOG_DIR/clean-build.txt" 2>&1
    $modules = @("takserver-protobuf", "takserver-fig-core", "federation-common")
    foreach ($module in $modules) {
        ./gradlew ":$module:build" > "$LOG_DIR/$module-build.txt" 2>&1
    }
}

function Show-Menu {
    Write-Host "================ Gradle 8.5 Upgrade Helper ================"
    Write-Host "1: Create backup of current Gradle files"
    Write-Host "2: Collect build environment information"
    Write-Host "3: Update Gradle wrapper to 8.5"
    Write-Host "4: Test build with new version"
    Write-Host "5: Run all steps in sequence"
    Write-Host "Q: Quit"
}

$selection = ""
do {
    Clear-Host
    Show-Menu
    $selection = Read-Host "Please make a selection"
    switch ($selection.ToLower()) {
        '1' {
            Create-Directories
            Backup-GradleFiles
            pause
        }
        '2' {
            Get-BuildInfo
            pause
        }
        '3' {
            Update-GradleWrapper
            pause
        }
        '4' {
            Test-Build
            pause
        }
        '5' {
            Create-Directories
            Backup-GradleFiles
            Get-BuildInfo
            Update-GradleWrapper
            Test-Build
            pause
        }
    }
} until ($selection.ToLower() -eq 'q')
