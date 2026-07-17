suppressPackageStartupMessages(library(ahriTRErRs))
if (file.exists('.env')) readRenviron('.env')

runtime_candidates <- unique(c(
  Sys.getenv('AHRI_TRE_RUNTIME_ROOT', '/opt/ahri-tre-runtime'),
  file.path(getwd(), '.runtime', 'ahri-tre-runtime'),
  '/workspaces/ahriTRErRs/.runtime/ahri-tre-runtime'
))
runtime_roots <- normalizePath(path.expand(runtime_candidates), mustWork = FALSE)
runtime_manifests <- file.path(runtime_roots, 'share', 'ahri-tre', 'manifest.json')
runtime_hits <- runtime_roots[file.exists(runtime_manifests)]
runtime_root <- if (length(runtime_hits) > 0L) runtime_hits[[1]] else runtime_roots[[1]]
manifest <- file.path(runtime_root, 'share', 'ahri-tre', 'manifest.json')
Sys.setenv(AHRI_TRE_RUNTIME_ROOT = runtime_root)
if (!file.exists(manifest)) {
  cat('[INFO] Runtime manifest not found. Skipping.\n')
  quit(save = 'no', status = 0L)
}

client <- AhriTreClient()
on.exit(close(client), add = TRUE)

study_target <- Sys.getenv('AHRI_TRE_STUDY', 'IMPACT BP Training')
studies <- study_list(client, format = 'json')$data
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

datasets <- dataset_list(client, study = study_name, include_versions = TRUE, format = 'json')$data
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
