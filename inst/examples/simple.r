library(ahriTRErRs)
#if (file.exists(".env")) {ahriTRErRs:::.load_dotenv_file(".env", overwrite = FALSE)}

cat("[INFO] Starting OAuth connection to DataStore...\n")
datastore <- opendatastore_oauth(
  server = Sys.getenv("PGHOST", unset = "localhost"),
  dbname = "pilot_tre",
  lake_data = "/mnt/test_lake/pilot_tre",
  lake_db = Sys.getenv("TRE_LAKE_DB", unset = "pilot_tre_catalog"),
  lake_user = Sys.getenv("LAKE_USER", unset = "ducklake_user"),
  lake_password = Sys.getenv("LAKE_PASSWORD", unset = ""),
  oauth_config = list(session = ahriTRErRs::cached_oauth_options_from_env()),
  migrate_catalog = TRUE
)

cat("Store connected: ", !is.null(datastore$store), "\n", sep = "")
cat("Lake connected: ", !is.null(datastore$lake), "\n", sep = "")

studies <- get_studies(datastore)
cat("[INFO] Studies found: ", nrow(studies), "\n", sep = "")
print(utils::head(studies, 5))

study <- get_study(datastore, "HDSS_example")
if (nrow(study) == 0 && nrow(studies) > 0) {
  study <- studies[1, , drop = FALSE]
}

datasets <- get_study_datasets(datastore, study)
cat("[INFO] Datasets found for selected study: ", nrow(datasets), "\n", sep = "")

if (nrow(datasets) > 0) {
  dataset <- datasets[1, , drop = FALSE]
  cat("[INFO] Reading dataset: ", as.character(dataset$name[[1]]), "\n", sep = "")
  rows <- read_dataset(datastore, dataset, limit = 10)
  print(rows)
}

if (!is.null(datastore)) {
  cat("\nClosing DataStore\n")
  closedatastore(datastore)
}
