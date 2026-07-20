if ("package:ahriTRErRs" %in% search()) {
  try(detach("package:ahriTRErRs", unload = TRUE, character.only = TRUE), silent = TRUE)
}
if ("ahriTRErRs" %in% loadedNamespaces()) {
  try(unloadNamespace("ahriTRErRs"), silent = TRUE)
}
suppressPackageStartupMessages(library(ahriTRErRs))
if (file.exists(".env")) readRenviron(".env")
options(ahriTRErRs.return_mode = "data.frame")

enforce_row_read <- tolower(Sys.getenv("AHRI_TRE_ENFORCE_ROW_READ", "true")) %in% c("1", "true", "yes", "on")
preflight_fail_fast <- tolower(Sys.getenv("AHRI_TRE_ROW_PREFLIGHT_FAIL_FAST", "true")) %in% c("1", "true", "yes", "on")
preferred_study <- Sys.getenv("AHRI_TRE_TARGET_STUDY", "Rfam_Database_Collection")

`%||%` <- function(lhs, rhs) if (is.null(lhs)) rhs else lhs
format_try_error <- function(err) if (inherits(err, "try-error")) conditionMessage(attr(err, "condition")) else as.character(err)
lake_path_writable <- function(path) is.character(path) && length(path) == 1L && nzchar(path) && dir.exists(path) && file.access(path, 2L) == 0L
read_rows <- function(client, study, dataset, limit = NULL) {
  data_result <- try(dataset_data(client, study = study, dataset = dataset, limit = limit, format = "json"), silent = TRUE)
  if (!inherits(data_result, "try-error") && is.data.frame(data_result$rows)) {
    attr(data_result$rows, "read_mode") <- "dataset_data"
    return(data_result$rows)
  }

  data_msg <- if (inherits(data_result, "try-error")) format_try_error(data_result) else "dataset_data returned no rows"
  preview_result <- try(dataset_preview(client, study = study, dataset = dataset, limit = limit %||% 100L, format = "json"), silent = TRUE)
  preview_msg <- if (inherits(preview_result, "try-error")) format_try_error(preview_result) else "dataset_preview diagnostic succeeded but dataset_data did not return rows"
  stop(sprintf("dataset_data error: %s | dataset_preview diagnostic: %s", data_msg, preview_msg), call. = FALSE)
}

