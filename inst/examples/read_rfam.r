#!/usr/bin/env Rscript
# Read datasets from the Rfam_Database_Collection study.
# Uses ahriTRErRs package; expects a live session.

library(ahriTRErRs)

# ----- Main script -----

client <- AhriTreClient()
on.exit(close(client), add = TRUE)

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
  rows <- try(dataset_data(client, study = study_name, dataset = nm, limit = 10, format = "json")$data_frame, silent = TRUE)
  if (inherits(rows, "try-error")) {
    cat("[WARN] Failed to read:", conditionMessage(rows), "\n")
    next
  }
  cat("[INFO] Rows:", nrow(rows), " Cols:", ncol(rows), "\n")
  if (nrow(rows) > 0) print(utils::head(rows, 3))
}

cat("\n[INFO] Done.\n")