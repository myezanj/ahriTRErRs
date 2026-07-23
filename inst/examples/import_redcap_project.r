#!/usr/bin/env Rscript
# Import a REDCap project using ahriTRErRs.
# Requires REDCAP_API_URL and REDCAP_API_TOKEN in environment.

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

# ----- Main script -----

setup_runtime()
client <- create_client()
on.exit(close(client), add = TRUE)

if (!ensure_session(client, fail = TRUE)) quit(save = "no", status = 1)

# Environment variables
redcap_url <- Sys.getenv("REDCAP_API_URL", "")
redcap_token <- Sys.getenv("REDCAP_API_TOKEN", "")
domain_name <- Sys.getenv("TRE_DOMAIN", "Basic_Science")
study_name <- Sys.getenv("TRE_STUDY", "The Biology of Subclinical Asymptomic TB")

if (!nzchar(redcap_url) || !nzchar(redcap_token)) {
  stop("Set REDCAP_API_URL and REDCAP_API_TOKEN.")
}

# Ensure domain and study exist (optional: create if missing)
# For simplicity, we assume they already exist; if not, you can add them.
# Check if study exists
study_info <- try(study_get(client, name = study_name, format = "json"), silent = TRUE)
if (inherits(study_info, "try-error") || is.null(study_info$object$study)) {
  cat("[INFO] Creating study:", study_name, "\n")
  study_add(client, name = study_name, domain = domain_name, format = "json")
}

# Ingest the REDCap project
result <- try_tre(
  ingest_redcap_project(
    client,
    study = study_name,
    domain = domain_name,
    format = "json"
  ),
  context = "REDCap ingest"
)

cat("[INFO] REDCap ingest result:\n")
print(result$object)

# If the project was ingested as a datafile, we could materialize a dataset
# using ingest_dataset_datafile, but that requires knowing the asset name.
# For now, list assets to see what was created.
assets <- asset_list(client, study = study_name, format = "json")
cat("\n[INFO] Assets in study:\n")
print(assets$data_frame)

cat("\n[INFO] Done.\n")