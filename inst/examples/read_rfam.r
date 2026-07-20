suppressPackageStartupMessages(library(ahriTRErRs))
if (file.exists(".env")) readRenviron(".env")
options(ahriTRErRs.return_mode = "data.frame")
enforce_row_read <- tolower(Sys.getenv("AHRI_TRE_ENFORCE_ROW_READ", unset = "true")) %in% c("1", "true", "yes", "on")
preflight_fail_fast <- tolower(Sys.getenv("AHRI_TRE_ROW_PREFLIGHT_FAIL_FAST", unset = "true")) %in% c("1", "true", "yes", "on")
preferred_study <- Sys.getenv("AHRI_TRE_TARGET_STUDY", unset = "Rfam_Database_Collection")

`%||%` <- function(lhs, rhs) {
  if (is.null(lhs)) rhs else lhs
}

format_try_error <- function(err) {
  if (!inherits(err, "try-error")) {
    return(as.character(err))
  }
  message <- conditionMessage(attr(err, "condition"))
  if (is.character(message) && length(message) == 1L && nzchar(message)) {
    return(message)
  }
  as.character(err)
}

lake_path_writable <- function(path) {
  if (!is.character(path) || length(path) != 1L || !nzchar(path) || !dir.exists(path)) {
    return(FALSE)
  }
  if (file.access(path, 2L) == 0L) {
    return(TRUE)
  }
  FALSE
}

probe_rows_preflight <- function(client, study, dataset_names) {
  if (length(dataset_names) == 0L) {
    return(list(ok = FALSE, reason = "no datasets available to probe"))
  }

  probe_name <- dataset_names[[1]]
  row_read <- try(read_dataset(client, study, probe_name), silent = TRUE)
  if (!inherits(row_read, "try-error")) {
    return(list(
      ok = TRUE,
      method = attr(row_read, "read_mode") %||% "dataset_data",
      dataset = probe_name,
      rows = nrow(row_read),
      cols = ncol(row_read)
    ))
  }

  list(
    ok = FALSE,
    dataset = probe_name,
    reason = format_try_error(row_read)
  )
}

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
  studies <- study_list(client, format = "json")$object
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
    target <- if (preferred_study %in% study_names) preferred_study else study_names[[1]]
    if (!(preferred_study %in% study_names)) {
      cat("[WARN] Preferred study not found: ", preferred_study, " (falling back to ", target, ")\n", sep = "")
    }
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

    datafiles <- datafile_list(client, study = target, include_versions = TRUE, format = "json")$object
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
    for (i in seq_along(datafile_names)) {
      cat("[INFO] Datafile ", i, ": ", datafile_names[[i]], "\n", sep = "")
    }

    datasets <- dataset_list(client, study = target, include_versions = TRUE, format = "json")$object
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

    session_state <- try(session_status(client, format = "json")$object, silent = TRUE)
    if (!inherits(session_state, "try-error") && is.list(session_state) && is.list(session_state$session) && is.list(session_state$session$datastore)) {
      lake_path <- if (is.list(session_state$session$datastore$lake_data)) as.character(session_state$session$datastore$lake_data$path[[1]]) else ""
      lake_db <- if (is.list(session_state$session$datastore$lake_db)) as.character(session_state$session$datastore$lake_db$path[[1]]) else ""
      cat("[INFO] Session lake path=", lake_path, ", writable=", as.character(lake_path_writable(lake_path)), "\n", sep = "")
      cat("[INFO] Session lake db=", lake_db, "\n", sep = "")
    }

    preflight <- probe_rows_preflight(client, target, dataset_names)
    if (isTRUE(preflight$ok)) {
      cat("[INFO] Row preflight succeeded via ", preflight$method, " on dataset ", preflight$dataset,
          " (rows=", preflight$rows, ", cols=", preflight$cols, ")\n", sep = "")
    } else {
      cat("[WARN] Row preflight failed: ", preflight$reason %||% "unknown reason", "\n", sep = "")
      if (isTRUE(enforce_row_read) && isTRUE(preflight_fail_fast)) {
        stop(
          "Row preflight failed before metadata pass. Set AHRI_TRE_ROW_PREFLIGHT_FAIL_FAST=false to continue full diagnostics.",
          call. = FALSE
        )
      }
    }

    cat("\n[INFO] Dataset metadata\n")
    total_rows_read <- 0L
    for (nm in dataset_names) {
      cat("\n[INFO] Metadata for dataset: ", nm, "\n", sep = "")
      metadata <- dataset_metadata(client, study = target, dataset = nm, with_variables = TRUE, format = "json")$object
      if (is.list(metadata) && !is.data.frame(metadata)) {
        print(metadata)
      } else {
        metadata_df <- if (is.data.frame(metadata)) metadata else as.data.frame(metadata)
        print(metadata_df)
      }

      rows <- try(read_dataset(client, target, nm), silent = TRUE)
      if (inherits(rows, "try-error")) {
        cat("[WARN] Row read failed for dataset ", nm, ": ", format_try_error(rows), "\n", sep = "")
        next
      }

      read_mode <- attr(rows, "read_mode") %||% "dataset_data"
      if (!identical(read_mode, "dataset_data")) {
        cat("[INFO] Row read fallback used for dataset ", nm, ": ", read_mode, "\n", sep = "")
      }

      total_rows_read <- total_rows_read + nrow(rows)
      cat("[INFO] Row read for dataset ", nm, ": rows=", nrow(rows), ", cols=", ncol(rows), "\n", sep = "")
      if (nrow(rows) > 0L) {
        print(utils::head(rows, 3))
      }
    }

    cat("\n[INFO] Total rows read across datasets: ", total_rows_read, "\n", sep = "")
    if (total_rows_read == 0L && length(dataset_names) > 0L) {
      session_state <- try(session_status(client, format = "json")$object, silent = TRUE)
      cat("[WARN] No dataset rows were readable in this session.\n")
      cat("[INFO] Checklist: verify live session, TRE_SERVER reachability, and DuckLake study schema/table materialization.\n")
      if (!inherits(session_state, "try-error") && is.list(session_state) && is.list(session_state$session)) {
        s <- session_state$session
        cat("[INFO] Session active=", as.character(s$active), ", availability=", as.character(s$availability), "\n", sep = "")
        if (is.list(s$datastore)) {
          lake_path <- if (is.list(s$datastore$lake_data)) as.character(s$datastore$lake_data$path[[1]]) else ""
          lake_db <- if (is.list(s$datastore$lake_db)) as.character(s$datastore$lake_db$path[[1]]) else ""
          cat("[INFO] Datastore server=", as.character(s$datastore$server[[1]]), ", db=", as.character(s$datastore$datastore[[1]]), "\n", sep = "")
          cat("[INFO] Session lake path=", lake_path, ", lake db=", lake_db, "\n", sep = "")
        }
      }
      if (isTRUE(enforce_row_read)) {
        stop(
          "No dataset rows were readable. Set AHRI_TRE_ENFORCE_ROW_READ=false to keep diagnostics-only mode.",
          call. = FALSE
        )
      }
    }
  }
}
