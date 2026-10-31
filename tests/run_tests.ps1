param([Parameter(Mandatory=$true)][string]$Godot)
$ErrorActionPreference = 'Stop'
$projectPath = Split-Path $PSScriptRoot -Parent
$oldAppData = $env:APPDATA
$env:APPDATA = Join-Path $projectPath '.test-user'
try {
    $runs = ,@('--headless', '--path', $projectPath, '--editor', '--import', '--quit')
    foreach ($test in Get-ChildItem $PSScriptRoot -Filter 'test_*.gd') {
        $runs += ,@('--headless', '--path', $projectPath, '--script', $test.FullName, '--quit-after', '600')
    }
    foreach ($arguments in $runs) {
        $output = (& $Godot @arguments 2>&1 | Out-String)
        $exitCode = $LASTEXITCODE
        Write-Output $output
        # Godot assertions can leave a SceneTree alive or exit with code zero.
        $checked = $output -replace '(?m)^ERROR: Failed to read the root certificate store\.\r?\n?', ''
        if ($exitCode -ne 0 -or $checked -match '(?im)SCRIPT ERROR|Parse Error|Assertion failed|^ERROR:') {
            throw "Godot check failed: $arguments"
        }
        if ($arguments -contains '--script' -and $output -notmatch 'tests passed') {
            throw "Missing test completion marker: $arguments"
        }
    }
    Write-Output 'All test suites and import passed.'
} finally {
    $env:APPDATA = $oldAppData
}
