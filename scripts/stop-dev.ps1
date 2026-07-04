<#
.SYNOPSIS
  Stops the backend + AI service processes started by start-dev.ps1.

.DESCRIPTION
  Reads scripts/.dev-pids.json (written by start-dev.ps1) and stops exactly
  those two process trees. Does not touch any other node/python process on
  your machine. Safe to run even if nothing is running - it just reports that.
#>

$PidFile = Join-Path $PSScriptRoot ".dev-pids.json"

if (-not (Test-Path $PidFile)) {
    Write-Host "No scripts/.dev-pids.json found - nothing recorded to stop."
    Write-Host "If servers are still running, close their PowerShell windows manually."
    exit 0
}

$pids = Get-Content $PidFile | ConvertFrom-Json

foreach ($entry in @(
    @{ name = "backend"; id = $pids.backend },
    @{ name = "AI service"; id = $pids.ai }
)) {
    $proc = Get-Process -Id $entry.id -ErrorAction SilentlyContinue
    if ($proc) {
        # Stop the whole process tree (the PowerShell window's child node/uvicorn process too).
        Get-CimInstance Win32_Process -Filter "ParentProcessId = $($entry.id)" -ErrorAction SilentlyContinue |
            ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
        Stop-Process -Id $entry.id -Force -ErrorAction SilentlyContinue
        Write-Host "Stopped $($entry.name) (PID $($entry.id))." -ForegroundColor Green
    } else {
        Write-Host "$($entry.name) (PID $($entry.id)) was not running." -ForegroundColor Yellow
    }
}

Remove-Item $PidFile -ErrorAction SilentlyContinue
Write-Host "Done."
