<#
.SYNOPSIS
  Starts the SCMS local dev stack: PostgreSQL check, Node backend, Python AI
  service, and (optionally) a USB-connected Android device tunnel + Flutter app.

.DESCRIPTION
  Each service is launched in its own PowerShell window so logs stay visible
  and each can be stopped independently (Ctrl+C in that window, or run
  stop-dev.ps1 to stop everything this script started).

.PARAMETER Install
  Run `npm install` (backend) and `pip install -r requirements.txt` (AI
  service) before starting, in case dependencies are missing/out of date.

.PARAMETER SeedDb
  Apply Prisma migrations and run both seed scripts before starting the
  backend. Use on a fresh/empty database. Safe to skip on subsequent runs.

.PARAMETER Phone
  After the backend is up, set up `adb reverse` for a connected Android
  device (USB) so the app can reach the backend/AI service at localhost,
  regardless of Wi-Fi/firewall. Requires exactly one device in `adb devices`.

.PARAMETER RunApp
  After starting the servers (and setting up -Phone if requested), also run
  `flutter run` from scms_flutter/ in a new window.

.EXAMPLE
  ./scripts/start-dev.ps1
  Start backend + AI service only (assumes DB already seeded).

.EXAMPLE
  ./scripts/start-dev.ps1 -SeedDb -Phone -RunApp
  Fresh DB, start both services, tunnel to a USB-connected phone, and launch
  the Flutter app.
#>

param(
    [switch]$Install,
    [switch]$SeedDb,
    [switch]$Phone,
    [switch]$RunApp
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot
$BackendDir = Join-Path $RepoRoot "scms_backend"
$AiDir = Join-Path $RepoRoot "scms_ai_service"
$FlutterDir = Join-Path $RepoRoot "scms_flutter"
$PidFile = Join-Path $PSScriptRoot ".dev-pids.json"

function Write-Step($msg) { Write-Host "`n==> $msg" -ForegroundColor Cyan }
function Write-Warn($msg) { Write-Host "WARNING: $msg" -ForegroundColor Yellow }
function Write-Ok($msg) { Write-Host $msg -ForegroundColor Green }

# ── 1. PostgreSQL check ──────────────────────────────────────────────────
Write-Step "Checking PostgreSQL (port 5432)"
$pg = Get-NetTCPConnection -State Listen -LocalPort 5432 -ErrorAction SilentlyContinue
if ($pg) {
    Write-Ok "PostgreSQL is listening on 5432."
} else {
    Write-Warn "Nothing is listening on port 5432."
    Write-Warn "Start your PostgreSQL service (Services app, or 'net start postgresql-x64-18')"
    Write-Warn "or 'docker-compose up postgres -d' from the repo root if you use the Docker setup."
    Write-Warn "Continuing anyway - the backend will fail to connect until Postgres is up."
}

# ── 2. Optional: install dependencies ────────────────────────────────────
if ($Install) {
    Write-Step "Installing backend dependencies (npm install)"
    Push-Location $BackendDir
    npm install
    Pop-Location

    Write-Step "Installing AI service dependencies (pip install -r requirements.txt)"
    Push-Location $AiDir
    & ".\venv\Scripts\pip.exe" install -r requirements.txt
    Pop-Location
}

# ── 3. Optional: migrate + seed the database ─────────────────────────────
if ($SeedDb) {
    Write-Step "Applying Prisma migrations"
    Push-Location $BackendDir
    npx prisma migrate deploy
    npx prisma generate

    Write-Step "Seeding reference data (departments/categories/zones/tags)"
    node prisma/seed.js

    Write-Step "Seeding demo users + sample complaints"
    node prisma/seed_sample_data.js
    Pop-Location
}

# ── 4. Start backend (new window) ────────────────────────────────────────
Write-Step "Starting Node backend (npm run dev) on port 3000"
$backendProc = Start-Process powershell -ArgumentList @(
    "-NoExit", "-Command",
    "Set-Location '$BackendDir'; npm run dev"
) -WindowStyle Normal -PassThru

# ── 5. Start AI service (new window) ─────────────────────────────────────
Write-Step "Starting Python AI service (uvicorn) on port 8000"
$aiProc = Start-Process powershell -ArgumentList @(
    "-NoExit", "-Command",
    "Set-Location '$AiDir'; .\venv\Scripts\Activate.ps1; uvicorn main:app --reload --port 8000"
) -WindowStyle Normal -PassThru

# Record PIDs so stop-dev.ps1 can clean them up later.
@{ backend = $backendProc.Id; ai = $aiProc.Id } | ConvertTo-Json | Set-Content $PidFile
Write-Ok "Backend PID: $($backendProc.Id)   AI service PID: $($aiProc.Id)"
Write-Host "(Recorded in scripts/.dev-pids.json for stop-dev.ps1)"

Write-Step "Waiting a few seconds for both services to boot..."
Start-Sleep -Seconds 6

# ── 6. Optional: phone tunnel over USB ───────────────────────────────────
if ($Phone) {
    Write-Step "Setting up adb reverse for a USB-connected Android device"
    $adbDevices = & adb devices 2>$null | Select-String "\tdevice$"
    if (-not $adbDevices) {
        Write-Warn "No 'device' entries found in 'adb devices'. Plug in your phone, enable USB debugging, and re-run with -Phone."
    } elseif ($adbDevices.Count -gt 1) {
        Write-Warn "Multiple devices detected - reversing ports on all of them."
        foreach ($line in $adbDevices) {
            $serial = ($line -split "\t")[0]
            & adb -s $serial reverse tcp:3000 tcp:3000 | Out-Null
            & adb -s $serial reverse tcp:8000 tcp:8000 | Out-Null
            Write-Ok "adb reverse set for $serial (3000, 8000 -> this PC)"
        }
    } else {
        $serial = ($adbDevices[0] -split "\t")[0]
        & adb -s $serial reverse tcp:3000 tcp:3000 | Out-Null
        & adb -s $serial reverse tcp:8000 tcp:8000 | Out-Null
        Write-Ok "adb reverse set for $serial (3000, 8000 -> this PC)"
    }
    Write-Host "Make sure scms_flutter/.env has API_BASE_URL=http://localhost:3000"
    Write-Host "Debug builds must include android/app/src/debug/AndroidManifest.xml"
    Write-Host "with usesCleartextTraffic=true (already committed) so plain HTTP works."
}

# ── 7. Optional: run the Flutter app ─────────────────────────────────────
if ($RunApp) {
    Write-Step "Launching Flutter app (new window)"
    Start-Process powershell -ArgumentList @(
        "-NoExit", "-Command",
        "Set-Location '$FlutterDir'; flutter run"
    ) -WindowStyle Normal
}

Write-Step "Done."
Write-Host "Backend:     http://localhost:3000/api"
Write-Host "AI service:  http://localhost:8000/docs"
Write-Host "Run 'scripts/stop-dev.ps1' to stop the backend and AI service windows."
