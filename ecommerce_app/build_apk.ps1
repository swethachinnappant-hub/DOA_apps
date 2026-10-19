<#
  Self-healing release build for the ecommerce_app Android app.

  Fixes, automatically, the two build failures this project has hit:

    1. "Version of the generated module should not be incompatible: 2.2.0"
       / "Failed to analyze declaration 'AppLinkSettings'"
       -> stale Kotlin outputs in the SHARED Flutter Gradle plugin build
          (C:\flutter\packages\flutter_tools\gradle) produced by a different
          Kotlin/Flutter toolchain. Purged and rebuilt here.

    2. "Timeout waiting to lock ..." / file-lock errors from Gradle/Kotlin
       daemons left behind by an interrupted build. All Gradle daemons are
       stopped and stuck Kotlin daemons are killed first.

  Usage:   build_apk.ps1 [flutter build apk args...]
  Example: build_apk.ps1 --release          (default)
           build_apk.ps1 --debug
#>
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$FlutterArgs = @('--release')
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $root
function Step($msg) { Write-Host "==> $msg" -ForegroundColor Cyan }

# ── 1. Read flutter.sdk and the wrapper's Gradle version ─────────────────────
$flutterSdk = 'C:\flutter'
$wrapperVersion = $null
foreach ($line in Get-Content (Join-Path $root 'android\local.properties')) {
    if ($line -match '^flutter\.sdk\s*=\s*(.+)$') {
        # local.properties is a Java properties file: backslashes are escapes.
        $flutterSdk = $Matches[1].Trim() -replace '\\\\', '\'
    }
}
$wrapperProps = Join-Path $root 'android\gradle\wrapper\gradle-wrapper.properties'
if (Test-Path $wrapperProps) {
    $m = [regex]::Match((Get-Content $wrapperProps -Raw), 'gradle-([0-9][0-9.]*)-(?:all|bin)\.zip')
    if ($m.Success) { $wrapperVersion = $m.Groups[1].Value }
}

# ── 2. Stop Gradle daemons (releases ~/.gradle cache locks) ──────────────────
$gradlew = Join-Path $root 'android\gradlew.bat'
if (Test-Path $gradlew) {
    Step "Stopping Gradle daemons"
    & cmd /c "`"$gradlew`" --stop"
}

# ── 3. Kill stuck Kotlin daemons only (never generic java.exe: VS Code etc.) ─
Step 'Killing stuck Kotlin daemons'
$killed = 0
Get-CimInstance Win32_Process -Filter "Name='java.exe'" |
    Where-Object { $_.CommandLine -match 'kotlin-daemon|kotlin-compiler-embeddable|KotlinCompileDaemon' } |
    ForEach-Object {
        try { Stop-Process -Id $_.ProcessId -Force -ErrorAction Stop; $killed++ } catch {}
    }
Write-Host "    killed $killed Kotlin daemon process(es)"

# ── 4. Purge stale shared-plugin state (the 2.2.0 metadata poison) ───────────
Step 'Purging stale Gradle/Kotlin state'
$targets = @(
    (Join-Path $flutterSdk 'packages\flutter_tools\gradle\build'),
    (Join-Path $flutterSdk 'packages\flutter_tools\gradle\.kotlin'),
    (Join-Path $flutterSdk 'packages\flutter_tools\gradle\.gradle'),
    (Join-Path $root 'android\.kotlin')
)
if ($wrapperVersion) {
    $gh = if ($env:GRADLE_USER_HOME) { $env:GRADLE_USER_HOME } else { Join-Path $env:USERPROFILE '.gradle' }
    $targets += (Join-Path $gh "caches\$wrapperVersion\kotlin-dsl")
    $targets += (Join-Path $gh "caches\$wrapperVersion\fileHashes")
}
foreach ($t in $targets) {
    if (Test-Path $t) {
        Remove-Item -LiteralPath $t -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "    purged $t"
    }
}

# ── 5. Build ────────────────────────────────────────────────────────────────
Step "flutter build apk $($FlutterArgs -join ' ')"
& flutter build apk @FlutterArgs
exit $LASTEXITCODE
