suppressPackageStartupMessages(library(ahriTRErRs))
if (file.exists(".env")) readRenviron(".env")
options(ahriTRErRs.return_mode = "json")

study_name <- Sys.getenv("AHRI_TRE_CLEANUP_STUDY", unset = "Copilot_Row_Probe_20260720")
dataset_name <- Sys.getenv("AHRI_TRE_CLEANUP_DATASET", unset = "runtime_row_probe")
delete_enabled <- tolower(Sys.getenv("AHRI_TRE_DELETE_PROBE", unset = "false")) %in% c("1", "true", "yes", "on")

cat("[INFO] Cleanup target study=", study_name, ", dataset=", dataset_name, "\n", sep = "")
cat("[INFO] Destructive delete enabled=", delete_enabled, "\n", sep = "")

runtime_candidates <- unique(c(
  Sys.getenv("AHRI_TRE_RUNTIME_ROOT", "/opt/ahri-tre-runtime"),
  file.path(getwd(), ".runtime", "ahri-tre-runtime"),
  "/workspaces/ahriTRErRs/.runtime/ahri-tre-runtime"
))
runtime_roots <- normalizePath(path.expand(runtime_candidates), mustWork = FALSE)
runtime_manifests <- file.path(runtime_roots, "share", "ahri-tre", "manifest.json")
runtime_hits <- runtime_roots[file.exists(runtime_manifests)]
runtime_root <- if (length(runtime_hits) > 0L) runtime_hits[[1]] else runtime_roots[[1]]
ahri_tre_bin <- file.path(runtime_root, "bin", "ahri-tre")
if (!file.exists(ahri_tre_bin)) {
  stop("Could not locate ahri-tre binary at ", ahri_tre_bin, call. = FALSE)
}

run_cli <- function(args) {
  env <- c(
    paste0("AHRI_TRE_RUNTIME_ROOT=", runtime_root),
    paste0("LD_LIBRARY_PATH=", file.path(runtime_root, "lib"), if (nzchar(Sys.getenv("LD_LIBRARY_PATH", unset = ""))) paste0(":", Sys.getenv("LD_LIBRARY_PATH")) else "")
  )
  out <- system2(ahri_tre_bin, args = args, stdout = TRUE, stderr = TRUE, env = env)
  status <- attr(out, "status")
  if (is.null(status)) status <- 0L
  list(status = status, output = out)
}

output_has <- function(res, pattern) {
  any(grepl(pattern, paste(res$output, collapse = "\n"), fixed = TRUE))
}

client <- AhriTreClient()
on.exit(close(client), add = TRUE)

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

datasets <- try(dataset_list(client, study = study_name, include_versions = TRUE, format = "json")$object, silent = TRUE)
dataset_names <- character()
if (!inherits(datasets, "try-error") && is.list(datasets) && is.list(datasets$datasets)) {
  dataset_names <- vapply(datasets$datasets, function(e) {
    if (!is.null(e$catalog$asset$name)) as.character(e$catalog$asset$name[[1]]) else NA_character_
  }, character(1), USE.NAMES = FALSE)
  dataset_names <- unique(dataset_names[!is.na(dataset_names) & nzchar(dataset_names)])
}

if (dataset_name %in% dataset_names) {
  if (isTRUE(delete_enabled)) {
    cat("[INFO] Deleting dataset: ", dataset_name, "\n", sep = "")
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
    cat("[INFO] Dry run: would delete dataset ", dataset_name, "\n", sep = "")
  }
} else {
  cat("[INFO] Dataset not found in study; skipping dataset delete.\n")
}

if (isTRUE(delete_enabled)) {
  cat("[INFO] Deleting study: ", study_name, "\n", sep = "")
  sres <- run_cli(c(
    "study", "delete", study_name,
    "--reason", "cleanup temporary row-read probe study",
    "--cascade",
    "--force",
    "--yes",
    "--format", "json"
  ))
  cat(paste(sres$output, collapse = "\n"), "\n", sep = "")

  if (sres$status != 0L && output_has(sres, "duplicate key value violates unique constraint \"i_assets_studyname\"")) {
    archived_asset <- paste0("archive_study_", gsub("-", "", study_get(client, name = study_name, format = "json")$object$registration$study$study$id[[1]]))
    cat("[WARN] Duplicate archive asset detected; attempting targeted cleanup of ", archived_asset, "\n", sep = "")
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

  existing <- run_cli(c("study", "list", "--format", "json"))
  if (any(grepl(paste0('"name": "', study_name, '"'), existing$output, fixed = TRUE))) {
    cat("[WARN] Study still present after delete attempts.\n")
  } else {
    cat("[INFO] Study appears removed from study list.\n")
    run_cli(c("study", "use", "Rfam_Database_Collection", "--format", "json"))
    cat("[INFO] Current study reset to Rfam_Database_Collection.\n")
  }
} else {
  cat("[INFO] Dry run: would delete study ", study_name, "\n", sep = "")
  cat("[INFO] Set AHRI_TRE_DELETE_PROBE=true to perform deletion.\n")
}
