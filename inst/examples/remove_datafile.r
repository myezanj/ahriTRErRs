suppressPackageStartupMessages(library(ahriTRErRs))
if (file.exists('.env')) readRenviron('.env')

study_name <- Sys.getenv('AHRI_TRE_STUDY', '')
asset_name <- Sys.getenv('AHRI_TRE_ASSET', '')
asset_version <- Sys.getenv('AHRI_TRE_VERSION', '')
if (!nzchar(study_name) || !nzchar(asset_name)) {
  cat('[INFO] Set AHRI_TRE_STUDY and AHRI_TRE_ASSET to preview datafile removal. Skipping.\n')
  quit(save = 'no', status = 0L)
}

client <- AhriTreClient()
on.exit(close(client), add = TRUE)
res <- datafile_delete(
  client,
  study = study_name,
  asset = asset_name,
  version = if (nzchar(asset_version)) asset_version else NULL,
  dry_run = TRUE,
  yes = TRUE,
  format = 'json'
)
status_value <- if (!is.null(res$envelope$status) && nzchar(as.character(res$envelope$status[[1]]))) as.character(res$envelope$status[[1]]) else 'ok'
cat('[INFO] datafile_delete dry-run status: ', status_value, '\n', sep = '')
print(res$data)
