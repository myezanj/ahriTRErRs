#!/usr/bin/env Rscript
# Read datasets from the Rfam_Database_Collection study.
# Uses package-level wrappers and expects a live session.

if (requireNamespace("devtools", quietly = TRUE) &&
    file.exists(file.path(getwd(), "DESCRIPTION")) &&
    file.exists(file.path(getwd(), "R", "core.r"))) {
  devtools::load_all(getwd(), quiet = TRUE)
} else {
  library(ahriTRErRs)
}

runtime_root <- Sys.getenv("AHRI_TRE_RUNTIME_ROOT", unset = "")
runtime_ok <- nzchar(runtime_root) && file.exists(file.path(runtime_root, "share", "ahri-tre", "manifest.json"))
if (!runtime_ok) {
  candidates <- c(
    "/workspaces/ahriTRErRs/.runtime/ahri-tre-runtime",
    "/opt/ahri-tre-runtime"
  )

  resolved <- ""
  for (cand in candidates) {
    if (nzchar(cand) && file.exists(file.path(cand, "share", "ahri-tre", "manifest.json"))) {
      resolved <- cand
      break
    }
  }

  if (!nzchar(resolved)) {
    stop("AHRI_TRE_RUNTIME_ROOT is unset or invalid, and no local runtime artifact was found.")
  }

  Sys.setenv(AHRI_TRE_RUNTIME_ROOT = resolved)
  cat("[INFO] Using AHRI_TRE_RUNTIME_ROOT:", resolved, "\n")
}

client <- AhriTreClient()
on.exit(try(close(client), silent = TRUE), add = TRUE)

domains_result <- try(domain_list(client, format = "json"), silent = TRUE)
if (inherits(domains_result, "try-error") && grepl("client handle is closed or invalid", as.character(domains_result), fixed = TRUE)) {
  cat("[WARN] Client handle invalid; recreating AhriTreClient() and retrying...\n")
  try(close(client), silent = TRUE)
  client <- AhriTreClient()
  domains_result <- try(domain_list(client, format = "json"), silent = TRUE)
}

if (!inherits(domains_result, "try-error") && !is.null(domains_result$data)) {
  cat("\n[INFO] Domains found:\n")
  print(domains_result$data)
} else {
  cat("[WARN] domain_list unavailable in current session; skipping.\n")
}

domain_get_result <- try(domain_get(client, name = "Basic_Science", format = "json"), silent = TRUE)
if (!inherits(domain_get_result, "try-error") && !is.null(domain_get_result$data$domain)) {
  cat("\n[INFO] Domain details:\n")
  print(domain_get_result$data$domain)
} else {
  cat("[WARN] domain_get unavailable in current session; skipping.\n")
}

studies_result <- try(study_list(client, format = "json"), silent = TRUE)
if (inherits(studies_result, "try-error") || is.null(studies_result$data) || !is.data.frame(studies_result$data) || nrow(studies_result$data) == 0) {
  cat("[WARN] study_list unavailable or empty. Open/select a live session first:\n")
  cat("       ahri-tre session list\n")
  cat("       ahri-tre session use <name>\n")
  cat("       ahri-tre session open-oauth <name> --profile <profile>\n")
  quit(save = "no", status = 0)
}

cat("\n[INFO] Studies found:\n")
print(studies_result$data)

study_name <- "Rfam_Database_Collection"
study_get_result <- try(study_get(client, name = study_name, format = "json"), silent = TRUE)
if (inherits(study_get_result, "try-error") || is.null(study_get_result$data$study)) {
  cat("[WARN] study_get failed or study was not returned; proceeding with study name fallback.\n")
}
cat("\n[INFO] Using study:", study_name, "\n")

datasets_result <- try(
  dataset_list(client, study = study_name, include_versions = TRUE, format = "json"),
  silent = TRUE
)
if (inherits(datasets_result, "try-error") || is.null(datasets_result$data) || !is.data.frame(datasets_result$data)) {
  stop("dataset_list did not return tabular dataset names.")
}

cat("\n[INFO] Datasets in study:\n")
print(datasets_result$data)

ds_names <- unique(datasets_result$data$name)
if (length(ds_names) == 0) {
  cat("[WARN] No datasets found.\n")
  quit(save = "no", status = 0)
}

for (nm in ds_names) {
  cat("\n[INFO] Reading dataset:", nm, "\n")
  rows_result <- try(
    dataset_data(client, study = study_name, dataset = nm, limit = 10, format = "json"),
    silent = TRUE
  )
  if (inherits(rows_result, "try-error") || is.null(rows_result$data) || !is.data.frame(rows_result$data)) {
    cat("[WARN] Failed to read dataset rows for", nm, "\n")
    next
  }

  cat("[INFO] Rows:", nrow(rows_result$data), " Cols:", ncol(rows_result$data), "\n")
  if (nrow(rows_result$data) > 0) print(utils::head(rows_result$data, 3))
}

cat("\n[INFO] Done.\n")
