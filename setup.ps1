# ═══════════════════════════════════════════════════════════════
#  setup.ps1  —  Catalyst Environment Setup Script for Windows
#
#  Usage (in PowerShell):
#    .\setup.ps1
# ═══════════════════════════════════════════════════════════════

$ErrorActionPreference = "Stop"

Write-Host "  ╔════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "  ║                                                        ║" -ForegroundColor Cyan
Write-Host "  ║     ⚡  C A T A L Y S T   E N V   S E T U P  ⚡          ║" -ForegroundColor Cyan
Write-Host "  ║                                                        ║" -ForegroundColor Cyan
Write-Host "  ╚════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Helper: check command exists
function Test-CommandExists {
    param ($cmd)
    return (Get-Command $cmd -ErrorAction SilentlyContinue) -ne $null
}

# Helper: Prompt to install using winget
function Prompt-Install {
    param ($service, $wingetId)
    Write-Host "   ⚠ $service is missing or has incorrect version." -ForegroundColor Yellow
    $confirm = Read-Host "   Do you want this script to attempt installing it via winget (Windows Package Manager)? (y/n)"
    if ($confirm -match '^[Yy]$') {
        Write-Host "   Installing $service via winget..." -ForegroundColor Green
        Start-Process winget -ArgumentList "install $wingetId --silent --accept-package-agreements --accept-source-agreements" -Wait
    } else {
        Write-Host "   Skipping automatic installation. Please install $service manually before continuing." -ForegroundColor Red
    }
}

# ── 1. Check Node.js ──────────────────────────────────────────
Write-Host "   Checking Node.js..." -ForegroundColor Blue
$nodeOk = $false
if (Test-CommandExists "node") {
    $nodeVer = (node -v).Trim().Substring(1)
    $nodeMajor = [int]($nodeVer.Split('.')[0])
    Write-Host "   Found Node.js version $nodeVer" -ForegroundColor Green
    if ($nodeMajor -ge 18) {
        $nodeOk = $true
    } else {
        Write-Host "   Node.js version is too old (needs v18+)." -ForegroundColor Yellow
    }
} else {
    Write-Host "   Node.js is not installed." -ForegroundColor Red
}

if (-not $nodeOk) {
    Prompt-Install "Node.js v20" "OpenJS.NodeJS"
}

# Re-check Node.js
if (-not (Test-CommandExists "node")) {
    Write-Host "   Node.js setup failed or was skipped. Cannot proceed without Node.js." -ForegroundColor Red
    Exit 1
}

# ── 2. Check Java JDK (needs 17 or 21) ───────────────────────
Write-Host ""
Write-Host "   Checking Java JDK (needs JDK 17 or 21)..." -ForegroundColor Blue
$jdkOk = $false
if (Test-CommandExists "java") {
    $javaVer = & java -version 2>&1
    $javaVerStr = $javaVer[0]
    Write-Host "   Found Java: $javaVerStr" -ForegroundColor Green
    if ($javaVerStr -match "17\." -or $javaVerStr -match "21\.") {
        $jdkOk = $true
    } elseif ($javaVerStr -match "25\.") {
        Write-Host "   Warning: JDK 25 is installed. Gradle builds may fail to parse Kotlin files with JDK 25." -ForegroundColor Yellow
    } else {
        Write-Host "   Java version is not JDK 17 or 21." -ForegroundColor Yellow
    }
} else {
    Write-Host "   Java is not installed." -ForegroundColor Red
}

if (-not $jdkOk) {
    Prompt-Install "Microsoft OpenJDK 17" "Microsoft.OpenJDK.17"
}

# ── 3. Check Android SDK ──────────────────────────────────────
Write-Host ""
Write-Host "   Checking Android SDK & Environment..." -ForegroundColor Blue
$sdkFound = $false
$sdkPath = ""

if ($env:ANDROID_HOME -and (Test-Path $env:ANDROID_HOME)) {
    $sdkPath = $env:ANDROID_HOME
    $sdkFound = $true
} elseif ($env:ANDROID_SDK_ROOT -and (Test-Path $env:ANDROID_SDK_ROOT)) {
    $sdkPath = $env:ANDROID_SDK_ROOT
    $sdkFound = $true
} else {
    # Check default path
    $defaultPath = "$env:LOCALAPPDATA\Android\Sdk"
    if (Test-Path $defaultPath) {
        $sdkPath = $defaultPath
        $sdkFound = $true
        $env:ANDROID_HOME = $defaultPath
    }
}

if ($sdkFound) {
    Write-Host "   Android SDK found at: $sdkPath" -ForegroundColor Green
    
    # Update local.properties for Gradle (escaped slashes)
    $formattedSdkPath = $sdkPath -replace '\\', '/'
    if (-not (Test-Path "android")) {
        New-Item -ItemType Directory -Force -Path "android" | Out-Null
    }
    "sdk.dir=$formattedSdkPath" | Out-File -FilePath "android/local.properties" -Encoding ascii
    Write-Host "   Updated android/local.properties with SDK path." -ForegroundColor Cyan
} else {
    Write-Host "   ⚠ Android SDK was not detected in standard paths." -ForegroundColor Yellow
    Write-Host "   Please ensure Android Studio is installed and SDK is configured."
    Write-Host "   See https://reactnative.dev/docs/set-up-your-environment for details."
    $sdkConfirm = Read-Host "   Do you want to proceed anyway? (y/n)"
    if ($sdkConfirm -notmatch '^[Yy]$') {
        Exit 1
    }
}

# ── 4. Verify Config Files ───────────────────────────────────
Write-Host ""
Write-Host "   Verifying Config Files..." -ForegroundColor Blue
if (-not (Test-Path "google-services.json")) {
    Write-Host "   ⚠ google-services.json is missing in the root directory." -ForegroundColor Yellow
    Write-Host "     Please download it from your Firebase console to connect your own database."
}

if (-not (Test-Path ".env")) {
    Write-Host "   ⚠ .env file is missing in the root directory. Creating template..." -ForegroundColor Yellow
    "EXPO_PUBLIC_GEMINI_API_KEY=your_gemini_key_here" | Out-File -FilePath ".env" -Encoding ascii
    Write-Host "     Created template .env file." -ForegroundColor Cyan
}

# ── 5. Install JS Dependencies ──────────────────────────────
Write-Host ""
Write-Host "   Installing JS dependencies (npm install)..." -ForegroundColor Blue
npm install

# ── 6. Run Expo Prebuild ─────────────────────────────────────
Write-Host ""
Write-Host "   Generating native folders (npx expo prebuild)..." -ForegroundColor Blue
if (Test-Path "google-services.json") {
    npx expo prebuild --clean
    Write-Host ""
    Write-Host "   ✔ Setup complete! Native android/ and ios/ folders successfully generated." -ForegroundColor Green
    Write-Host "   You can now start the development server:"
    Write-Host "     npm start" -ForegroundColor Cyan
    Write-Host "   Or compile a local release APK:"
    Write-Host "     cd android; .\gradlew assembleRelease" -ForegroundColor Cyan
} else {
    Write-Host ""
    Write-Host "   ⚠ Prebuild skipped because google-services.json is missing." -ForegroundColor Yellow
    Write-Host "     Please add google-services.json and run 'npx expo prebuild --clean' manually."
}