main <- function() {
  runtime_roots <- normalizePath(path.expand(unique(c(
    Sys.getenv("AHRI_TRE_RUNTIME_ROOT", "/opt/ahri-tre-runtime"),
    file.path(getwd(), ".runtime", "ahri-tre-runtime"),
    "/workspaces/ahriTRErRs/.runtime/ahri-tre-runtime"
  ))), mustWork = FALSE)
  runtime_hits <- runtime_roots[file.exists(file.path(runtime_roots, "share", "ahri-tre", "manifest.json"))]
  runtime_root <- if (length(runtime_hits)) runtime_hits[[1]] else runtime_roots[[1]]
  manifest <- file.path(runtime_root, "share", "ahri-tre", "manifest.json")
  Sys.setenv(AHRI_TRE_RUNTIME_ROOT = runtime_root)
  cat("[INFO] AHRI_TRE_RUNTIME_ROOT=", runtime_root, "\n", sep = "")

  if (!file.exists(manifest)) {
    cat("[WARN] Runtime manifest not found at ", manifest, "\n", sep = "")
    cat("[INFO] Install runtime and rerun this example.\n")
    return(invisible(FALSE))
  }

  client <- AhriTreClient()
  on.exit(close(client), add = TRUE)
  studies_obj <- study_list(client, format = "json")$object
  study_entries <- studies_obj$studies %||% list()
  study_names <- unique(vapply(study_entries, function(entry) entry$study$name[[1]] %||% NA_character_, character(1), USE.NAMES = FALSE))
  study_names <- study_names[!is.na(study_names) & nzchar(study_names)]
  cat("[INFO] Studies found: ", length(study_names), "\n", sep = "")
  if (!length(study_names)) {
    cat("[WARN] No study available in active session.\n")
    return(invisible(FALSE))
  }

  target <- if (preferred_study %in% study_names) preferred_study else study_names[[1]]
  if (!(preferred_study %in% study_names)) {
    cat("[WARN] Preferred study not found: ", preferred_study, " (falling back to ", target, ")\n", sep = "")
  }
  cat("[INFO] Selected study: ", target, "\n", sep = "")
  cat("\n[INFO] Study details\n")
  print(tryCatch(study_get(client, name = target, format = "json")$object, error = function(...) list(study = list(name = target))))

  datafiles <- tryCatch(datafile_list(client, study = target, include_versions = TRUE, format = "json")$object$datafiles, error = function(...) list())
  datafile_names <- unique(vapply(datafiles, function(entry) entry$catalog$asset$name[[1]] %||% NA_character_, character(1), USE.NAMES = FALSE))
  datafile_names <- datafile_names[!is.na(datafile_names) & nzchar(datafile_names)]
  cat("\n[INFO] Datafile entries found: ", length(datafile_names), "\n", sep = "")
  for (i in seq_along(datafile_names)) cat("[INFO] Datafile ", i, ": ", datafile_names[[i]], "\n", sep = "")

  datasets <- tryCatch(dataset_list(client, study = target, include_versions = TRUE, format = "json")$object$datasets, error = function(...) list())
  dataset_names <- unique(vapply(datasets, function(entry) entry$catalog$asset$name[[1]] %||% NA_character_, character(1), USE.NAMES = FALSE))
  dataset_names <- dataset_names[!is.na(dataset_names) & nzchar(dataset_names)]
  cat("\n[INFO] Dataset entries found: ", length(dataset_names), "\n", sep = "")
  for (i in seq_len(min(10L, length(dataset_names)))) cat("[INFO] Dataset ", i, ": ", dataset_names[[i]], "\n", sep = "")

  session_state <- try(session_status(client, format = "json")$object, silent = TRUE)
  if (!inherits(session_state, "try-error") && is.list(session_state$session$datastore)) {
    lake_path <- session_state$session$datastore$lake_data$path[[1]] %||% ""
    lake_db <- session_state$session$datastore$lake_db$path[[1]] %||% ""
    cat("[INFO] Session lake path=", lake_path, ", writable=", as.character(lake_path_writable(lake_path)), "\n", sep = "")
    cat("[INFO] Session lake db=", lake_db, "\n", sep = "")
  }

  if (length(dataset_names)) {
    probe <- try(read_rows(client, target, dataset_names[[1]], limit = 1), silent = TRUE)
    if (inherits(probe, "try-error")) {
      cat("[WARN] Row preflight failed: ", format_try_error(probe), "\n", sep = "")
      if (enforce_row_read && preflight_fail_fast) {
        stop("Row preflight failed before metadata pass. Set AHRI_TRE_ROW_PREFLIGHT_FAIL_FAST=false to continue full diagnostics.", call. = FALSE)
      }
    } else {
      cat("[INFO] Row preflight succeeded via ", attr(probe, "read_mode") %||% "dataset_data", " on dataset ", dataset_names[[1]], " (rows=", nrow(probe), ", cols=", ncol(probe), ")\n", sep = "")
    }
  }

  cat("\n[INFO] Dataset metadata\n")
  total_rows_read <- 0L
  for (nm in dataset_names) {
    cat("\n[INFO] Metadata for dataset: ", nm, "\n", sep = "")
    print(dataset_metadata(client, study = target, dataset = nm, with_variables = TRUE, format = "json")$object)
    rows <- try(read_rows(client, target, nm), silent = TRUE)
    if (inherits(rows, "try-error")) {
      cat("[WARN] Row read failed for dataset ", nm, ": ", format_try_error(rows), "\n", sep = "")
      next
    }
    total_rows_read <- total_rows_read + nrow(rows)
    cat("[INFO] Row read for dataset ", nm, ": rows=", nrow(rows), ", cols=", ncol(rows), "\n", sep = "")
    if (nrow(rows) > 0L) print(utils::head(rows, 3))
  }

  cat("\n[INFO] Total rows read across datasets: ", total_rows_read, "\n", sep = "")
  if (!total_rows_read && length(dataset_names)) {
    session_state <- try(session_status(client, format = "json")$object, silent = TRUE)
    cat("[WARN] No dataset rows were readable in this session.\n")
    cat("[INFO] Checklist: verify live session, TRE_SERVER reachability, and DuckLake study schema/table materialization.\n")
    if (!inherits(session_state, "try-error") && is.list(session_state$session)) {
      s <- session_state$session
      cat("[INFO] Session active=", as.character(s$active), ", availability=", as.character(s$availability), "\n", sep = "")
      if (is.list(s$datastore)) {
        cat("[INFO] Datastore server=", s$datastore$server[[1]] %||% "", ", db=", s$datastore$datastore[[1]] %||% "", "\n", sep = "")
        cat("[INFO] Session lake path=", s$datastore$lake_data$path[[1]] %||% "", ", lake db=", s$datastore$lake_db$path[[1]] %||% "", "\n", sep = "")
      }
    }
    if (enforce_row_read) stop("No dataset rows were readable. Set AHRI_TRE_ENFORCE_ROW_READ=false to keep diagnostics-only mode.", call. = FALSE)
  }

  invisible(TRUE)
}

main()
