suppressPackageStartupMessages(library(ahriTRErRs))
if (file.exists('.env')) readRenviron('.env')

runtime_candidates <- unique(c(Sys.getenv('AHRI_TRE_RUNTIME_ROOT', '/opt/ahri-tre-runtime'), file.path(getwd(), '.runtime', 'ahri-tre-runtime'), '/workspaces/ahriTRErRs/.runtime/ahri-tre-runtime'))
runtime_roots <- normalizePath(path.expand(runtime_candidates), mustWork = FALSE)
runtime_manifests <- file.path(runtime_roots, 'share', 'ahri-tre', 'manifest.json')
runtime_hits <- runtime_roots[file.exists(runtime_manifests)]
runtime_root <- if (length(runtime_hits) > 0L) runtime_hits[[1]] else runtime_roots[[1]]
manifest <- file.path(runtime_root, 'share', 'ahri-tre', 'manifest.json')
Sys.setenv(AHRI_TRE_RUNTIME_ROOT = runtime_root)
cat('[INFO] AHRI_TRE_RUNTIME_ROOT=', runtime_root, '\n', sep = '')

if (!file.exists(manifest)) {
  cat('[WARN] Runtime manifest not found at ', manifest, '\n', sep = '')
  cat('[INFO] Install runtime and rerun this example.\n')
  quit(save = 'no', status = 0L)
}

study_name <- Sys.getenv('AHRI_TRE_STUDY', 'Rfam_Database_Collection')
domain_name <- Sys.getenv('AHRI_TRE_DOMAIN', '')
dataset_name <- Sys.getenv('AHRI_TRE_DATASET', '')
table_uri <- Sys.getenv('AHRI_TRE_TABLE_URI', '')
table_format <- Sys.getenv('AHRI_TRE_TABLE_FORMAT', 'csv')
if (!nzchar(domain_name) || !nzchar(dataset_name) || !nzchar(table_uri)) {
  cat('[INFO] Set AHRI_TRE_DOMAIN, AHRI_TRE_DATASET, and AHRI_TRE_TABLE_URI to run chunk ingest. Skipping.\n')
  cat('[INFO] AHRI_TRE_STUDY defaults to Rfam_Database_Collection for this example.\n')
  quit(save = 'no', status = 0L)
}

client <- AhriTreClient()
on.exit(close(client), add = TRUE)
res <- try(
  ingest_dataset_table(
    client,
    study = study_name,
    uri = table_uri,
    domain = domain_name,
    dataset = dataset_name,
    format = table_format,
    description = paste0('staged_table_ingest_', dataset_name),
    output_format = 'json'
  ),
  silent = TRUE
)
if (inherits(res, 'try-error')) {
  error_message <- conditionMessage(attr(res, 'condition'))
  cat('[ERROR] ', error_message, '\n', sep = '')
  if (grepl('lake filesystem operation failed: Permission denied', error_message, fixed = TRUE)) {
    cat('[ERROR] TRE backend lake write permission is blocking chunk ingest for ', dataset_name, '.\n', sep = '')
  }
  quit(save = 'no', status = 1L)
}
status_value <- if (!is.null(res$envelope$status) && nzchar(as.character(res$envelope$status[[1]]))) as.character(res$envelope$status[[1]]) else 'ok'
cat('[INFO] ingest_dataset_table status: ', status_value, '\n', sep = '')
print(res$data)
