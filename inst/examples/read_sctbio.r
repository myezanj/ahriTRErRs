suppressPackageStartupMessages(library(ahriTRErRs))

is_connectivity_failure <- function(message) {
  grepl(
    paste(
      c(
        "could not translate host name",
        "Temporary failure in name resolution",
        "Name or service not known",
        "Connection refused",
        "No route to host",
        "Network is unreachable",
        "timeout expired",
        "could not connect to server",
        "server is unreachable"
      ),
      collapse = "|"
    ),
    message,
    ignore.case = TRUE
  )
}

open_datastore_oauth_from_env <- function() {
  if (
    nzchar(Sys.getenv("JUPYTERHUB_USER", "")) &&
    !nzchar(Sys.getenv("AHRI_TRE_JUPYTERHUB_HOST", "")) &&
    nzchar(Sys.getenv("TRE_SERVER", ""))
  ) {
    Sys.setenv(AHRI_TRE_JUPYTERHUB_HOST = paste0("https://", Sys.getenv("TRE_SERVER")))
    cat("[INFO] Set AHRI_TRE_JUPYTERHUB_HOST from TRE_SERVER: ", Sys.getenv("AHRI_TRE_JUPYTERHUB_HOST"), "\n", sep = "")
  }

  oauth_session <- ahriTRErRs::cached_oauth_options_from_env()
  cat("[INFO] OAuth config: issuer=", oauth_session$issuer, ", client_id=", substr(oauth_session$client_id, 1, 8), "...\n", sep = "")
  cat("[INFO] Initializing DataStore with environment variables...\n")
  cat(
    "[INFO] Environment: TRE_SERVER=", Sys.getenv("TRE_SERVER"),
    ", TRE_TEST_DBNAME=", Sys.getenv("TRE_TEST_DBNAME"),
    ", ORCID_ISSUER=", Sys.getenv("ORCID_ISSUER"),
    "\n",
    sep = ""
  )
  datastore <- DataStore$new()
  cat("[INFO] Opening DataStore with OAuth...\n")
  opendatastore_oauth(
    datastore,
    oauth_config = list(session = oauth_session),
    migrate_catalog = TRUE
  )
}

runtime <- ahriTRErRs::runtime_platform()
if (identical(runtime, "local") && file.exists(".env")) {
  ahriTRErRs:::.load_dotenv_file(".env", overwrite = FALSE)
}

bootstrap <- tryCatch(
  list(runtime = runtime, datastore = open_datastore_oauth_from_env()),
  error = function(e) {
    message_text <- conditionMessage(e)
    if (is_connectivity_failure(message_text)) {
      cat("[WARN] Could not connect to the TRE datastore from this runtime.\n")
      cat("[WARN] TRE_SERVER=", Sys.getenv("TRE_SERVER", unset = ""), "\n", sep = "")
      cat("[WARN] TRE_TEST_DBNAME=", Sys.getenv("TRE_TEST_DBNAME", unset = ""), "\n", sep = "")
      cat("[WARN] Skipping example execution because the configured PostgreSQL host is unreachable.\n")
      cat("[WARN] Details: ", message_text, "\n", sep = "")
      return(NULL)
    }
    stop(e)
  }
)
if (is.null(bootstrap)) {
  invisible(FALSE)
} else {
  runtime <- bootstrap$runtime
  datastore <- bootstrap$datastore

  cat("[INFO] Runtime platform: ", runtime, "\n", sep = "")
  cat("Store connected: ", !is.null(datastore$store), "\n", sep = "")
  cat("Lake connected: ", !is.null(datastore$lake), "\n", sep = "")

  domains <- get_domains(datastore)
  cat("\n[INFO] Domains found: ", nrow(domains), "\n", sep = "")
  print(utils::head(domains, 5))

  domain <- get_domain(datastore, "Basic Science", return_mode = "objects")
  studies <- get_studies(datastore, domain = domain)

  requested_study_name <- "The Biology of Subclinical Asymptomic TB"
  study <- get_study(datastore, requested_study_name, domain = domain)
  if (is.null(study) || nrow(study) == 0) {
    stop("Study not found: ", requested_study_name)
  }

  datasets <- get_study_datasets(datastore, study)

  cat("\n[INFO] Using domain filter: ", as.character(domain$name[[1]]), "\n", sep = "")
  cat("\n[INFO] Studies found: ", nrow(studies), "\n", sep = "")
  print(utils::head(studies, 5))
  cat("\n[INFO] Selected study: ", as.character(study$name[[1]]), "\n", sep = "")
  cat("\n[INFO] Different datasets found for selected study: ", nrow(datasets), "\n", sep = "")

  vocabularies <- get_vocabularies(datastore, domain = domain)
  variables <- get_study_variables(datastore, study)
  cat("\n[INFO] Vocabulary entries found for selected study: ", nrow(vocabularies), "\n", sep = "")
  print(utils::head(vocabularies, 5))
  cat("\n[INFO] Variables found for selected study: ", nrow(variables), "\n", sep = "")
  print(utils::head(variables, 5))

  if (nrow(datasets) > 0) {
    datasets <- datasets[order(datasets$name), , drop = FALSE]
  }

  for (i in seq_len(nrow(datasets))) {
    dataset <- datasets[i, , drop = FALSE]
    dataset_name <- as.character(dataset$name[[1]])
    version_label <- as.character(dataset$version[[1]])
    cat("\n[INFO] Reading dataset ", i, "/", nrow(datasets), ": ", dataset_name, " (", version_label, ")\n", sep = "")

    rows <- try(
      read_dataset(datastore, dataset, limit = 10L, on_missing = "error"),
      silent = TRUE
    )
    if (inherits(rows, "try-error")) {
      cat("[WARN] Version ", version_label, " failed: ", as.character(rows), "\n", sep = "")
      next
    }

    cat("[INFO] Loaded version ", version_label, ": rows=", nrow(rows), ", cols=", ncol(rows), "\n", sep = "")
    if (ncol(rows) > 0) {
      print(rows[, seq_len(min(5, ncol(rows))), drop = FALSE])
    } else {
      print(rows)
    }
  }

  cat("\nClosing DataStore\n")
  closedatastore(datastore)
}
