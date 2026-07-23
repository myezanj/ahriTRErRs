#!/usr/bin/env Rscript
#
# Ingest a large RFAM table via URI (e.g., S3, HTTP) using chunked ingestion.
#
# Environment variables:
#   AHRI_TRE_STUDY          - Study name (default: Rfam_Database_Collection)
#   AHRI_TRE_DOMAIN         - Domain name
#   AHRI_TRE_DATASET        - Dataset name
#   AHRI_TRE_TABLE_URI      - URI to the table (e.g., s3://bucket/path.parquet)
#   AHRI_TRE_TABLE_FORMAT   - Format (default: csv)
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

runtime_root <- resolve_runtime_root()
Sys.setenv(AHRI_TRE_RUNTIME_ROOT = runtime_root)
cat(sprintf("[INFO] AHRI_TRE_RUNTIME_ROOT=%s\n", runtime_root))

manifest <- file.path(runtime_root, "share", "ahri-tre", "manifest.json")
if (!file.exists(manifest)) {
  cat("[WARN] Runtime manifest not found at ", manifest, "\n")
  cat("[INFO] Install runtime and rerun this example.\n")
  quit(save = "no", status = 0L)
}

study_name <- Sys.getenv("AHRI_TRE_STUDY", "Rfam_Database_Collection")
domain_name <- Sys.getenv("AHRI_TRE_DOMAIN", "")
dataset_name <- Sys.getenv("AHRI_TRE_DATASET", "")
table_uri <- Sys.getenv("AHRI_TRE_TABLE_URI", "")
table_format <- Sys.getenv("AHRI_TRE_TABLE_FORMAT", "csv")

if (!nzchar(domain_name) || !nzchar(dataset_name) || !nzchar(table_uri)) {
  cat("[INFO] Set AHRI_TRE_DOMAIN, AHRI_TRE_DATASET, and AHRI_TRE_TABLE_URI to run chunk ingest. Skipping.\n")
  cat("[INFO] AHRI_TRE_STUDY defaults to Rfam_Database_Collection for this example.\n")
  quit(save = "no", status = 0L)
}

client <- AhriTreClient()
on.exit(close(client), add = TRUE)

res <- try_tre(
  ingest_dataset_table(
    client,
    study = study_name,
    uri = table_uri,
    domain = domain_name,
    dataset = dataset_name,
    format = table_format,
    description = paste0("staged_table_ingest_", dataset_name),
    output_format = "json"
  ),
  context = "chunked table ingest"
)

status_value <- if (!is.null(res$envelope$status) && nzchar(as.character(res$envelope$status[[1]]))) {
  as.character(res$envelope$status[[1]])
} else {
  "ok"
}
cat(sprintf("[INFO] ingest_dataset_table status: %s\n", status_value))
print(res$data)