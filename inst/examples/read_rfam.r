#!/usr/bin/env Rscript
# Read datasets from the Rfam_Database_Collection study.
# Uses package-level wrappers and expects a live session.

if (requireNamespace("devtools", quietly = TRUE) &&
    file.exists(file.path(getwd(), "DESCRIPTION")) &&
    file.exists(file.path(getwd(), "R", "core.r"))) {
  # Prefer local source wrappers when running from repository root.
  devtools::load_all(getwd(), quiet = TRUE)
} else {
  library(ahriTRErRs)
}

`%||%` <- function(x, y) if (is.null(x)) y else x

runtime_manifest_exists <- function(root) {
  nzchar(root) && file.exists(file.path(root, "share", "ahri-tre", "manifest.json"))
}

to_data_frame <- function(x) {
  if (is.null(x)) return(NULL)
  if (is.data.frame(x)) return(x)
  if (is.list(x)) {
    for (cand in c("rows", "items", "studies", "datasets", "domains", "data")) {
      if (!is.null(x[[cand]])) return(to_data_frame(x[[cand]]))
    }
  }
  converted <- try(
    jsonlite::fromJSON(jsonlite::toJSON(x, auto_unbox = TRUE), simplifyDataFrame = TRUE),
    silent = TRUE
  )
  if (!inherits(converted, "try-error") && is.data.frame(converted)) converted else NULL
}

runtime_root <- Sys.getenv("AHRI_TRE_RUNTIME_ROOT", unset = "")
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
on.exit(try(close(client), silent = TRUE), add = TRUE)

with_client_retry <- function(expr, retries = 1L) {
  attempts <- 0L
  repeat {
    attempts <- attempts + 1L
    out <- try(eval.parent(substitute(expr)), silent = TRUE)
    if (!inherits(out, "try-error")) return(out)

    msg <- as.character(out)
    if (attempts > retries || !grepl("client handle is closed or invalid", msg, fixed = TRUE)) {
      stop(msg)
    }

    cat("[WARN] Client handle invalid; recreating AhriTreClient() and retrying...\n")
    try(close(client), silent = TRUE)
    client <<- AhriTreClient()
  }
}

read_wrapper_data <- function(expr, context, optional = FALSE) {
  out <- try(with_client_retry(expr), silent = TRUE)
  if (inherits(out, "try-error")) {
    msg <- as.character(out)
    if (optional && (
      grepl("request envelope is invalid", msg, fixed = TRUE) ||
      grepl("no live session is selected", msg, fixed = TRUE)
    )) {
      cat("[WARN]", context, "unavailable in current session; skipping.\n")
      return(NULL)
    }
    stop(msg)
  }

  data <- out$data %||% NULL
  if (is.null(data)) {
    if (optional) {
      cat("[WARN]", context, "returned no data; skipping.\n")
    } else {
      cat("[WARN]", context, "returned no data.\n")
    }
    return(NULL)
  }
  data
}

# List domains
domains <- read_wrapper_data(domain_list(client, format = "json"), "domain_list", optional = TRUE)
if (!is.null(domains)) {
  cat("\n[INFO] Domains found:\n")
  print(to_data_frame(domains) %||% domains)
}

# Get Basic_Science domain
domain_info <- read_wrapper_data(domain_get(client, name = "Basic_Science", format = "json"), "domain_get", optional = TRUE)
if (!is.null(domain_info)) {
  if (is.null(domain_info$domain)) {
    cat("[WARN] Domain 'Basic_Science' not found; continuing.\n")
  } else {
    cat("\n[INFO] Domain details:\n")
    print(domain_info$domain)
  }
}

# List studies
studies <- read_wrapper_data(study_list(client, format = "json"), "study_list")
studies_df <- to_data_frame(studies)
if (is.null(studies_df) || nrow(studies_df) == 0) {
  cat("[WARN] study_list unavailable or empty. Open/select a live session first:\n")
  cat("       ahri-tre session list\n")
  cat("       ahri-tre session use <name>\n")
  cat("       ahri-tre session open-oauth <name> --profile <profile>\n")
  quit(save = "no", status = 0)
}
cat("\n[INFO] Studies found:\n")
print(studies_df)

study_name <- "Rfam_Database_Collection"
study <- read_wrapper_data(study_get(client, name = study_name, format = "json"), "study_get", optional = TRUE)
if (is.null(study) || is.null(study$study)) {
  cat("[WARN] study_get failed or study was not returned; proceeding with study name fallback.\n")
}
cat("\n[INFO] Using study:", study_name, "\n")

# List datasets in the study
datasets <- read_wrapper_data(
  dataset_list(client, study = study_name, include_versions = TRUE, format = "json"),
  "dataset_list"
)
datasets_df <- to_data_frame(datasets)
cat("\n[INFO] Datasets in study:\n")
print(datasets_df)

if (is.null(datasets_df) || is.null(datasets_df$name)) {
  stop("dataset_list did not return tabular dataset names.")
}

ds_names <- unique(datasets_df$name)
if (length(ds_names) == 0) {
  cat("[WARN] No datasets found.\n")
  quit(save = "no", status = 0)
}

# Read first few rows from each dataset
for (nm in ds_names) {
  cat("\n[INFO] Reading dataset:", nm, "\n")
  rows <- try(
    to_data_frame(
      read_wrapper_data(
        dataset_data(client, study = study_name, dataset = nm, limit = 10, format = "json"),
        paste0("dataset_data:", nm)
      )
    ),
    silent = TRUE
  )
  if (inherits(rows, "try-error") || is.null(rows)) {
    cat("[WARN] Failed to read dataset rows for", nm, "\n")
    next
  }
  cat("[INFO] Rows:", nrow(rows), " Cols:", ncol(rows), "\n")
  if (nrow(rows) > 0) print(utils::head(rows, 3))
}

cat("\n[INFO] Done.\n")
