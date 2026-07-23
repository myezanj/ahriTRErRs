#!/usr/bin/env Rscript
# Import a REDCap project using ahriTRErRs.
# Requires REDCAP_API_URL and REDCAP_API_TOKEN in environment.

suppressPackageStartupMessages(library(ahriTRErRs))

# ----- Main script -----

client <- AhriTreClient()
on.exit(close(client), add = TRUE)

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