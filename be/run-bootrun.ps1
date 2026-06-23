param(
    [string]$EnvFile = ".env"
)

$envPath = Join-Path $PSScriptRoot $EnvFile
if (-not (Test-Path $envPath)) {
    throw "Không tìm thấy file $envPath"
}

Get-Content $envPath | ForEach-Object {
    $line = $_.Trim()

    if (-not $line -or $line.StartsWith("#")) { return }

    if ($line -match '^\s*([^=]+?)\s*=\s*(.*)\s*$') {
        $name = $matches[1].Trim()
        $value = $matches[2].Trim()

        if (($value.StartsWith('"') -and $value.EndsWith('"')) -or
            ($value.StartsWith("'") -and $value.EndsWith("'"))) {
            $value = $value.Substring(1, $value.Length - 2)
        }

        [System.Environment]::SetEnvironmentVariable($name, $value, "Process")
    }
}

Set-Location $PSScriptRoot
& .\gradlew.bat bootRun
