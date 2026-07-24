suppressPackageStartupMessages(library(ahriTRErRs))
if (file.exists('.env')) readRenviron('.env')

runtime_root <- tryCatch(
  runtime_ensure_root(candidates = c(
    '/workspaces/ahriTRErRs/.runtime/ahri-tre-runtime',
    '/opt/ahri-tre-runtime'
  )),
  error = function(e) {
    cat('[INFO] Runtime manifest not found. Skipping.\n')
    quit(save = 'no', status = 0L)
  }
)
cat('[INFO] Using AHRI_TRE_RUNTIME_ROOT: ', runtime_root, '\n', sep = '')

client <- NULL
studies <- NULL
for (attempt in seq_len(2L)) {
  client <- AhriTreClient()
  probe <- tryCatch(study_list(client, format = 'json'), error = function(e) e)
  if (!inherits(probe, 'error')) {
    studies <- probe$object
    break
  }

  if (grepl('required pointer was null', conditionMessage(probe), fixed = TRUE) && attempt < 2L) {
    cat('[WARN] Client initialization returned a null pointer; retrying once.\n')
    try(close(client), silent = TRUE)
    next
  }

  stop(probe)
}
if (is.null(studies)) {
  cat('[INFO] Could not initialize a live client. Skipping.\n')
  quit(save = 'no', status = 0L)
}
on.exit(try(close(client), silent = TRUE), add = TRUE)

study_target <- Sys.getenv('AHRI_TRE_STUDY', 'IMPACT BP Training')
study_names <- character(0)
if (is.list(studies) && is.list(studies$studies)) {
  study_names <- vapply(studies$studies, function(e) {
    if (!is.null(e$study$name)) as.character(e$study$name[[1]]) else NA_character_
  }, character(1), USE.NAMES = FALSE)
} else if (is.data.frame(studies) && 'name' %in% names(studies)) {
  study_names <- as.character(studies$name)
}
study_names <- unique(study_names[!is.na(study_names) & nzchar(study_names)])
if (length(study_names) == 0L) {
  cat('[INFO] No studies available in the active session.\n')
  quit(save = 'no', status = 0L)
}

study_name <- if (study_target %in% study_names) study_target else study_names[[1]]
cat('[INFO] Using study: ', study_name, '\n', sep = '')

datasets_result <- tryCatch(
  dataset_list(client, study = study_name, include_versions = TRUE, format = 'json'),
  error = function(e) e
)
if (inherits(datasets_result, 'error') && grepl('required pointer was null', conditionMessage(datasets_result), fixed = TRUE)) {
  cat('[WARN] dataset_list hit a null pointer; recreating client and retrying once.\n')
  try(close(client), silent = TRUE)
  client <- AhriTreClient()
  datasets_result <- dataset_list(client, study = study_name, include_versions = TRUE, format = 'json')
}
if (inherits(datasets_result, 'error')) {
  stop(datasets_result)
}
datasets <- datasets_result$object
dataset_names <- character(0)
if (is.list(datasets) && is.list(datasets$datasets)) {
  dataset_names <- vapply(datasets$datasets, function(e) {
    if (!is.null(e$catalog$asset$name)) as.character(e$catalog$asset$name[[1]]) else NA_character_
  }, character(1), USE.NAMES = FALSE)
} else if (is.data.frame(datasets) && 'name' %in% names(datasets)) {
  dataset_names <- as.character(datasets$name)
}
dataset_names <- unique(dataset_names[!is.na(dataset_names) & nzchar(dataset_names)])
cat('[INFO] Dataset entries found: ', length(dataset_names), '\n', sep = '')
for (i in seq_len(min(10L, length(dataset_names)))) {
  cat('[INFO] Dataset ', i, ': ', dataset_names[[i]], '\n', sep = '')
}
