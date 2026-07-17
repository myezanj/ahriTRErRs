suppressPackageStartupMessages(library(ahriTRErRs))
if (file.exists(".env")) readRenviron(".env")

runtime_manifest <- function(root) file.path(root, "share", "ahri-tre", "manifest.json")

resolve_runtime_root <- function() {
  candidates <- unique(c(
    Sys.getenv("AHRI_TRE_RUNTIME_ROOT", "/opt/ahri-tre-runtime"),
    file.path(getwd(), ".runtime", "ahri-tre-runtime"),
    "/workspaces/ahriTRErRs/.runtime/ahri-tre-runtime"
  ))
  roots <- normalizePath(path.expand(candidates), mustWork = FALSE)
  hits <- roots[file.exists(runtime_manifest(roots))]
  if (length(hits) > 0L) hits[[1]] else roots[[1]]
}

to_df <- function(x) {
  if (is.null(x)) return(data.frame())
  if (is.data.frame(x)) return(x)
  if (is.character(x) && length(x) == 1L && nzchar(x)) {
    parsed <- try(jsonlite::fromJSON(x, simplifyDataFrame = TRUE), silent = TRUE)
    if (!inherits(parsed, "try-error")) return(to_df(parsed))
  }
  tryCatch(as.data.frame(x), error = function(...) data.frame())
}

extract_study_names <- function(studies_raw) {
  if (is.list(studies_raw) && is.list(studies_raw$studies)) {
    vals <- vapply(studies_raw$studies, function(e) {
      if (!is.null(e$study$name)) as.character(e$study$name[[1]]) else NA_character_
    }, character(1), USE.NAMES = FALSE)
    return(vals[!is.na(vals) & nzchar(vals)])
  }
  df <- to_df(studies_raw)
  if ("name" %in% names(df)) {
    vals <- as.character(df$name)
    return(vals[!is.na(vals) & nzchar(vals)])
  }
  character()
}

extract_dataset_names <- function(datasets_raw) {
  if (is.list(datasets_raw) && is.list(datasets_raw$datasets)) {
    vals <- vapply(datasets_raw$datasets, function(e) {
      if (!is.null(e$catalog$asset$name)) as.character(e$catalog$asset$name[[1]]) else NA_character_
    }, character(1), USE.NAMES = FALSE)
    vals <- vals[!is.na(vals) & nzchar(vals)]
    return(unique(vals))
  }
  df <- to_df(datasets_raw)
  if ("name" %in% names(df)) {
    vals <- as.character(df$name)
    vals <- vals[!is.na(vals) & nzchar(vals)]
    return(unique(vals))
  }
  character()
}

safe_preview <- function(client, study_name, dataset_name, limit = 10L) {
  out <- try(dataset_preview(client, study = study_name, dataset = dataset_name, limit = limit, format = "json"), silent = TRUE)
  if (inherits(out, "try-error")) return(list(ok = FALSE, msg = as.character(out)))
  rows <- if (is.data.frame(out$data_frame)) out$data_frame else to_df(out$data)
  list(ok = TRUE, rows = rows)
}

runtime_root <- resolve_runtime_root()
manifest <- runtime_manifest(runtime_root)
Sys.setenv(AHRI_TRE_RUNTIME_ROOT = runtime_root)
cat("[INFO] AHRI_TRE_RUNTIME_ROOT=", runtime_root, "\n", sep = "")

if (!file.exists(manifest)) {
  cat("[WARN] Runtime manifest not found at ", manifest, "\n", sep = "")
  cat("[INFO] Install runtime and rerun this example.\n")
  invisible(FALSE)
} else {
  client <- tryCatch(AhriTreClient(), error = function(e) e)
  if (inherits(client, "error")) {
    cat("[WARN] Failed to open client: ", conditionMessage(client), "\n", sep = "")
    invisible(FALSE)
  } else {
    on.exit(close(client), add = TRUE)
    studies <- tryCatch(study_list(client, format = "json")$data, error = function(e) e)
    if (inherits(studies, "error")) {
      cat("[WARN] study_list failed: ", conditionMessage(studies), "\n", sep = "")
      invisible(FALSE)
    } else {
      study_names <- extract_study_names(studies)
      cat("[INFO] Studies found: ", length(study_names), "\n", sep = "")
      if (length(study_names) == 0L) {
        cat("[WARN] No study available in active session.\n")
        invisible(FALSE)
      } else {
        target <- if ("Rfam_Database_Collection" %in% study_names) "Rfam_Database_Collection" else study_names[[1]]
        cat("[INFO] Selected study: ", target, "\n", sep = "")
        datasets <- tryCatch(dataset_list(client, study = target, include_versions = TRUE, format = "json")$data, error = function(e) e)
        if (inherits(datasets, "error")) {
          cat("[WARN] dataset_list failed: ", conditionMessage(datasets), "\n", sep = "")
          invisible(FALSE)
        } else {
          names <- extract_dataset_names(datasets)
          cat("[INFO] Dataset entries found: ", length(names), "\n", sep = "")
          for (i in seq_len(min(3L, length(names)))) {
            nm <- names[[i]]
            cat("[INFO] Preview dataset ", i, ": ", nm, "\n", sep = "")
            preview <- safe_preview(client, target, nm, limit = 10L)
            if (!isTRUE(preview$ok)) {
              cat("[WARN] Preview failed for ", nm, ": ", preview$msg, "\n", sep = "")
            } else {
              cat("[INFO] Rows=", nrow(preview$rows), " Cols=", ncol(preview$rows), "\n", sep = "")
            }
          }
        }
      }
    }
  }
}
