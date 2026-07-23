#!/usr/bin/env Rscript
#
# Ingest a datafile (CSV, Parquet, etc.) into the TRE.
#
# Environment variables:
#   AHRI_TRE_STUDY          - Study name
#   AHRI_TRE_ASSET          - Asset name to create
#   AHRI_TRE_FILE_PATH      - Path to the file to ingest
#   AHRI_TRE_FILE_FORMAT    - Format (csv, parquet, etc.) – auto-detected from extension if not set
#   AHRI_TRE_RUNTIME_ROOT   - Runtime root (auto-discovered)

suppressPackageStartupMessages(library(ahriTRErRs))

if (file.exists(".env")) readRenviron(".env")

study_name <- Sys.getenv("AHRI_TRE_STUDY", "")
asset_name <- Sys.getenv("AHRI_TRE_ASSET", "")
file_path <- Sys.getenv("AHRI_TRE_FILE_PATH", "")
file_format <- Sys.getenv("AHRI_TRE_FILE_FORMAT", tolower(tools::file_ext(file_path)))

if (!nzchar(study_name) || !nzchar(asset_name) || !nzchar(file_path)) {
  cat("[INFO] Set AHRI_TRE_STUDY, AHRI_TRE_ASSET, and AHRI_TRE_FILE_PATH to run ingest. Skipping.\n")
  quit(save = "no", status = 0L)
}

if (!file.exists(file_path)) {
  cat(sprintf("[INFO] File not found: %s. Skipping.\n", file_path))
  quit(save = "no", status = 0L)
}

if (!nzchar(file_format)) {
  cat("[INFO] Set AHRI_TRE_FILE_FORMAT or provide a file extension that maps to the source format. Skipping.\n")
  quit(save = "no", status = 0L)
}

client <- AhriTreClient()
on.exit(close(client), add = TRUE)

res <- try_tre(
  ingest_datafile(client, study = study_name, asset = asset_name, path = file_path,
                  format = file_format, output_format = "json"),
  context = "datafile ingest"
)

status_value <- if (!is.null(res$envelope$status) && nzchar(as.character(res$envelope$status[[1]]))) {
  as.character(res$envelope$status[[1]])
} else {
  "ok"
}
cat(sprintf("[INFO] ingest_datafile status: %s\n", status_value))
print(res$data)