#!/usr/bin/env Rscript
#
# Cleanup script for temporary row-probe study and dataset.
# Usage: set AHRI_TRE_STUDY, AHRI_TRE_DATASET, and optionally AHRI_TRE_DELETE_PROBE=true.
#
# Environment variables:
#   AHRI_TRE_CLEANUP_STUDY      - Name of the study to delete (default: Copilot_Row_Probe_20260720)
#   AHRI_TRE_CLEANUP_DATASET    - Name of the dataset to delete (default: runtime_row_probe)
#   AHRI_TRE_DELETE_PROBE       - Set to "true" to actually delete (dry-run otherwise)
#   AHRI_TRE_RUNTIME_ROOT       - Path to runtime artifact (discovered automatically)

suppressPackageStartupMessages(library(ahriTRErRs))

# Helper to find runtime root (copied in each script for self-containment)
resolve_runtime_root <- function() {
  candidates <- unique(c(
    Sys.getenv("AHRI_TRE_RUNTIME_ROOT", "/opt/ahri-tre-runtime"),
    file.path(getwd(), ".runtime", "ahri-tre-runtime"),
    "/workspaces/ahriTRErRs/.runtime/ahri-tre-runtime"
  ))
  roots <- normalizePath(path.expand(candidates), mustWork = FALSE)
  manifests <- file.path(roots, "share", "ahri-tre", "manifest.json")
  hits <- roots[file.exists(manifests)]
  if (length(hits) > 0L) hits[[1]] else roots[[1]]
}

# Load .env if present
if (file.exists(".env")) readRenviron(".env")

# Configuration
study_name <- Sys.getenv("AHRI_TRE_CLEANUP_STUDY", unset = "Copilot_Row_Probe_20260720")
dataset_name <- Sys.getenv("AHRI_TRE_CLEANUP_DATASET", unset = "runtime_row_probe")
delete_enabled <- tolower(Sys.getenv("AHRI_TRE_DELETE_PROBE", unset = "false")) %in% c("1", "true", "yes", "on")

cat(sprintf("[INFO] Cleanup target study=%s, dataset=%s\n", study_name, dataset_name))
cat(sprintf("[INFO] Destructive delete enabled=%s\n", delete_enabled))

# Locate runtime
runtime_root <- resolve_runtime_root()
Sys.setenv(AHRI_TRE_RUNTIME_ROOT = runtime_root)
manifest <- file.path(runtime_root, "share", "ahri-tre", "manifest.json")
if (!file.exists(manifest)) {
  cat("[ERROR] Runtime manifest not found. Install runtime first.\n")
  quit(save = "no", status = 1)
}

# Determine CLI binary
ahri_tre_bin <- file.path(runtime_root, "bin", "ahri-tre")
if (!file.exists(ahri_tre_bin)) {
  stop("Could not locate ahri-tre binary at ", ahri_tre_bin, call. = FALSE)
}

# Helper to run CLI commands
run_cli <- function(args) {
  env <- c(
    paste0("AHRI_TRE_RUNTIME_ROOT=", runtime_root),
    paste0("LD_LIBRARY_PATH=", file.path(runtime_root, "lib"),
           if (nzchar(Sys.getenv("LD_LIBRARY_PATH", unset = ""))) paste0(":", Sys.getenv("LD_LIBRARY_PATH")) else "")
  )
  out <- system2(ahri_tre_bin, args = args, stdout = TRUE, stderr = TRUE, env = env)
  status <- attr(out, "status")
  if (is.null(status)) status <- 0L
  list(status = status, output = out)
}

output_has <- function(res, pattern) {
  any(grepl(pattern, paste(res$output, collapse = "\n"), fixed = TRUE))
}

# Create client
client <- AhriTreClient()
on.exit(close(client), add = TRUE)

# List studies
studies <- try(study_list(client, format = "json")$object, silent = TRUE)
study_names <- character()
if (!inherits(studies, "try-error") && is.list(studies) && is.list(studies$studies)) {
  study_names <- vapply(studies$studies, function(e) {
    if (!is.null(e$study$name)) as.character(e$study$name[[1]]) else NA_character_
  }, character(1), USE.NAMES = FALSE)
  study_names <- study_names[!is.na(study_names) & nzchar(study_names)]
}

