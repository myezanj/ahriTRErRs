#!/usr/bin/env Rscript
# Read datasets from the Rfam_Database_Collection study.
# Uses ahriTRErRs package; expects a live session.

suppressPackageStartupMessages(library(ahriTRErRs))

# ----- Helper functions (self-contained) -----

resolve_runtime_root <- function() {
  candidates <- unique(c(
    Sys.getenv("AHRI_TRE_RUNTIME_ROOT", ""),
    file.path(getwd(), ".runtime", "ahri-tre-runtime"),
    "/opt/ahri-tre-runtime"
  ))
  candidates <- candidates[nzchar(candidates)]
  roots <- normalizePath(path.expand(candidates), mustWork = FALSE)
  manifests <- file.path(roots, "share", "ahri-tre", "manifest.json")
  hits <- roots[file.exists(manifests)]
  if (length(hits) > 0L) hits[[1]] else roots[[1]]
}

setup_runtime <- function() {
  root <- resolve_runtime_root()
  if (!file.exists(file.path(root, "share", "ahri-tre", "manifest.json"))) {
    stop("AHRI TRE runtime not found. Set AHRI_TRE_RUNTIME_ROOT or install runtime.")
  }
  Sys.setenv(AHRI_TRE_RUNTIME_ROOT = root)
  cat("[INFO] Using runtime root:", root, "\n")
  invisible(root)
}

create_client <- function(max_attempts = 2L) {
  for (attempt in seq_len(max_attempts)) {
    client <- tryCatch(AhriTreClient(), error = function(e) e)
    if (!inherits(client, "error")) {
      return(client)
    }
    if (attempt < max_attempts) {
      cat("[WARN] Client creation failed, retrying...\n")
      Sys.sleep(1)
    } else {
      stop("Failed to create client after ", max_attempts, " attempts: ", conditionMessage(client))
    }
  }
}

has_live_session <- function(client) {
  status <- try(session_status(client, format = "json")$object, silent = TRUE)
  if (inherits(status, "try-error") || is.null(status$session)) return(FALSE)
  isTRUE(status$session$active) && identical(status$session$availability %||% "", "live")
}

ensure_session <- function(client, fail = TRUE) {
  if (has_live_session(client)) return(TRUE)
  cat("[WARN] No live session is active.\n")
  cat("Run 'Rscript inst/examples/open_oauth_session.r' to open one.\n")
  if (isTRUE(fail)) stop("Live session required.")
  FALSE
}

read_dataset_rows <- function(client, study, dataset, limit = NULL) {
  result <- dataset_data(client, study = study, dataset = dataset, limit = limit, format = "json")
  result$data_frame  # returns data frame if available
}

# ----- Main script -----

setup_runtime()
client <- create_client()
on.exit(close(client), add = TRUE)

if (!ensure_session(client, fail = TRUE)) quit(save = "no", status = 1)

# List domains
domains <- domain_list(client, format = "json")
cat("\n[INFO] Domains found:\n")
print(domains$data_frame)

# Get Basic_Science domain
domain_info <- domain_get(client, name = "Basic_Science", format = "json")
if (is.null(domain_info$object$domain)) {
  stop("Domain 'Basic_Science' not found.")
}
cat("\n[INFO] Domain details:\n")
print(domain_info$object$domain)

# List studies
studies <- study_list(client, format = "json")
cat("\n[INFO] Studies found:\n")
print(studies$data_frame)

study_name <- "Rfam_Database_Collection"
study <- study_get(client, name = study_name, format = "json")
if (is.null(study$object$study)) {
  stop("Study not found: ", study_name)
}
cat("\n[INFO] Using study:", study_name, "\n")

# List datasets in the study
datasets <- dataset_list(client, study = study_name, include_versions = TRUE, format = "json")
cat("\n[INFO] Datasets in study:\n")
print(datasets$data_frame)

# Get dataset names
ds_names <- unique(datasets$data_frame$name)
if (length(ds_names) == 0) {
  cat("[WARN] No datasets found.\n")
  quit(save = "no", status = 0)
}

# Read first few rows from each dataset
for (nm in ds_names) {
  cat("\n[INFO] Reading dataset:", nm, "\n")
  rows <- try(read_dataset_rows(client, study_name, nm, limit = 10), silent = TRUE)
  if (inherits(rows, "try-error")) {
    cat("[WARN] Failed to read:", conditionMessage(rows), "\n")
    next
  }
  cat("[INFO] Rows:", nrow(rows), " Cols:", ncol(rows), "\n")
  if (nrow(rows) > 0) print(utils::head(rows, 3))
}

cat("\n[INFO] Done.\n")