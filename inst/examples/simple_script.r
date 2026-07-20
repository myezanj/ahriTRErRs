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

sessions <- session_list(client)
cat('[INFO] session_list status: ', sessions$status, '\n', sep = '')
print(sessions$data)

studies <- study_list(client, format = 'json')$data
if (is.data.frame(studies)) {
  cat('[INFO] Studies found: ', nrow(studies), '\n', sep = '')
  print(utils::head(studies, 5L))
} else {
  print(studies)
}
