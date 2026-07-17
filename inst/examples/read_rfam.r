suppressPackageStartupMessages(library(ahriTRErRs))
if (file.exists(".env")) readRenviron(".env")

runtime_candidates <- unique(c(
  Sys.getenv("AHRI_TRE_RUNTIME_ROOT", "/opt/ahri-tre-runtime"),
  file.path(getwd(), ".runtime", "ahri-tre-runtime"),
  "/workspaces/ahriTRErRs/.runtime/ahri-tre-runtime"
))
runtime_roots <- normalizePath(path.expand(runtime_candidates), mustWork = FALSE)
runtime_manifests <- file.path(runtime_roots, "share", "ahri-tre", "manifest.json")
runtime_hits <- runtime_roots[file.exists(runtime_manifests)]
runtime_root <- if (length(runtime_hits) > 0L) runtime_hits[[1]] else runtime_roots[[1]]
manifest <- file.path(runtime_root, "share", "ahri-tre", "manifest.json")
Sys.setenv(AHRI_TRE_RUNTIME_ROOT = runtime_root)
cat("[INFO] AHRI_TRE_RUNTIME_ROOT=", runtime_root, "\n", sep = "")

if (!file.exists(manifest)) {
  cat("[WARN] Runtime manifest not found at ", manifest, "\n", sep = "")
  cat("[INFO] Install runtime and rerun this example.\n")
  invisible(FALSE)
} else {
  client <- AhriTreClient()
  on.exit(close(client), add = TRUE)
  studies <- study_list(client, format = "json")$data
  if (is.list(studies) && is.list(studies$studies)) {
    study_names <- vapply(studies$studies, function(e) {
      if (!is.null(e$study$name)) as.character(e$study$name[[1]]) else NA_character_
    }, character(1), USE.NAMES = FALSE)
    study_names <- study_names[!is.na(study_names) & nzchar(study_names)]
  } else {
    studies_df <- if (is.data.frame(studies)) studies else as.data.frame(studies)
    if ("name" %in% names(studies_df)) {
      study_names <- as.character(studies_df$name)
      study_names <- study_names[!is.na(study_names) & nzchar(study_names)]
    } else {
      study_names <- character()
    }
  }

  cat("[INFO] Studies found: ", length(study_names), "\n", sep = "")
  if (length(study_names) == 0L) {
    cat("[WARN] No study available in active session.\n")
    invisible(FALSE)
  } else {
    target <- if ("Rfam_Database_Collection" %in% study_names) "Rfam_Database_Collection" else study_names[[1]]
    cat("[INFO] Selected study: ", target, "\n", sep = "")
    datasets <- dataset_list(client, study = target, include_versions = TRUE, format = "json")$data
    if (is.list(datasets) && is.list(datasets$datasets)) {
      dataset_names <- vapply(datasets$datasets, function(e) {
        if (!is.null(e$catalog$asset$name)) as.character(e$catalog$asset$name[[1]]) else NA_character_
      }, character(1), USE.NAMES = FALSE)
      dataset_names <- unique(dataset_names[!is.na(dataset_names) & nzchar(dataset_names)])
    } else {
      datasets_df <- if (is.data.frame(datasets)) datasets else as.data.frame(datasets)
      if ("name" %in% names(datasets_df)) {
        dataset_names <- as.character(datasets_df$name)
        dataset_names <- unique(dataset_names[!is.na(dataset_names) & nzchar(dataset_names)])
      } else {
        dataset_names <- character()
      }
    }

    cat("[INFO] Dataset entries found: ", length(dataset_names), "\n", sep = "")
    for (i in seq_len(min(10L, length(dataset_names)))) {
      cat("[INFO] Dataset ", i, ": ", dataset_names[[i]], "\n", sep = "")
    }
  }
}
