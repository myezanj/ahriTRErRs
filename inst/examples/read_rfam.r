#!/usr/bin/env Rscript
# Read datasets from the Rfam_Database_Collection study.
# Uses ahriTRErRs package; expects a live session.

library(ahriTRErRs)

# ----- Main script -----

runtime_root <- Sys.getenv("AHRI_TRE_RUNTIME_ROOT", unset = "")
runtime_manifest_exists <- function(root) {
  nzchar(root) && file.exists(file.path(root, "share", "ahri-tre", "manifest.json"))
}

if (!runtime_manifest_exists(runtime_root)) {
  candidates <- c(
    "/workspaces/ahriTRErRs/.runtime/ahri-tre-runtime",
    "/opt/ahri-tre-runtime"
  )
  resolved <- ""
  for (cand in candidates) {
    if (runtime_manifest_exists(cand)) {
      resolved <- cand
      break
    }
  }

  if (!nzchar(resolved)) {
    stop("AHRI_TRE_RUNTIME_ROOT is unset or invalid, and no local runtime artifact was found.")
  }

  Sys.setenv(AHRI_TRE_RUNTIME_ROOT = resolved)
  runtime_root <- resolved
  cat("[INFO] Using AHRI_TRE_RUNTIME_ROOT:", resolved, "\n")
}

client <- AhriTreClient()
on.exit(close(client), add = TRUE)

with_client_retry <- function(expr, retries = 1L) {
  attempts <- 0L
  repeat {
    attempts <- attempts + 1L
    out <- try(eval.parent(substitute(expr)), silent = TRUE)
    if (!inherits(out, "try-error")) {
      return(out)
    }

    msg <- as.character(out)
    if (attempts > retries || !grepl("client handle is closed or invalid", msg, fixed = TRUE)) {
      stop(msg)
    }

    cat("[WARN] Client handle invalid; recreating AhriTreClient() and retrying...\n")
    try(close(client), silent = TRUE)
    client <<- AhriTreClient()
  }
}

# List domains
domains <- with_client_retry(domain_list(client, format = "json"))
cat("\n[INFO] Domains found:\n")
print(domains$data_frame)

# Get Basic_Science domain
domain_info <- with_client_retry(domain_get(client, name = "Basic_Science", format = "json"))
if (is.null(domain_info$object$domain)) {
  stop("Domain 'Basic_Science' not found.")
}
cat("\n[INFO] Domain details:\n")
print(domain_info$object$domain)

# List studies
studies <- with_client_retry(study_list(client, format = "json"))
cat("\n[INFO] Studies found:\n")
print(studies$data_frame)

study_name <- "Rfam_Database_Collection"
study <- with_client_retry(study_get(client, name = study_name, format = "json"))
if (is.null(study$object$study)) {
  stop("Study not found: ", study_name)
}
cat("\n[INFO] Using study:", study_name, "\n")

# List datasets in the study
datasets <- with_client_retry(dataset_list(client, study = study_name, include_versions = TRUE, format = "json"))
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
  rows <- try(with_client_retry(dataset_data(client, study = study_name, dataset = nm, limit = 10, format = "json"))$data_frame, silent = TRUE)
  if (inherits(rows, "try-error")) {
    cat("[WARN] Failed to read:", as.character(rows), "\n")
    next
  }
  cat("[INFO] Rows:", nrow(rows), " Cols:", ncol(rows), "\n")
  if (nrow(rows) > 0) print(utils::head(rows, 3))
}

cat("\n[INFO] Done.\n")