suppressPackageStartupMessages(library(ahriTRErRs))
if (file.exists('.env')) readRenviron('.env')

study_name <- Sys.getenv('AHRI_TRE_STUDY', 'Rfam_Database_Collection')
dataset_name <- Sys.getenv('AHRI_TRE_DATASET', '')
if (!nzchar(dataset_name)) {
  cat('[INFO] Set AHRI_TRE_DATASET to preview Rfam dataset removal. Skipping.\n')
  quit(save = 'no', status = 0L)
}

client <- AhriTreClient()
on.exit(close(client), add = TRUE)
res <- dataset_delete(
  client,
  study = study_name,
  dataset = dataset_name,
  dry_run = TRUE,
  yes = TRUE,
  format = 'json'
)
status_value <- if (!is.null(res$envelope$status) && nzchar(as.character(res$envelope$status[[1]]))) as.character(res$envelope$status[[1]]) else 'ok'
cat('[INFO] dataset_delete dry-run status: ', status_value, '\n', sep = '')
print(res$data)
