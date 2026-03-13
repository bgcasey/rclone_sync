# ---
# title: Rclone one-off copy (Shared Drive -> local)
# author: Brendan Casey
# created: 2026-03-13
# inputs: User-defined rclone source path and local destination
# outputs: Copied files on local disk, log file in ./logs
# notes:
#   One-way copy from Google Drive to local.
#   This script does NOT delete local files (uses rclone copy, not sync).
# ---

# 1. Setup ----

# 1.1 User settings ----

# $runSetupChecks: Set to $true to validate rclone remote connectivity
# before copying.
$runSetupChecks = $false

# $dryRun: Set to $true to preview copy operations without writing files.
$dryRun = $false

# $createDestinationIfMissing: Auto-create destination folder if missing.
$createDestinationIfMissing = $true

# $sourcePath: Full rclone source path.
# Examples:
#   "gdrive:Shared Drives/MySharedDrive/project_exports"
#   "gdrive:my_folder/subfolder"
$sourcePath = "gdrive:3_resources/data/scanfi_v2"

# $destinationPath: Local folder to copy files into.
$destinationPath = "\\abmi-data2\science\spatial_data\temp\scanfi_v2"


# 1.2 Optional setup checks ----
if ($runSetupChecks) {
  Write-Host "Running setup checks..."
  rclone config show gdrive
  rclone lsf gdrive: --dirs-only
}


# 1.3 Logging ----
$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$logDir = Join-Path $repoRoot "logs"
New-Item -ItemType Directory -Path $logDir -Force | Out-Null
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$logFile = Join-Path $logDir "rclone_copy_$timestamp.log"


# 1.4 Validate settings ----
if ($sourcePath -match "REPLACE_WITH_") {
  throw "Update `$sourcePath before running this script."
}

if ($destinationPath -match "REPLACE_WITH_") {
  throw "Update `$destinationPath before running this script."
}

if (-not (Test-Path $destinationPath)) {
  if ($createDestinationIfMissing) {
    New-Item -ItemType Directory -Path $destinationPath -Force | Out-Null
  } else {
    throw "Destination path does not exist: $destinationPath"
  }
}


# 2. Build rclone flags ----
$rcloneFlags = @(
  "--progress"
  "--checksum"
  "--transfers=8"
  "--checkers=16"
  "--log-level=INFO"
  "--log-file=$logFile"
)

if ($dryRun) {
  $rcloneFlags += "--dry-run"
}


# 3. One-off copy execution ----
Write-Host "Starting one-off copy..."
Write-Host "Source:      $sourcePath"
Write-Host "Destination: $destinationPath"
Write-Host "Dry run:     $dryRun"
Write-Host "Log file:    $logFile"

# Write key runtime context into the log file for easier audit.
@(
  "===== Copy Session ====="
  "Timestamp:   $(Get-Date -Format 'o')"
  "Source:      $sourcePath"
  "Destination: $destinationPath"
  "Dry run:     $dryRun"
  ""
) | Add-Content -Path $logFile

# `copy` only adds/updates files and never deletes destination content.
rclone copy $sourcePath `
  $destinationPath `
  @rcloneFlags

Write-Host "Copy operation complete."
