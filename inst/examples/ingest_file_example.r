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

resolve_runtime_root <- function() {
  candidates <- unique(c(
    Sys.getenv("AHRI_TRE_RUNTIME_ROOT", "/opt/ahri-tre-runtime"),
    file.path(getwd(), ".runtime", "ahri-tre-runtime"),
    "/workspaces/ahriTRErRs/.runtime/ahri-tre-runtime"
  ))
  roots <- normalizePath(path.expand(candidates), mustWork = FALSE)
  manifests <- file.path(roots, "share", "ahri-tre", "manifest.json")
  hits <- roots[file.exists(manifests)]
  if (length(hits) > 0L) hits[[1]] else roots[[1]]
}

if (file.exists(".env")) readRenviron(".env")

# Set runtime
runtime_root <- resolve_runtime_root()
Sys.setenv(AHRI_TRE_RUNTIME_ROOT = runtime_root)
cat(sprintf("[INFO] AHRI_TRE_RUNTIME_ROOT=%s\n", runtime_root))

manifest <- file.path(runtime_root, "share", "ahri-tre", "manifest.json")
if (!file.exists(manifest)) {
  cat("[WARN] Runtime manifest not found at ", manifest, "\n")
  cat("[INFO] Install runtime and rerun this example.\n")
  quit(save = "no", status = 0L)
}

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