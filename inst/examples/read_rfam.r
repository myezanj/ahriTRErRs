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

    study_info <- NULL
    if (is.list(studies) && is.list(studies$studies)) {
      matched <- studies$studies[vapply(studies$studies, function(e) {
        !is.null(e$study$name) && identical(as.character(e$study$name[[1]]), target)
      }, logical(1), USE.NAMES = FALSE)]
      if (length(matched) > 0L) {
        study_info <- matched[[1]]
      }
    }

    if (is.null(study_info)) {
      study_info <- list(study = list(name = target))
    }
    cat("\n[INFO] Study details\n")
    if (is.list(study_info) && !is.data.frame(study_info)) {
      print(study_info)
    } else {
      study_df <- if (is.data.frame(study_info)) study_info else as.data.frame(study_info)
      print(study_df)
    }

    datafiles <- datafile_list(client, study = target, include_versions = TRUE, format = "json")$data
    datafile_names <- character()
    if (is.list(datafiles) && is.list(datafiles$datafiles)) {
      datafile_names <- vapply(datafiles$datafiles, function(e) {
        if (!is.null(e$catalog$asset$name)) as.character(e$catalog$asset$name[[1]]) else NA_character_
      }, character(1), USE.NAMES = FALSE)
      datafile_names <- unique(datafile_names[!is.na(datafile_names) & nzchar(datafile_names)])
    } else {
      datafiles_df <- if (is.data.frame(datafiles)) datafiles else as.data.frame(datafiles)
      if ("name" %in% names(datafiles_df)) {
        datafile_names <- as.character(datafiles_df$name)
        datafile_names <- unique(datafile_names[!is.na(datafile_names) & nzchar(datafile_names)])
      }
    }

    cat("\n[INFO] Datafile entries found: ", length(datafile_names), "\n", sep = "")
    for (i in seq_len(length(datafile_names))) {
      cat("[INFO] Datafile ", i, ": ", datafile_names[[i]], "\n", sep = "")
    }

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

    cat("\n[INFO] Dataset entries found: ", length(dataset_names), "\n", sep = "")
    for (i in seq_len(min(10L, length(dataset_names)))) {
      cat("[INFO] Dataset ", i, ": ", dataset_names[[i]], "\n", sep = "")
    }

    cat("\n[INFO] Dataset metadata\n")
    for (nm in dataset_names) {
      cat("\n[INFO] Metadata for dataset: ", nm, "\n", sep = "")
      metadata <- dataset_metadata(client, study = target, dataset = nm, with_variables = TRUE, format = "json")$data
      if (is.list(metadata) && !is.data.frame(metadata)) {
        print(metadata)
      } else {
        metadata_df <- if (is.data.frame(metadata)) metadata else as.data.frame(metadata)
        print(metadata_df)
      }
    }
  }
}
