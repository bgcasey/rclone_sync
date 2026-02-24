# Rclone One-Way Project Backup

![Maintenance](https://img.shields.io/badge/Status-Maintenance-green)
![Languages](https://img.shields.io/badge/Languages-PowerShell-blue)

Script for syncing local projects to Google Drive using rclone.[^1][^2]

## Overview
This repository contains a PowerShell script that performs one-way syncs from local project folders to a Google Drive remote using `rclone`. It supports auto-discovery of local projects and and timestamped sync logs.

## Example configuration
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

## Example logging setup
Logs are stored under a `logs` folder with a timestamped filename:

```powershell
$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$logDir = Join-Path $repoRoot "logs"
New-Item -ItemType Directory -Path $logDir -Force | Out-Null
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$logFile = Join-Path $logDir "rclone_sync_$timestamp.log"
```

## Example sync loop
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

## Auto-detecting project folders
When `$autoDiscoverProjects` is set to `$true`, the script lists all immediate subfolders under `D:\local_projects\active` and treats each one as a project to sync. This is a simple way to include every project directory without maintaining a manual list.

If you only want specific projects, set `$autoDiscoverProjects` to `$false` and list the desired folders explicitly in the manual array. This also lets you exclude folders within the project directory.

## Change detection and sync skipping
The script uses a `sync_manifest.json` file to track the last sync timestamp for each project. Before syncing, it:

1. Checks the manifest for the project's last sync time
2. Recursively scans all files in the project folder
3. Compares each file's modification time to the last sync timestamp
4. Skips the sync if no files have been modified since the last sync
5. Proceeds with sync only if changes are detected or if this is the first sync

When a sync completes successfully, the manifest is updated with the new sync timestamp for that project.

[^1]: https://rclone.org/
[^2]: https://github.com/rclone/rclone
