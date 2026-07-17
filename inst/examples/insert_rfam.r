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

study_name <- "Rfam_Database_Collection"
domain_name <- Sys.getenv('AHRI_TRE_DOMAIN', 'Basic_Science')
targets <- c('family', 'clan', 'taxinomy', 'clan_membership', 'full_region', 'rfamseq')
table_dir_candidates <- unique(c(
  Sys.getenv('AHRI_TRE_TABLE_DIR', ''),
  file.path(getwd(), 'inst', 'extdata', 'rfam'),
  file.path(getwd(), 'inst', 'extdata'),
  file.path(getwd(), 'release', 'rfam')
))
table_dir_hits <- table_dir_candidates[nzchar(table_dir_candidates) & dir.exists(table_dir_candidates)]
table_dir <- if (length(table_dir_hits) > 0L) table_dir_hits[[1]] else ''
table_format <- Sys.getenv('AHRI_TRE_TABLE_FORMAT', 'csv')
table_extensions <- c(csv = '.csv', parquet = '.parquet', json = '.json', xlsx = '.xlsx', arrow = '.arrow')

client <- AhriTreClient()
on.exit(close(client), add = TRUE)
found_input <- FALSE

if (!nzchar(domain_name) || !nzchar(table_dir)) {
  cat('[INFO] Set AHRI_TRE_DOMAIN and AHRI_TRE_TABLE_DIR to run staged RFAM ingest. Skipping.\n')
  cat('[INFO] Expected staged files use one of: .csv, .parquet, .json, .xlsx, .arrow\n')
  quit(save = 'no', status = 0L)
}

for (dataset_name in targets) {
  table_var <- paste0('AHRI_TRE_MYSQL_TABLE_', toupper(dataset_name))
  table_name <- Sys.getenv(table_var, if (identical(dataset_name, 'taxinomy')) 'taxonomy' else dataset_name)
  path_var <- paste0('AHRI_TRE_TABLE_PATH_', toupper(dataset_name))
  override_path <- Sys.getenv(path_var, '')
  table_path <- ''
  missing_hint <- file.path(table_dir, paste0(table_name, '.csv'))
  detected_format <- table_format
  if (nzchar(override_path)) {
    table_path <- override_path
    missing_hint <- override_path
  } else {
    for (fmt in names(table_extensions)) {
      candidate <- file.path(table_dir, paste0(table_name, table_extensions[[fmt]]))
      if (file.exists(candidate)) {
        table_path <- candidate
        detected_format <- fmt
        break
      }
    }
  }
  description_value <- paste0('staged_table_ingest_', dataset_name)

  if (!nzchar(table_path) || !file.exists(table_path)) {
    cat('[WARN] Missing staged file for ', dataset_name, ': ', missing_hint, '\n', sep = '')
    cat('[INFO] Set ', path_var, ' or add ', table_name, '.{csv,parquet,json,xlsx,arrow} under ', table_dir, '\n', sep = '')
    next
  }

  found_input <- TRUE

  cat('[INFO] Ingesting dataset ', dataset_name, ' from ', table_path, '\n', sep = '')
  res <- try(
    ingest_dataset_table(
      client,
      study = study_name,
      domain = domain_name,
      dataset = dataset_name,
      path = table_path,
      format = detected_format,
      description = description_value,
      output_format = 'json'
    ),
    silent = TRUE
  )

  if (inherits(res, 'try-error')) {
    error_message <- conditionMessage(attr(res, 'condition'))
    cat('[ERROR] ', error_message, '\n', sep = '')
    if (grepl('lake filesystem operation failed: Permission denied', error_message, fixed = TRUE)) {
      cat('[ERROR] TRE backend lake write permission is blocking staged ingest for ', dataset_name, '.\n', sep = '')
      cat('[ERROR] This example is on a supported package path; the remaining fix is runtime/backend permission configuration.\n')
    } else {
      cat('[ERROR] Supported staged table ingest failed in the active TRE build.\n')
    }
    quit(save = 'no', status = 1L)
  }

  status_value <- if (!is.null(res$envelope$status) && nzchar(as.character(res$envelope$status[[1]]))) as.character(res$envelope$status[[1]]) else 'ok'
  cat('[INFO] ingest_dataset_table status (', dataset_name, '): ', status_value, '\n', sep = '')
  print(res$data)
}

if (!isTRUE(found_input)) {
  cat('[INFO] No staged RFAM input files were found. Skipping.\n')
  quit(save = 'no', status = 0L)
}
