# rclone_sync
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
Logs are stored under a `logs` folder next to the script with a timestamped filename:

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
When `$autoDiscoverProjects` is set to `$true`, the script lists all immediate subfolders under `D:\local_projects` and treats each one as a project to sync. This is a simple, zero-maintenance way to include every project directory without maintaining a manual list.

If you only want specific projects, set `$autoDiscoverProjects` to `$false` and list the desired folders explicitly in the manual array. This also lets you exclude non-project folders like `logs`, `archive`, or scratch directories.

[^1]: https://rclone.org/
[^2]: https://github.com/rclone/rclone
