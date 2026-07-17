suppressPackageStartupMessages(library(ahriTRErRs))
if (file.exists('.env')) readRenviron('.env')

study_name <- Sys.getenv('AHRI_TRE_STUDY', '')
domain_name <- Sys.getenv('AHRI_TRE_DOMAIN', '')
dataset_name <- Sys.getenv('AHRI_TRE_DATASET', '')
sql_text <- Sys.getenv('AHRI_TRE_SQL', '')
if (!nzchar(study_name) || !nzchar(domain_name) || !nzchar(dataset_name) || !nzchar(sql_text)) {
  cat('[INFO] Set AHRI_TRE_STUDY, AHRI_TRE_DOMAIN, AHRI_TRE_DATASET, AHRI_TRE_SQL to run SQL ingest. Skipping.\n')
  quit(save = 'no', status = 0L)
}

client <- AhriTreClient()
on.exit(close(client), add = TRUE)
res <- ingest_dataset_sql(
  client,
  study = study_name,
  domain = domain_name,
  dataset = dataset_name,
  sql = sql_text,
  flavour = 'mssql',
  format = 'json'
)
status_value <- if (!is.null(res$envelope$status) && nzchar(as.character(res$envelope$status[[1]]))) as.character(res$envelope$status[[1]]) else 'ok'
cat('[INFO] ingest_dataset_sql status: ', status_value, '\n', sep = '')
print(res$data)
