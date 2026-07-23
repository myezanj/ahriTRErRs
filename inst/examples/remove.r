#!/usr/bin/env Rscript
#
# Preview deletion of a dataset or datafile.
# Set AHRI_TRE_DELETE_PROBE=true to actually delete.
#
# Environment variables:
#   AHRI_TRE_STUDY      - Study name
#   AHRI_TRE_DATASET    - Dataset name (for dataset delete)
#   AHRI_TRE_ASSET      - Asset name (for datafile delete)
#   AHRI_TRE_VERSION    - Version (optional)
#   AHRI_TRE_DELETE_PROBE - Set to "true" to perform deletion (dry-run otherwise)

suppressPackageStartupMessages(library(ahriTRErRs))

if (file.exists(".env")) readRenviron(".env")

study_name <- Sys.getenv("AHRI_TRE_STUDY", "")
dataset_name <- Sys.getenv("AHRI_TRE_DATASET", "")   # for dataset delete
asset_name <- Sys.getenv("AHRI_TRE_ASSET", "")       # for datafile delete
asset_version <- Sys.getenv("AHRI_TRE_VERSION", "")
delete_enabled <- tolower(Sys.getenv("AHRI_TRE_DELETE_PROBE", "false")) %in% c("1", "true", "yes", "on")

# Determine operation
if (nzchar(dataset_name)) {
  cat(sprintf("[INFO] Dataset delete preview for study=%s, dataset=%s\n", study_name, dataset_name))
  client <- AhriTreClient()
  on.exit(close(client), add = TRUE)
  res <- dataset_delete(
    client,
    study = study_name,
    dataset = dataset_name,
    dry_run = !delete_enabled,
    yes = TRUE,
    format = "json"
  )
  if (delete_enabled) {
    cat("[INFO] Deletion performed.\n")
  } else {
    cat("[INFO] Dry-run mode. Set AHRI_TRE_DELETE_PROBE=true to actually delete.\n")
  }
} else if (nzchar(asset_name)) {
  cat(sprintf("[INFO] Datafile delete preview for study=%s, asset=%s\n", study_name, asset_name))
  client <- AhriTreClient()
  on.exit(close(client), add = TRUE)
  res <- datafile_delete(
    client,
    study = study_name,
    asset = asset_name,
    version = if (nzchar(asset_version)) asset_version else NULL,
    dry_run = !delete_enabled,
    yes = TRUE,
    format = "json"
  )
  if (delete_enabled) {
    cat("[INFO] Deletion performed.\n")
  } else {
    cat("[INFO] Dry-run mode. Set AHRI_TRE_DELETE_PROBE=true to actually delete.\n")
  }
} else {
  cat("[INFO] Set either AHRI_TRE_DATASET or AHRI_TRE_ASSET to preview deletion.\n")
  quit(save = "no", status = 0)
}

status_value <- if (!is.null(res$envelope$status) && nzchar(as.character(res$envelope$status[[1]]))) {
  as.character(res$envelope$status[[1]])
} else {
  "ok"
}
cat(sprintf("[INFO] Delete operation status: %s\n", status_value))
print(res$data)