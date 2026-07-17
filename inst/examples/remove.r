suppressPackageStartupMessages(library(ahriTRErRs))
if (file.exists('.env')) readRenviron('.env')

study_name <- Sys.getenv('AHRI_TRE_STUDY', '')
dataset_name <- Sys.getenv('AHRI_TRE_DATASET', '')
if (!nzchar(study_name) || !nzchar(dataset_name)) {
  cat('[INFO] Set AHRI_TRE_STUDY and AHRI_TRE_DATASET to preview dataset removal. Skipping.\n')
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
cat('[INFO] dataset_delete dry-run status: ', res$status, '\n', sep = '')
print(res$data)
