# Set using rclone's native Google Drive backend (gdrive remote)
# Check gdrive remote configuration:
rclone config show gdrive
rclone lsf gdrive: --dirs-only

# rclone sync (Windows local path uses \, rclone remote uses /)
# IMPORTANT: this is one-way sync from local to remote, so be sure to 
# use the correct source and destination paths


# Optional dry run toggle
$dryRun = $false
$rcloneFlags = @("--progress", "--update", "--checksum")
if ($dryRun) {
  $rcloneFlags += "--dry-run"
}

# Local folders to sync (one-way: local -> gdrive)
rclone sync "D:\local_projects\rclone_sync" `
  "gdrive:1_projects/rclone_sync/orig/rclone_sync" `
  @rcloneFlags

rclone sync "D:\local_projects\sciCentRverse" `
  "gdrive:1_projects/sciCentRverse/orig/sciCentRverse" `
  @rcloneFlags

rclone sync "D:\local_projects\utilR" `
  "gdrive:1_projects/utilR/orig/utilR" `
  @rcloneFlags

rclone sync "D:\local_projects\wildland_foundations_site_selection" `
  "gdrive:1_projects/wildland_foundations_site_selection/orig/wildland_foundations_site_selection" `
  @rcloneFlags

rclone sync "D:\local_projects\geospatial_preprocessing_and_extraction_toolkit" `
  "gdrive:1_projects/geospatial_preprocessing_and_extraction_toolkit/orig/geospatial_preprocessing_and_extraction_toolkit" `
  @rcloneFlags

rclone sync "D:\local_projects\InteriorHabitat" `
  "gdrive:1_projects/InteriorHabitat/orig/InteriorHabitat" `
  @rcloneFlags

rclone sync "D:\local_projects\invasive_species_indicator" `
  "gdrive:1_projects/invasive_species_indicator/orig/invasive_species_indicator" `
  @rcloneFlags

rclone sync "D:\local_projects\local_backup" `
  "gdrive:1_projects/local_backup/orig/local_backup" `
  @rcloneFlags

rclone sync "D:\local_projects\NativeCover" `
  "gdrive:1_projects/NativeCover/orig/NativeCover" `
  @rcloneFlags

rclone sync "D:\local_projects\pileated_woodpecker" `
  "gdrive:1_projects/pileated_woodpecker/orig/pileated_woodpecker" `
  @rcloneFlags

rclone sync "D:\local_projects\private_utils" `
  "gdrive:1_projects/private_utils/orig/private_utils" `
  @rcloneFlags

# Optional foreach version (comment out the explicit blocks above if you use this)
# $localProjects = @(
#   "D:\local_projects\rclone_sync"
#   "D:\local_projects\sciCentRverse"
#   "D:\local_projects\utilR"
#   "D:\local_projects\wildland_foundations_site_selection"
#   "D:\local_projects\geospatial_preprocessing_and_extraction_toolkit"
#   "D:\local_projects\InteriorHabitat"
#   "D:\local_projects\invasive_species_indicator"
#   "D:\local_projects\local_backup"
#   "D:\local_projects\NativeCover"
#   "D:\local_projects\pileated_woodpecker"
#   "D:\local_projects\private_utils"
# )
#
# foreach ($localPath in $localProjects) {
#   $projectName = Split-Path -Leaf $localPath
#   $remotePath = "gdrive:1_projects/$projectName/orig/$projectName"
#
#   rclone sync $localPath `
#     $remotePath `
#     @rcloneFlags
# }


  


