# ---
# title: Rclone sync script
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

# $runSetupChecks: Run setup validation checks before syncing.
# Set to $true to verify gdrive remote configuration and list
# available directories. Set to $false to skip checks.
$runSetupChecks = $false

# Set runtime toggles and discovery behavior.
# $dryRun: Preview changes without syncing.
# Set to $false to perform actual sync.
$dryRun = $true

# $autoDiscoverProjects: Auto-discover projects in
# $localProjectsRoot. Set to $true to use auto-discovery
# instead of manual list.
$autoDiscoverProjects = $true

# $localProjectsRoot: Root directory for auto-discovery
# of project folders.
$localProjectsRoot = "D:\local_projects"

## 1.2 Rclone setup checks ----
# Validate the gdrive remote configuration.
# Set using rclone's native Google Drive backend (gdrive remote)
# Check gdrive remote configuration:
# $runSetupChecks: Run these commands before syncing.
if ($runSetupChecks) {
  rclone config show gdrive
  rclone lsf gdrive: --dirs-only
}

$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

# 1.3 Logging ----
# Create a log folder and define a timestamped log file.
$logDir = Join-Path $repoRoot "logs"
New-Item -ItemType Directory -Path $logDir -Force | Out-Null
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$logFile = Join-Path $logDir "rclone_sync_$timestamp.log"

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
    # "D:\local_projects\rclone_sync"
    # "D:\local_projects\sciCentRverse"
    # "D:\local_projects\utilR"
    # "D:\local_projects\wildland_foundations_site_selection"
    # "D:\local_projects\geospatial_preprocessing_and_extraction_toolkit"
    # "D:\local_projects\InteriorHabitat"
    # "D:\local_projects\invasive_species_indicator"
    # "D:\local_projects\local_backup"
    "D:\local_projects\NativeCover"
    # "D:\local_projects\pileated_woodpecker"
    # "D:\local_projects\private_utils"
  )
}

# 3. Sync execution ----
# Run rclone sync for each local project folder.
foreach ($localPath in $localProjects) {
  $projectName = Split-Path -Leaf $localPath
  $remotePath = "gdrive:1_projects/active/$projectName/main"

  Write-Host "Syncing $projectName..."

  rclone sync $localPath `
    $remotePath `
    @rcloneFlags
}


  


