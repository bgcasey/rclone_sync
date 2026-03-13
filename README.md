# Rclone One-Way Project Backup

![Maintenance](https://img.shields.io/badge/Status-Maintenance-green)
![Languages](https://img.shields.io/badge/Languages-PowerShell-blue)

Scripts for syncing local projects to Google Drive and one-off copying from Google Drive to local using rclone.[^1][^2]

## Overview
This repository contains PowerShell scripts for two one-way workflows:

1. `rclone_sync.ps1`: sync local project folders to Google Drive
2. `rclone_copy.ps1`: one-off copy from Google Drive (including Shared Drive paths) to local storage

Both scripts support timestamped logs in `logs/`.

## rclone_copy.ps1 (one-off copy)
Use `rclone_copy.ps1` when you want a pull operation from Google Drive to local without deleting local files.

### What it does
`rclone_copy.ps1` runs `rclone copy` from a user-defined source path to a user-defined destination path.

- Source can be a standard Drive path or Shared Drive path.
- Destination can be any local or UNC path.
- Folder names do not need to match.
- Existing destination files are not deleted.

### Key settings

```powershell
# Validate remote config/listing before copy
$runSetupChecks = $false

# Preview only; set to $false for real copy
$dryRun = $false

# Create destination folder if missing
$createDestinationIfMissing = $true

# rclone source path (Google Drive)
$sourcePath = "gdrive:3_resources/data/scanfi_v2"

# local destination folder
$destinationPath = "\\abmi-data2\science\spatial_data\temp\scanfi_v2"
```

### Logging
Each run writes a timestamped log file:

- `logs/rclone_copy_<timestamp>.log`

The script also writes run context (timestamp, source, destination, dry-run state) at the top of the log for auditability.

### Run

```powershell
pwsh -File .\rclone_copy.ps1
```

Tip: start with `$dryRun = $true`, review the log, then set `$dryRun = $false`.

## rclone_sync.ps1

### Example configuration
Toggle setup checks, dry run behavior, and project discovery:

```powershell
# $runSetupChecks: Run setup validation checks before syncing.
# Set to $true to verify gdrive remote configuration and list
# available directories. Set to $false to skip checks.
$runSetupChecks = $false

# $dryRun: Preview changes without syncing.
# Set to $false to perform actual sync.
$dryRun = $true

# $autoDiscoverProjects: Auto-discover projects in
# $localProjectsRoot. Set to $true to use auto-discovery
# instead of manual list.
$autoDiscoverProjects = $true

# $localProjectsRoot: Root directory for auto-discovery
# of project folders.
$localProjectsRoot = "D:\\local_projects"
```

### Example logging setup
Logs are stored under a `logs` folder with a timestamped filename:

```powershell
$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$logDir = Join-Path $repoRoot "logs"
New-Item -ItemType Directory -Path $logDir -Force | Out-Null
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$logFile = Join-Path $logDir "rclone_sync_$timestamp.log"
```

### Example sync loop
Each project path maps to `gdrive:1_projects/active/<projectName>/main`:

```powershell
foreach ($localPath in $localProjects) {
	$projectName = Split-Path -Leaf $localPath
	$remotePath = "gdrive:1_projects/active/$projectName/main"

	Write-Host "Syncing $projectName..."

	rclone sync $localPath `
		$remotePath `
		@rcloneFlags
}
```

### Auto-detecting project folders
When `$autoDiscoverProjects` is set to `$true`, the script lists all immediate subfolders under `D:\local_projects\active` and treats each one as a project to sync. This is a simple way to include every project directory without maintaining a manual list.

If you only want specific projects, set `$autoDiscoverProjects` to `$false` and list the desired folders explicitly in the manual array. This also lets you exclude folders within the project directory.

### Change detection and sync skipping
The script uses a `sync_manifest.json` file to track the last sync timestamp for each project. Before syncing, it:

1. Checks the manifest for the project's last sync time
2. Recursively scans all files in the project folder
3. Compares each file's modification time to the last sync timestamp
4. Skips the sync if no files have been modified since the last sync
5. Proceeds with sync only if changes are detected or if this is the first sync

When a sync completes successfully, the manifest is updated with the new sync timestamp for that project.

[^1]: https://rclone.org/
[^2]: https://github.com/rclone/rclone
