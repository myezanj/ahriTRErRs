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

study_name <- Sys.getenv('AHRI_TRE_STUDY', '')
asset_name <- Sys.getenv('AHRI_TRE_ASSET', '')
file_path <- Sys.getenv('AHRI_TRE_FILE_PATH', '')
file_format <- Sys.getenv('AHRI_TRE_FILE_FORMAT', tolower(tools::file_ext(file_path)))
if (!nzchar(study_name) || !nzchar(asset_name) || !nzchar(file_path)) {
  cat('[INFO] Set AHRI_TRE_STUDY, AHRI_TRE_ASSET, and AHRI_TRE_FILE_PATH to run ingest. Skipping.\n')
  quit(save = 'no', status = 0L)
}
if (!file.exists(file_path)) {
  cat('[INFO] File not found: ', file_path, '. Skipping.\n', sep = '')
  quit(save = 'no', status = 0L)
}
if (!nzchar(file_format)) {
  cat('[INFO] Set AHRI_TRE_FILE_FORMAT or provide a file extension that maps to the source format. Skipping.\n')
  quit(save = 'no', status = 0L)
}

client <- AhriTreClient()
on.exit(close(client), add = TRUE)
res <- try(
  ingest_datafile(client, study = study_name, asset = asset_name, path = file_path, format = file_format, output_format = 'json'),
  silent = TRUE
)
if (inherits(res, 'try-error')) {
  error_message <- conditionMessage(attr(res, 'condition'))
  cat('[ERROR] ', error_message, '\n', sep = '')
  if (grepl('lake filesystem operation failed: Permission denied', error_message, fixed = TRUE)) {
    cat('[ERROR] TRE backend lake write permission is blocking datafile ingest.\n')
  }
  quit(save = 'no', status = 1L)
}
status_value <- if (!is.null(res$envelope$status) && nzchar(as.character(res$envelope$status[[1]]))) as.character(res$envelope$status[[1]]) else 'ok'
cat('[INFO] ingest_datafile status: ', status_value, '\n', sep = '')
print(res$data)
