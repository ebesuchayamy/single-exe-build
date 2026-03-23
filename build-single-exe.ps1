param(
  [string]$ConfigPath = 'build/build-config.json'
)

$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$configFullPath = Join-Path $root $ConfigPath

if (!(Test-Path $configFullPath)) {
  throw "Build config not found: $configFullPath"
}

$config = Get-Content $configFullPath -Raw | ConvertFrom-Json

if ([string]::IsNullOrWhiteSpace($config.AppDirectoryName)) {
  throw 'AppDirectoryName is required in build config.'
}
if ([string]::IsNullOrWhiteSpace($config.AppExecutableName)) {
  throw 'AppExecutableName is required in build config.'
}
if ([string]::IsNullOrWhiteSpace($config.OutputFileName)) {
  throw 'OutputFileName is required in build config.'
}
if ([string]::IsNullOrWhiteSpace($config.AssemblyName)) {
  throw 'AssemblyName is required in build config.'
}
if ([string]::IsNullOrWhiteSpace($config.RuntimeIdentifier)) {
  throw 'RuntimeIdentifier is required in build config.'
}
if ($null -eq $config.PayloadItems -or $config.PayloadItems.Count -eq 0) {
  throw 'PayloadItems must contain at least one file or directory.'
}

$buildDir = Join-Path $root 'build'
$distDirName = if ([string]::IsNullOrWhiteSpace($config.DistDir)) { 'dist' } else { [string]$config.DistDir }
$distDir = Join-Path $root $distDirName
$payloadZip = Join-Path $buildDir 'payload.zip'
$launcherProjectDir = Join-Path $buildDir 'single_launcher'
$launcherProject = Join-Path $launcherProjectDir 'single_launcher.csproj'
$launcherPayload = Join-Path $launcherProjectDir 'payload.zip'
$launcherConfig = Join-Path $launcherProjectDir 'launcher-config.json'
$publishDir = Join-Path $launcherProjectDir 'publish'
$outExe = Join-Path $distDir ([string]$config.OutputFileName)

$launcherConfigJson = @{
  AppDirectoryName = [string]$config.AppDirectoryName
  AppExecutableName = [string]$config.AppExecutableName
} | ConvertTo-Json

Set-Content -Path $launcherConfig -Value $launcherConfigJson -Encoding UTF8

if (!(Test-Path $distDir)) {
  New-Item -ItemType Directory -Path $distDir | Out-Null
}

# Build payload archive with runtime files required by Flutter app.
if (Test-Path $payloadZip) {
  Remove-Item $payloadZip -Force
}

$payloadItems = @()
foreach ($item in $config.PayloadItems) {
  $relative = [string]$item
  $full = Join-Path $root $relative
  if (!(Test-Path $full)) {
    throw "Payload item not found: $relative"
  }
  $payloadItems += $relative
}

Push-Location $root
try {
  & tar -a -c -f $payloadZip @payloadItems
} finally {
  Pop-Location
}

Copy-Item $payloadZip $launcherPayload -Force

if (Test-Path $publishDir) {
  Remove-Item $publishDir -Recurse -Force
}

dotnet publish $launcherProject -c Release -r ([string]$config.RuntimeIdentifier) --self-contained true -p:AssemblyName=$([string]$config.AssemblyName) -p:PublishSingleFile=true -p:PublishTrimmed=true -p:TrimMode=partial -p:EnableCompressionInSingleFile=true -p:DebugType=None -p:DebugSymbols=false -p:InvariantGlobalization=true -o $publishDir

$publishedExe = Join-Path $publishDir ([string]$config.AssemblyName + '.exe')
if (!(Test-Path $publishedExe) -and (Test-Path $publishDir)) {
  $anyExe = Get-ChildItem -Path $publishDir -Filter '*.exe' | Select-Object -First 1
  if ($anyExe) {
    $publishedExe = $anyExe.FullName
  }
}
if (Test-Path $publishedExe) {
  Copy-Item $publishedExe $outExe -Force
}

# Cleanup transient build artifacts to keep workspace lightweight.
if (Test-Path $launcherPayload) {
  Remove-Item $launcherPayload -Force
}
if (Test-Path $launcherConfig) {
  Remove-Item $launcherConfig -Force
}
if (Test-Path $payloadZip) {
  Remove-Item $payloadZip -Force
}
if (Test-Path $publishDir) {
  Remove-Item $publishDir -Recurse -Force
}
foreach ($dir in @('bin', 'obj')) {
  $full = Join-Path $launcherProjectDir $dir
  if (Test-Path $full) {
    Remove-Item $full -Recurse -Force
  }
}

if (Test-Path $outExe) {
  Write-Output "DONE: $outExe"
} else {
  throw "dotnet publish did not create output EXE: $outExe"
}
