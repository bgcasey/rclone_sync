# ---
# title: Rclone sync
# author: Brendan Casey
# created: 2026-02-23
# inputs: Local project folders, gdrive remote
# outputs: Synced folders on gdrive, log file in ./logs
# notes:
#   One-way sync from local to remote. Review paths before running.
#   Windows local path uses \, rclone remote uses /.
# ---

# 1. Setup ----

# 1.1 Toggles ----

# $runSetupChecks: Run setup validation checks before
# syncing. Set to $true to verify gdrive remote
# configuration and list available directories. Set to
# $false to skip checks.
$runSetupChecks = $false

# Set runtime toggles and discovery behavior.
# $dryRun: Preview changes without syncing.
# Set to $false to perform actual sync.
$dryRun = $false

# $autoDiscoverProjects: Auto-discover projects in
# $localProjectsRoot. Set to $true to use auto-discovery
# instead of manual list.
$autoDiscoverProjects = $true

# $localProjectsRoot: Root directory for auto-discovery
# of project folders.
$localProjectsRoot = "D:\local_projects\active"

## 1.2 Rclone setup checks ----
# Validate the gdrive remote configuration.
# Set using rclone's native Google Drive backend
# (gdrive remote). Check gdrive remote configuration:
# $runSetupChecks: Run these commands before syncing.
if ($runSetupChecks) {
  rclone config show gdrive
  rclone lsf gdrive: --dirs-only
}

$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

# 1.3 Logging ----
# Create a log folder and define a timestamped log
# file.
$logDir = Join-Path $repoRoot "logs"
New-Item -ItemType Directory -Path $logDir -Force | Out-Null
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$logFile = Join-Path $logDir "rclone_sync_$timestamp.log"

## 1.4 Sync manifest ----
# Track last sync time for each project to detect
# changes.
$manifestFile = Join-Path $repoRoot "sync_manifest.json"
Write-Host "Manifest file path: $manifestFile"
$manifest = @{}
if (Test-Path $manifestFile) {
  Write-Host "Manifest file found, attempting to load..."
  try {
    $manifestContent = Get-Content $manifestFile -Raw
    if ($manifestContent) {
      $manifestObj = $manifestContent | ConvertFrom-Json
      # Convert PSObject to hashtable for compatibility
      # with older PowerShell versions.
      foreach ($prop in $manifestObj.PSObject.Properties) {
        $manifest[$prop.Name] = $prop.Value
      }
      Write-Host "Manifest loaded: $($manifest.Count) projects found"
      foreach ($key in $manifest.Keys) {
        Write-Host "  - $key : $($manifest[$key])"
      }
    } else {
      Write-Host "Manifest file is empty, starting fresh"
    }
  } catch {
    Write-Host "Warning: Could not load manifest file: $($_.Exception.Message)"
    Write-Host "Raw content: $manifestContent"
  }
} else {
  Write-Host "No manifest file found, creating new one"
}

$rcloneFlags = @(
  "--progress"
  "--update"
  "--checksum"
  "--log-level=INFO"
  "--log-file=$logFile"
)
if ($dryRun) {
  $rcloneFlags += "--dry-run"
}

# 2. Project list ----
# Build the list of local project folders to sync.
$localProjects = if ($autoDiscoverProjects) {
  Get-ChildItem -Path $localProjectsRoot -Directory |
    Select-Object -ExpandProperty FullName
} else {
  @(
    # "D:\local_projects\active\rclone_sync"
    # "D:\local_projects\active\sciCentRverse"
    "D:\local_projects\active\utilR"
    # "D:\local_projects\active\wildland_foundations_site_selection"
    # "D:\local_projects\active\geospatial_preprocessing_and_extraction_toolkit"
    # "D:\local_projects\active\InteriorHabitat"
    # "D:\local_projects\active\invasive_species_indicator"
    # "D:\local_projects\active\local_backup"
    "D:\local_projects\active\NativeCover"
    # "D:\local_projects\active\pileated_woodpecker"
    "D:\local_projects\active\private_utils"
  )
}

# 3. Sync execution ----
# Iterate through each local project folder and sync it
# to its corresponding remote location. Before syncing,
# check if the local files have been modified since the
# last sync. Skip syncing if no changes are detected.
foreach ($localPath in $localProjects) {
  # Extract the project name from the folder path.
  # Example: "D:\local_projects\utilR" -> "utilR"
  $projectName = Split-Path -Leaf $localPath
  
  # Construct the remote path following the pattern:
  # gdrive:1_projects/active/<projectName>/main
  $remotePath = "gdrive:1_projects/active/$projectName/main"

  ## 3.1 Check last sync time ----
  # Compare the local project's modification time
  # against the last successful sync. This prevents
  # unnecessary uploads when nothing has changed.
  Write-Host "Checking dates for $projectName..."
  
  # Initialize the last sync time as null. If the
  # project exists in the manifest, retrieve its
  # timestamp. This marks when the project was last
  # synced.
  $lastSyncTime = $null
  if ($manifest.ContainsKey($projectName)) {
    try {
      $lastSyncTime = [datetime]$manifest[$projectName]
      # Convert to UTC for timezone-independent comparison
      $lastSyncTime = $lastSyncTime.ToUniversalTime()
      Write-Host "  Last sync: $lastSyncTime (UTC)"
    } catch {
      Write-Host "  Warning: Invalid timestamp for $projectName in manifest"
    }
  } else {
    Write-Host "  Last sync: (no previous sync found)"
  }

  # Check if any files in the project have been
  # modified since the last sync. This is done by
  # recursively scanning all files in the project
  # folder and comparing their LastWriteTime to the
  # last sync timestamp.
  $hasChanges = $false
  if ($null -eq $lastSyncTime) {
    # No previous sync found: assume there are
    # changes and proceed with sync.
    $hasChanges = $true
  } else {
    # Find all files modified after the last sync time.
    Write-Host "  Checking for files after $lastSyncTime (UTC)"
    
    $recentFiles = Get-ChildItem -Path $localPath -Recurse -File -ErrorAction SilentlyContinue |
      Where-Object { $_.LastWriteTime.ToUniversalTime() -gt $lastSyncTime }
    
    if ($recentFiles.Count -gt 0) {
      Write-Host "  Found $($recentFiles.Count) recent file(s)"
      $hasChanges = $true
    } else {
      Write-Host "  No files found after sync time"
    }
  }

  # Skip the sync if no changes were detected since
  # the last sync.
  if (-not $hasChanges) {
    Write-Host "  -> Skipping (no changes since last sync)"
    continue
  }

  # Proceed with sync because changes were detected
  # or this is the first sync.
  Write-Host "  -> Proceeding with sync"
  Write-Host "Syncing $projectName..."

  # Run rclone sync with the configured flags
  # (progress, update, checksum, logging, and
  # optional dry-run mode).
  rclone sync $localPath `
    $remotePath `
    @rcloneFlags

  ## 3.2 Update manifest ----
  # Record the sync time in the manifest.
  if (-not $dryRun) {
    # Store UTC time in ISO format for timezone
    # independence.
    $manifest[$projectName] = (Get-Date).ToUniversalTime().ToString("o")
    try {
      $manifest | ConvertTo-Json -Depth 2 | Set-Content $manifestFile
      Write-Host "Updated manifest for $projectName"
    } catch {
      Write-Host "Warning: Could not save manifest file ($_)"
    }
  }
}

# End of script ----