if (!(study_name %in% study_names)) {
  cat("[INFO] Study not found; nothing to clean.\n")
  quit(save = "no", status = 0)
}

# List datasets in that study
datasets <- try(dataset_list(client, study = study_name, include_versions = TRUE, format = "json")$object, silent = TRUE)
dataset_names <- character()
if (!inherits(datasets, "try-error") && is.list(datasets) && is.list(datasets$datasets)) {
  dataset_names <- vapply(datasets$datasets, function(e) {
    if (!is.null(e$catalog$asset$name)) as.character(e$catalog$asset$name[[1]]) else NA_character_
  }, character(1), USE.NAMES = FALSE)
  dataset_names <- unique(dataset_names[!is.na(dataset_names) & nzchar(dataset_names)])
}

# Delete dataset if present
if (dataset_name %in% dataset_names) {
  if (isTRUE(delete_enabled)) {
    cat(sprintf("[INFO] Deleting dataset: %s\n", dataset_name))
    dres <- run_cli(c(
      "dataset", "delete",
      "--study", study_name,
      "--dataset", dataset_name,
      "--version", "all",
      "--cascade",
      "--force",
      "--yes",
      "--reason", "cleanup temporary row-read probe",
      "--format", "json"
    ))
    cat(paste(dres$output, collapse = "\n"), "\n", sep = "")
    if (dres$status != 0L) {
      cat("[WARN] Dataset delete command returned non-zero status.\n")
    }
  } else {
    cat(sprintf("[INFO] Dry run: would delete dataset %s\n", dataset_name))
  }
} else {
  cat("[INFO] Dataset not found in study; skipping dataset delete.\n")
}

# Delete study
if (isTRUE(delete_enabled)) {
  cat(sprintf("[INFO] Deleting study: %s\n", study_name))
  sres <- run_cli(c(
    "study", "delete", study_name,
    "--reason", "cleanup temporary row-read probe study",
    "--cascade",
    "--force",
    "--yes",
    "--format", "json"
  ))
  cat(paste(sres$output, collapse = "\n"), "\n", sep = "")

  # Handle duplicate archive asset if needed
  if (sres$status != 0L && output_has(sres, "duplicate key value violates unique constraint \"i_assets_studyname\"")) {
    archived_asset <- paste0("archive_study_", gsub("-", "", study_get(client, name = study_name, format = "json")$object$registration$study$study$id[[1]]))
    cat(sprintf("[WARN] Duplicate archive asset detected; attempting targeted cleanup of %s\n", archived_asset))
    run_cli(c("study", "use", "Archive", "--format", "json"))
    ares <- run_cli(c(
      "asset", "delete",
      "--name", archived_asset,
      "--reason", "cleanup duplicate archive asset",
      "--cascade",
      "--force",
      "--yes",
      "--format", "json"
    ))
    cat(paste(ares$output, collapse = "\n"), "\n", sep = "")
    run_cli(c("study", "use", study_name, "--format", "json"))
    sres2 <- run_cli(c(
      "study", "delete", study_name,
      "--reason", "cleanup temporary row-read probe study",
      "--cascade",
      "--force",
      "--yes",
      "--format", "json"
    ))
    cat(paste(sres2$output, collapse = "\n"), "\n", sep = "")
  }

  # Verify deletion
  existing <- run_cli(c("study", "list", "--format", "json"))
  if (any(grepl(paste0('"name": "', study_name, '"'), existing$output, fixed = TRUE))) {
    cat("[WARN] Study still present after delete attempts.\n")
  } else {
    cat("[INFO] Study appears removed from study list.\n")
    run_cli(c("study", "use", "Rfam_Database_Collection", "--format", "json"))
    cat("[INFO] Current study reset to Rfam_Database_Collection.\n")
  }
} else {
  cat(sprintf("[INFO] Dry run: would delete study %s\n", study_name))
  cat("[INFO] Set AHRI_TRE_DELETE_PROBE=true to perform deletion.\n")
}