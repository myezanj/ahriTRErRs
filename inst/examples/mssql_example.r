suppressPackageStartupMessages(library(ahriTRErRs))
if (!("opendatastore_oauth" %in% getNamespaceExports("ahriTRErRs"))) {
  cat("[INFO] This legacy example uses datastore APIs not exported by the current ahriTRErRs build.\n")
  cat("[INFO] Skipping execution.\n")
  quit(save = "no", status = 0L)
}

bootstrap_helper_candidates <- c(file.path("inst", "examples", "bootstrap_helpers.r"), "bootstrap_helpers.r")
bootstrap_helper_path <- bootstrap_helper_candidates[file.exists(bootstrap_helper_candidates)][1]
if (is.na(bootstrap_helper_path) || !nzchar(bootstrap_helper_path)) {
  stop("Could not locate inst/examples/bootstrap_helpers.r")
}
source(bootstrap_helper_path, local = TRUE)
ensure_ahriTRErRs_available()

library(DBI)
library(odbc)

runtime <- ahriTRErRs::runtime_platform()

start_time <- Sys.time()
old_warn <- getOption("warn")
options(warn = 1)
cat("Execution started at:", format(start_time, "%Y-%m-%d %H:%M:%S %Z"), "\n")

datastore <- NULL
conn <- NULL
on.exit({
  if (!is.null(datastore)) {
    cat("\nClosing DataStore\n")
    try(closedatastore(datastore), silent = TRUE)
  }
  if (!is.null(conn)) {
    cat("Closing MSSQL connection\n")
    try(DBI::dbDisconnect(conn), silent = TRUE)
  }
  options(warn = old_warn)
}, add = TRUE)

if (identical(runtime, "local") && file.exists(".env")) {
  readRenviron(".env")
  bootstrap <- bootstrap_example_session()
  if (is.null(bootstrap)) {
    quit(save = "no", status = 0L)
  }
  oauth_session <- ahriTRErRs::cached_oauth_options_from_env()
  client_preview <- if (nzchar(oauth_session$client_id)) {
    paste0(substr(oauth_session$client_id, 1, 8), "...")
  } else {
    "<unset>"
  }
  cat("[INFO] OAuth config: issuer=", oauth_session$issuer, ", client_id=", client_preview, "\n", sep = "")
  datastore <- bootstrap$datastore
} else {
  cat("[INFO] No .env file loaded; relying on runtime environment variables\n")
  bootstrap <- bootstrap_example_session()
  if (is.null(bootstrap)) {
    quit(save = "no", status = 0L)
  }
  datastore <- bootstrap$datastore
}

mssql_requirements <- check_mssql_requirements()
cat("[INFO] MSSQL drivers detected:", paste(mssql_requirements$available_drivers, collapse = ", "), "\n")
if (!mssql_requirements$ok) {
  cat("[INFO] No default MSSQL driver resolved. Set MSSQL_DRIVER if you need to override the detected driver.\n")
  cat("[INFO]", mssql_driver_install_instructions(), "\n")
}

mssql_driver <- trimws(Sys.getenv("MSSQL_DRIVER", Sys.getenv("MSQLServerDriver", unset = "")))
if (!nzchar(mssql_driver)) {
  mssql_driver <- NULL
}

mssql_authentication <- trimws(Sys.getenv("MSSQL_AUTHENTICATION", unset = ""))
if (!nzchar(mssql_authentication)) {
  mssql_authentication <- NULL
}

mssql_trusted_connection <- trimws(Sys.getenv("MSSQL_TRUSTED_CONNECTION", unset = ""))
if (!nzchar(mssql_trusted_connection)) {
  mssql_trusted_connection <- NULL
}

conn <- connect_mssql(
  server = Sys.getenv("MSQLServer"),
  database = Sys.getenv("MSQLServerDB"),
  user = Sys.getenv("MSQLServerUser"),
  password = Sys.getenv("MSQLServerPW"),
  driver = mssql_driver,
  authentication = mssql_authentication,
  trusted_connection = mssql_trusted_connection
)

bootstrap <- ahriTRErRs:::example_ensure_domain_study(
  datastore,
  "Clinical",
  "IMPACT BP Training",
  domain_description = "Clinical data domain for the MSSQL example",
  study_description = "IMPACT BP Training import from MSSQL",
  study_external_id = "IMPACT BP Training"
)
domain <- bootstrap$domain
study <- bootstrap$study

cat("Domain:", domain$name, "with ID", domain$domain_id, "\n")
cat("Study:", study$name, "with ID", study$study_id, "\n")

sql <- "SELECT distinct SurveillanceType
      ,ComponentType
      ,CollectionMode
      ,InstrumentName
      ,Disabled
      ,AHRI_Acronym
      ,Acronym
      ,InstrumentYear
  FROM AHRI_STG.ops.rptQuestionnaires;"

dataset_name <- "rptQuestionnaires"
description <- "rptQuestionnaires Dataset imported from MS-SQL Server"

dataset <- sql_to_dataset(
  ds = datastore,
  study = study,
  domain = domain,
  dataset_name = dataset_name,
  conn = conn,
  sql = sql,
  description = description,
  flavour = "MSSQL",
  replace = TRUE
)

df <- read_dataset(datastore, dataset)
cat(paste(
  "Dataset read back as data.frame with",
  nrow(df), "rows and", ncol(df), "columns."
), "\n")

transformations <- list_study_transformations(datastore, study)
cat("List of transformations for study", study$name, ":\n")
print(transformations)

assets <- list_study_assets_df(datastore, study)
cat("List of assets for study", study$name, ":\n")
print(assets)
