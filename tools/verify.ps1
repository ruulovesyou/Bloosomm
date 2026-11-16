param(
    [string]$LuauDirectory = "$PSScriptRoot/../.tools/luau",
    [string]$Rojo = "$PSScriptRoot/../.tools/rojo/rojo.exe"
)
$ErrorActionPreference = 'Stop'
Push-Location "$PSScriptRoot/.."
try {
    foreach ($tool in @('luau.exe', 'luau-compile.exe', 'luau-analyze.exe')) {
        if (-not (Test-Path -LiteralPath (Join-Path $LuauDirectory $tool))) { throw "Missing tool: $tool. See README.md." }
    }
    $sourceFiles = Get-ChildItem src,tests -Recurse -Filter '*.luau'
    foreach ($file in $sourceFiles) {
        $compilerOutput = & (Join-Path $LuauDirectory 'luau-compile.exe') --null $file.FullName 2>&1
        if ($LASTEXITCODE -ne 0) { $compilerOutput | Write-Output; throw "Compile failed: $($file.FullName)" }
    }
    Write-Output "PASS compiled $($sourceFiles.Count) Luau files"
    & (Join-Path $LuauDirectory 'luau-analyze.exe') src/Blossom/Core/Value.luau src/Blossom/Core/Store.luau src/Blossom/Core/Cleanup.luau
    if ($LASTEXITCODE -ne 0) { throw 'Pure-module strict analysis failed' }
    Write-Output 'PASS strict analysis: Value, Store, Cleanup'
    & (Join-Path $LuauDirectory 'luau.exe') tests/core.spec.luau
    if ($LASTEXITCODE -ne 0) { throw 'Core tests failed' }
    New-Item -ItemType Directory -Path build -Force | Out-Null
    foreach ($build in @(
        @('default.project.json', 'build/BlossomDemo.rbxlx'),
        @('library.project.json', 'build/Blossom.rbxmx'),
        @('tests/studio.project.json', 'build/BlossomSmokeTests.rbxlx')
    )) {
        & $Rojo build $build[0] --output $build[1]
        if ($LASTEXITCODE -ne 0) { throw "Rojo build failed: $($build[0])" }
    }
    python tools/check_package.py
    if ($LASTEXITCODE -ne 0) { throw 'Package structure verification failed' }
    Write-Output 'Headless checks passed. Studio smoke/manual UI checks remain separate.'
} finally {
    Pop-Location
}
