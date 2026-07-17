suppressPackageStartupMessages(library(ahriTRErRs))
if (file.exists('.env')) readRenviron('.env')

study_name <- Sys.getenv('AHRI_TRE_STUDY', '')
domain_name <- Sys.getenv('AHRI_TRE_DOMAIN', '')
if (!nzchar(study_name) || !nzchar(domain_name)) {
  cat('[INFO] Set AHRI_TRE_STUDY and AHRI_TRE_DOMAIN to run REDCap project ingest. Skipping.\n')
  quit(save = 'no', status = 0L)
}

client <- AhriTreClient()
on.exit(close(client), add = TRUE)
res <- ingest_redcap_project(client, study = study_name, domain = domain_name, format = 'json')
status_value <- if (!is.null(res$envelope$status) && nzchar(as.character(res$envelope$status[[1]]))) as.character(res$envelope$status[[1]]) else 'ok'
cat('[INFO] ingest_redcap_project status: ', status_value, '\n', sep = '')
print(res$data)
