suppressPackageStartupMessages(library(ahriTRErRs))
if (file.exists('.env')) readRenviron('.env')

study_name <- Sys.getenv('AHRI_TRE_STUDY', '')
domain_name <- Sys.getenv('AHRI_TRE_DOMAIN', '')
dataset_name <- Sys.getenv('AHRI_TRE_DATASET', '')
table_path <- Sys.getenv('AHRI_TRE_TABLE_PATH', '')
if (!nzchar(study_name) || !nzchar(domain_name) || !nzchar(dataset_name) || !nzchar(table_path)) {
  cat('[INFO] Set AHRI_TRE_STUDY, AHRI_TRE_DOMAIN, AHRI_TRE_DATASET, and AHRI_TRE_TABLE_PATH to run table ingest. Skipping.\n')
  quit(save = 'no', status = 0L)
}
if (!file.exists(table_path)) {
  cat('[INFO] Table path not found: ', table_path, '. Skipping.\n', sep = '')
  quit(save = 'no', status = 0L)
}

client <- AhriTreClient()
on.exit(close(client), add = TRUE)
res <- ingest_dataset_table(client, study = study_name, path = table_path, domain = domain_name, dataset = dataset_name, format = 'json')
cat('[INFO] ingest_dataset_table status: ', res$status, '\n', sep = '')
print(res$data)
