# Script: set_java_env.ps1
# Purpose: Sets up Java environment variables for TAK Server
# Usage: Run this script as administrator to configure Java environment
# Parameters:
#   -JavaHome: Optional custom Java installation path
#   -Restore: Switch to restore previous environment settings

param(
    [string]$JavaHome = "C:\Program Files\BellSoft\LibericaJDK-17-Full",
    [switch]$Restore
)

# Verify running as administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "Please run this script as Administrator!"
    Exit 1
}

# Configuration
$requiredVersion = "17"
$backupFile = "$env:TEMP\java_env_backup.json"
$maxSupportedVersion = "17.0.99" # Maximum supported Java version

# Function to backup current environment variables
function Backup-Environment {
    $backup = @{
        JAVA_HOME = [Environment]::GetEnvironmentVariable("JAVA_HOME", "Machine")
        Path = [Environment]::GetEnvironmentVariable("Path", "Machine")
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
    $backup | ConvertTo-Json | Set-Content -Path $backupFile
    Write-Host "Environment variables backed up to $backupFile"
}

# Function to restore environment variables from backup
function Restore-Environment {
    if (Test-Path $backupFile) {
        $backup = Get-Content -Path $backupFile | ConvertFrom-Json
        [Environment]::SetEnvironmentVariable("JAVA_HOME", $backup.JAVA_HOME, "Machine")
        [Environment]::SetEnvironmentVariable("Path", $backup.Path, "Machine")
        Write-Host "Environment variables restored from backup (created on $($backup.Timestamp))"
        Remove-Item -Path $backupFile
        Exit 0
    } else {
        Write-Warning "No backup file found at $backupFile"
        Exit 1
    }
}

# Function to parse Java version string
function Get-JavaVersion {
    param ([string]$versionString)
    if ($versionString -match 'version "([\d._]+)"') {
        return $matches[1]
    }
    return $null
}

# Function to compare version numbers
function Compare-Versions {
    param ([string]$version1, [string]$version2)
    $v1 = [version]($version1.Split("_")[0])
    $v2 = [version]($version2.Split("_")[0])
    return $v1.CompareTo($v2)
}

# Handle restore request
if ($Restore) {
    Restore-Environment
    Exit 0
}

# Backup current environment
Backup-Environment

# Verify Java installation exists
if (-not (Test-Path $JavaHome)) {
    Write-Error "Java installation not found at $JavaHome"
    Write-Host "Please install Liberica JDK 17 before running this script"
    Write-Host "Or specify custom path using -JavaHome parameter"
    Exit 1
}

# Verify Java version before making any changes
try {
    $javaVersionOutput = & "$JavaHome\bin\java.exe" -version 2>&1
    $javaVersion = Get-JavaVersion -versionString $javaVersionOutput
    
    if (-not $javaVersion) {
        Write-Error "Failed to parse Java version"
        Exit 1
    }

    # Check if version is too high
    if ((Compare-Versions -version1 $javaVersion -version2 $maxSupportedVersion) -gt 0) {
        Write-Error "Java version $javaVersion is not supported. Maximum supported version is $maxSupportedVersion"
        Write-Host "Please install Java $requiredVersion"
        Exit 1
    }

    # Check if version matches required major version
    if (-not $javaVersion.StartsWith($requiredVersion)) {
        Write-Error "Invalid Java version $javaVersion. Required: $requiredVersion"
        Write-Host "Please install Java $requiredVersion"
        Exit 1
    }

    Write-Host "Verified Java version: $javaVersion"
} catch {
    Write-Error "Failed to verify Java version: $_"
    Exit 1
}

# Set JAVA_HOME
try {
    [Environment]::SetEnvironmentVariable("JAVA_HOME", $JavaHome, "Machine")
    Write-Host "Successfully set JAVA_HOME to $JavaHome"
} catch {
    Write-Error "Failed to set JAVA_HOME: $_"
    Write-Host "Restoring previous environment..."
    Restore-Environment
    Exit 1
}

# Update PATH - Clean up existing Java entries and add new one
try {
    $path = [Environment]::GetEnvironmentVariable("Path", "Machine")
    $pathArray = $path.Split(';') | Where-Object { $_ -and ($_ -notlike "*java*" -and $_ -notlike "*JAVA_HOME*") }
    $newPath = ($pathArray + "%JAVA_HOME%\bin") -join ';'
    [Environment]::SetEnvironmentVariable("Path", $newPath, "Machine")
    Write-Host "Successfully updated PATH with Java entry"
} catch {
    Write-Error "Failed to update PATH: $_"
    Write-Host "Restoring previous environment..."
    Restore-Environment
    Exit 1
}

# Verify final configuration
try {
    $finalJavaHome = [Environment]::GetEnvironmentVariable("JAVA_HOME", "Machine")
    $finalPath = [Environment]::GetEnvironmentVariable("Path", "Machine")
    $javaVersion = & "$JavaHome\bin\java.exe" -version 2>&1

    Write-Host "`nEnvironment Configuration Summary:"
    Write-Host "--------------------------------"
    Write-Host "JAVA_HOME: $finalJavaHome"
    Write-Host "Java in PATH: Yes"
    Write-Host "Java Version:"
    Write-Host $javaVersion
    Write-Host "`nConfiguration complete!"
    Write-Host "To restore previous settings if needed, run: .\set_java_env.ps1 -Restore"
} catch {
    Write-Error "Failed during final verification: $_"
    Write-Host "Restoring previous environment..."
    Restore-Environment
    Exit 1
}
