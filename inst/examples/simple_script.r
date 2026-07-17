suppressPackageStartupMessages(library(ahriTRErRs))
if (!("opendatastore_oauth" %in% getNamespaceExports("ahriTRErRs"))) {
  cat("[INFO] This legacy example uses datastore APIs not exported by the current ahriTRErRs build.\n")
  cat("[INFO] Skipping execution.\n")
  quit(save = "no", status = 0L)
}

library(ahriTRErRs)

if (file.exists(".env")) {
#  ahriTRErRs:::.load_dotenv_file(".env", overwrite = FALSE)
}

cat("[INFO] Starting OAuth connection to DataStore...\n")
datastore <- NULL

open_datastore_oauth <- function(skip_ducklake_attach = FALSE) {
  old_skip <- Sys.getenv("AHRI_TRE_SKIP_DUCKLAKE_ATTACH", unset = "")
  if (isTRUE(skip_ducklake_attach)) {
    Sys.setenv(AHRI_TRE_SKIP_DUCKLAKE_ATTACH = "true")
    on.exit({
      if (nzchar(old_skip)) {
        Sys.setenv(AHRI_TRE_SKIP_DUCKLAKE_ATTACH = old_skip)
      } else {
        Sys.unsetenv("AHRI_TRE_SKIP_DUCKLAKE_ATTACH")
      }
    }, add = TRUE)
  }

  lake_db <- Sys.getenv("TRE_LAKE_DB", unset = "pilot_tre_catalog")
  lake_user <- Sys.getenv("LAKE_USER", unset = "ducklake_user")
  lake_password <- Sys.getenv("LAKE_PASSWORD", unset = "")

  if (!isTRUE(skip_ducklake_attach) && !nzchar(lake_password)) {
    cat("[WARN] LAKE_PASSWORD is empty; DuckLake attach may fail for password-auth catalog connections.\n")
  }

  ahriTRErRs::opendatastore_oauth(
    server = Sys.getenv("PGHOST", unset = "localhost"),
    dbname = "pilot_tre",
    lake_data = "/mnt/test_lake/pilot_tre",
    lake_db = lake_db,
    lake_user = lake_user,
    lake_password = lake_password,
    oauth_config = list(session = ahriTRErRs::cached_oauth_options_from_env()),
    migrate_catalog = TRUE
  )
}

tryCatch({
  datastore <- tryCatch(
    open_datastore_oauth(skip_ducklake_attach = FALSE),
    error = function(e) {
      msg <- conditionMessage(e)
      ducklake_auth_error <- grepl(
        "DuckLake MetaData|none of the server's SASL authentication mechanisms are supported",
        msg,
        ignore.case = TRUE
      )

      if (!isTRUE(ducklake_auth_error)) {
        stop(e)
      }

      cat(
        "[WARN] DuckLake attach failed due to PostgreSQL auth mechanism mismatch in DuckDB runtime. ",
        "Retrying in metadata-only mode (AHRI_TRE_SKIP_DUCKLAKE_ATTACH=true).\n",
        sep = ""
      )
      open_datastore_oauth(skip_ducklake_attach = TRUE)
    }
  )

  cat("Store connected: ", !is.null(datastore$store), "\n", sep = "")
  cat("Lake connected: ", !is.null(datastore$lake), "\n", sep = "")

  cat("[SUCCESS] DataStore opened successfully.\n")
  studies <- get_studies(datastore)
  cat("[INFO] Available studies:\n")
  print(studies)

  if (is.null(datastore$lake)) {
    cat("[WARN] DuckLake attach is unavailable in this runtime; skipping lake-dependent walkthrough steps.\n")
  } else {
    ahriTRErRs::run_example_study_walkthrough(
      datastore = datastore,
      study_name = "HDSS_example",
      row_limit = 10
    )
  }
}, finally = {
  if (!is.null(datastore)) {
    cat("\nClosing DataStore\n")
    try(closedatastore(datastore), silent = TRUE)
  }
})
