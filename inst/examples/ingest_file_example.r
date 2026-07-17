suppressPackageStartupMessages(library(ahriTRErRs))
if (file.exists('.env')) readRenviron('.env')

study_name <- Sys.getenv('AHRI_TRE_STUDY', '')
asset_name <- Sys.getenv('AHRI_TRE_ASSET', '')
file_path <- Sys.getenv('AHRI_TRE_FILE_PATH', '')
if (!nzchar(study_name) || !nzchar(asset_name) || !nzchar(file_path)) {
  cat('[INFO] Set AHRI_TRE_STUDY, AHRI_TRE_ASSET, and AHRI_TRE_FILE_PATH to run ingest. Skipping.\n')
  quit(save = 'no', status = 0L)
}
if (!file.exists(file_path)) {
  cat('[INFO] File not found: ', file_path, '. Skipping.\n', sep = '')
  quit(save = 'no', status = 0L)
}

client <- AhriTreClient()
on.exit(close(client), add = TRUE)
res <- ingest_datafile(client, study = study_name, asset = asset_name, path = file_path, format = 'json')
cat('[INFO] ingest_datafile status: ', res$status, '\n', sep = '')
print(res$data)
