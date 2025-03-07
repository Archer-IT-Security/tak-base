# Script: test_java_env.ps1
# Purpose: Tests Java environment configuration and version compatibility

Write-Host "Testing Java Environment Configuration"
Write-Host "------------------------------------`n"

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

# Test JAVA_HOME
$javaHome = [Environment]::GetEnvironmentVariable("JAVA_HOME", "Machine")
Write-Host "1. Testing JAVA_HOME:"
if ($javaHome) {
    Write-Host "   ✓ JAVA_HOME is set to: $javaHome"
    if (Test-Path $javaHome) {
        Write-Host "   ✓ JAVA_HOME path exists"
        
        # Test Java executables
        $executables = @("java.exe", "javac.exe", "jar.exe")
        $allExecutablesExist = $true
        foreach ($exe in $executables) {
            $exePath = Join-Path $javaHome "bin\$exe"
            if (Test-Path $exePath) {
                Write-Host "   ✓ Found $exe"
            } else {
                Write-Host "   ✗ Missing $exe!" -ForegroundColor Red
                $allExecutablesExist = $false
            }
        }
        
        if ($allExecutablesExist) {
            Write-Host "   ✓ All required Java executables found"
        }
    } else {
        Write-Host "   ✗ JAVA_HOME path does not exist!" -ForegroundColor Red
    }
} else {
    Write-Host "   ✗ JAVA_HOME is not set!" -ForegroundColor Red
}

# Test PATH
$path = [Environment]::GetEnvironmentVariable("Path", "Machine")
Write-Host "`n2. Testing PATH:"
if ($path -like "*%JAVA_HOME%\bin*" -or $path -like "*$javaHome\bin*") {
    Write-Host "   ✓ Java bin directory is in PATH"
    
    # Check for duplicate Java entries
    $pathEntries = $path.Split(';')
    $javaEntries = $pathEntries | Where-Object { $_ -like "*java*" -or $_ -like "*JAVA_HOME*" }
    if ($javaEntries.Count -gt 1) {
        Write-Host "   ! Warning: Multiple Java entries found in PATH:" -ForegroundColor Yellow
        foreach ($entry in $javaEntries) {
            Write-Host "     - $entry"
        }
    }
} else {
    Write-Host "   ✗ Java bin directory is not in PATH!" -ForegroundColor Red
}

# Test Java version and compatibility
Write-Host "`n3. Testing Java version and compatibility:"
try {
    $javaVersionOutput = & "java" -version 2>&1
    Write-Host "   ✓ Java is accessible from command line"
    
    $javaVersion = Get-JavaVersion -versionString $javaVersionOutput
    if ($javaVersion) {
        Write-Host "   ✓ Java version: $javaVersion"
        
        # Check version compatibility
        $requiredVersion = "17"
        $maxSupportedVersion = "17.0.99"
        
        if ($javaVersion.StartsWith($requiredVersion)) {
            Write-Host "   ✓ Java version matches required version ($requiredVersion)"
        } else {
            Write-Host "   ✗ Java version does not match required version ($requiredVersion)!" -ForegroundColor Red
        }
        
        if ((Compare-Versions -version1 $javaVersion -version2 $maxSupportedVersion) -le 0) {
            Write-Host "   ✓ Java version is within supported range (≤ $maxSupportedVersion)"
        } else {
            Write-Host "   ✗ Java version exceeds maximum supported version ($maxSupportedVersion)!" -ForegroundColor Red
        }
    } else {
        Write-Host "   ✗ Failed to parse Java version!" -ForegroundColor Red
    }
    
    Write-Host "`n   Full version information:"
    Write-Host "   $javaVersionOutput"
} catch {
    Write-Host "   ✗ Failed to execute 'java' command!" -ForegroundColor Red
    Write-Host "   Error: $_" -ForegroundColor Red
}

# Test Java compiler
Write-Host "`n4. Testing Java compiler:"
try {
    $javacVersion = & "javac" -version 2>&1
    Write-Host "   ✓ Java compiler is accessible"
    Write-Host "   Version: $javacVersion"
} catch {
    Write-Host "   ✗ Failed to execute 'javac' command!" -ForegroundColor Red
    Write-Host "   Error: $_" -ForegroundColor Red
}

Write-Host "`nTest Complete!"

# Provide recommendations if issues were found
if ($Error.Count -gt 0) {
    Write-Host "`nRecommendations:" -ForegroundColor Yellow
    Write-Host "1. Run 'set_java_env.ps1' as Administrator to fix environment variables"
    Write-Host "2. If issues persist, verify Java 17 is properly installed"
    Write-Host "3. Use 'set_java_env.ps1 -Restore' to restore previous settings if needed"
}
