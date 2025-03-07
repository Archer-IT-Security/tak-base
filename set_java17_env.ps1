# Set JAVA_HOME to Java 17
[Environment]::SetEnvironmentVariable("JAVA_HOME", "C:\Program Files\BellSoft\LibericaJDK-17", "Machine")

# Update PATH - Remove any existing Java paths and add Java 17
$path = [Environment]::GetEnvironmentVariable("Path", "Machine")
$paths = $path.Split(';') | Where-Object { -not ($_ -like '*Java*' -or $_ -like '*JDK*' -or $_ -like '*BellSoft*') }
$newPath = ($paths + '%JAVA_HOME%\bin') -join ';'
[Environment]::SetEnvironmentVariable("Path", $newPath, "Machine")

# Verify the settings
Write-Host "Environment variables updated."
Write-Host "Please close and reopen any command prompts for changes to take effect."
