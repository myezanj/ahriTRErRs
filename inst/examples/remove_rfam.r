find_repo_root <- function(start = getwd()) {
  current <- normalizePath(start, winslash = "/", mustWork = TRUE)
  repeat {
    if (file.exists(file.path(current, "DESCRIPTION")) && dir.exists(file.path(current, "inst", "examples"))) {
      return(current)
    }
    parent <- dirname(current)
    if (identical(parent, current)) {
      return(NULL)
    }
    current <- parent
  }
}

ensure_ahriTRErRs_available <- function() {
  if (
    "package:ahriTRErRs" %in% search() ||
      "ahriTRErRs" %in% loadedNamespaces() ||
      requireNamespace("ahriTRErRs", quietly = TRUE)
  ) {
    suppressPackageStartupMessages(library("ahriTRErRs", character.only = TRUE))
    return(invisible(TRUE))
  }

  repo_root <- find_repo_root()
  if (is.null(repo_root)) {
    stop("Could not locate the ahriTRErRs repository root for load_all().")
  }

  if (requireNamespace("pkgload", quietly = TRUE)) {
    pkgload::load_all(repo_root, export_all = FALSE, quiet = TRUE)
  } else if (requireNamespace("devtools", quietly = TRUE)) {
    devtools::load_all(repo_root, quiet = TRUE)
  } else {
    stop("Package 'ahriTRErRs' is not installed and neither pkgload nor devtools is available.")
  }

  suppressPackageStartupMessages(library("ahriTRErRs", character.only = TRUE))
  invisible(TRUE)
}

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

bootstrap_example_session <- function() {
  ensure_ahriTRErRs_available()

  runtime <- ahriTRErRs::runtime_platform()
  if (identical(runtime, "local") && file.exists(".env")) {
    ahriTRErRs:::.load_dotenv_file(".env", overwrite = FALSE)
  }

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

  datastore <- tryCatch(
    {
      cat("[INFO] Opening DataStore with OAuth...\n")
      opendatastore_oauth(
        DataStore$new(),
        oauth_config = list(session = oauth_session),
        migrate_catalog = TRUE
      )
    },
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

  if (is.null(datastore)) {
    return(NULL)
  }

  list(runtime = runtime, datastore = datastore)
}

ensure_ahriTRErRs_available()

bootstrap <- bootstrap_example_session()
if (is.null(bootstrap)) {
  invisible(FALSE)
  quit(save = "no", status = 0L)
}

runtime <- bootstrap$runtime
datastore <- bootstrap$datastore

cat("[INFO] Runtime platform: ", runtime, "\n", sep = "")
cat("[INFO] Store connected: ", !is.null(datastore$store), "\n", sep = "")
cat("[INFO] Lake connected: ", !is.null(datastore$lake), "\n", sep = "")

target_domain_name <- "Basic Science"
target_study_name <- "Rfam Database Collection"
rfam_table_names <- c("family", "rfamseq", "full_region", "clan", "clan_membership", "taxonomy")

domain <- get_domain(datastore, target_domain_name, return_mode = "objects")
if (is.null(domain)) {
  cat("[INFO] Domain not found: ", target_domain_name, ". Nothing to clean.\n", sep = "")
  cat("\nClosing DataStore\n")
  try(closedatastore(datastore), silent = TRUE)
  quit(save = "no", status = 0L)
}

cat("\n[INFO] Preparing cleanup for study: ", target_study_name, "\n", sep = "")
study <- get_study(datastore, target_study_name, domain = domain, return_mode = "objects")

candidate_variable_names <- character(0)
candidate_vocabulary_names <- character(0)
candidate_entity_names <- rfam_table_names

if (!is.null(study)) {
  cat("[INFO] Study found (study_id=", study$study_id, "). Gathering linked metadata via package accessors...\n", sep = "")

  study_assets <- get_study_assets(datastore, study, include_versions = TRUE)
  study_dataset_assets <- study_assets[study_assets$asset_type == "dataset", , drop = FALSE]
  if (nrow(study_dataset_assets) > 0) {
    dataset_names <- unique(as.character(study_dataset_assets$name))
    candidate_entity_names <- unique(c(candidate_entity_names, dataset_names))

    domain_variables <- get_domain_variables(datastore, domain)
    domain_vocabularies <- get_vocabularies(datastore, domain)

    for (dataset_name in dataset_names) {
      dataset_rows <- get_dataset(datastore, target_study_name, dataset_name, include_versions = TRUE)
      if (nrow(dataset_rows) == 0) {
        next
      }

      for (row_idx in seq_len(nrow(dataset_rows))) {
        variable_rows <- get_dataset_variables(datastore, dataset_rows[row_idx, , drop = FALSE])
        if (nrow(variable_rows) == 0) {
          next
        }

        if ("name" %in% names(variable_rows)) {
          candidate_variable_names <- unique(c(
            candidate_variable_names,
            stats::na.omit(as.character(variable_rows$name))
          ))
        }

        if ("vocabulary_id" %in% names(variable_rows) && nrow(domain_vocabularies) > 0) {
          vocab_ids <- unique(stats::na.omit(as.character(variable_rows$vocabulary_id)))
          if (length(vocab_ids) > 0) {
            matches <- domain_vocabularies[as.character(domain_vocabularies$vocabulary_id) %in% vocab_ids, , drop = FALSE]
            if (nrow(matches) > 0) {
              candidate_vocabulary_names <- unique(c(
                candidate_vocabulary_names,
                stats::na.omit(as.character(matches$name))
              ))
            }
          }
        }

        if ("name" %in% names(variable_rows) && nrow(domain_variables) > 0) {
          matches <- domain_variables[domain_variables$name %in% as.character(variable_rows$name), , drop = FALSE]
          if (nrow(matches) > 0 && "vocabulary_id" %in% names(matches) && nrow(domain_vocabularies) > 0) {
            vocab_ids <- unique(stats::na.omit(as.character(matches$vocabulary_id)))
            if (length(vocab_ids) > 0) {
              vocab_matches <- domain_vocabularies[as.character(domain_vocabularies$vocabulary_id) %in% vocab_ids, , drop = FALSE]
              if (nrow(vocab_matches) > 0) {
                candidate_vocabulary_names <- unique(c(
                  candidate_vocabulary_names,
                  stats::na.omit(as.character(vocab_matches$name))
                ))
              }
            }
          }
        }
      }
    }
  }

  cat("[INFO] Deleting study with cascade (assets, datasets, versions, datafiles, transformations)...\n")
  delete_study(
    datastore,
    study = study,
    force = TRUE,
    cascade = TRUE,
    archive = FALSE
  )
  cat("[INFO] Study deleted: ", target_study_name, "\n", sep = "")
} else {
  cat("[INFO] Study not found; continuing with residual metadata cleanup for known RFAM objects.\n")
}

candidate_entity_names <- unique(stats::na.omit(candidate_entity_names))
entity_deleted <- 0L
for (entity_name in candidate_entity_names) {
  entity_obj <- tryCatch(
    get_entity(datastore, domain$domain_id, entity_name),
    error = function(e) NULL
  )
  if (!is.null(entity_obj)) {
    delete_entity(datastore, entity_obj, force = TRUE)
    entity_deleted <- entity_deleted + 1L
    cat("[INFO] Deleted entity (and dependent relations/instances): ", entity_name, "\n", sep = "")
  }
}

variable_deleted <- 0L
for (variable_name in unique(stats::na.omit(candidate_variable_names))) {
  variable_obj <- tryCatch(
    get_variable(datastore, domain$domain_id, variable_name),
    error = function(e) NULL
  )
  if (is.null(variable_obj)) {
    next
  }

  deleted <- tryCatch({
    delete_variable(datastore, variable_obj, force = FALSE)
    TRUE
  }, error = function(e) {
    cat("[INFO] Skipping variable still in use: ", variable_name, "\n", sep = "")
    FALSE
  })

  if (isTRUE(deleted)) {
    variable_deleted <- variable_deleted + 1L
    cat("[INFO] Deleted orphan variable: ", variable_name, "\n", sep = "")
  }
}

vocabulary_deleted <- 0L
for (vocabulary_name in unique(stats::na.omit(candidate_vocabulary_names))) {
  if (!nzchar(vocabulary_name)) {
    next
  }
  domain_vocabularies <- get_vocabularies(datastore, domain)
  vocab_match <- domain_vocabularies[domain_vocabularies$name == vocabulary_name, , drop = FALSE]
  if (nrow(vocab_match) == 0) {
    next
  }
  vocab_obj <- tryCatch(
    get_vocabulary(datastore, vocab_match$vocabulary_id[[1]]),
    error = function(e) NULL
  )
  if (is.null(vocab_obj)) {
    next
  }

  deleted <- tryCatch({
    delete_vocabulary(datastore, vocab_obj, force = FALSE)
    TRUE
  }, error = function(e) {
    cat("[INFO] Skipping vocabulary/codebook still referenced: ", vocabulary_name, "\n", sep = "")
    FALSE
  })

  if (isTRUE(deleted)) {
    vocabulary_deleted <- vocabulary_deleted + 1L
    cat("[INFO] Deleted orphan vocabulary/codebook: ", vocabulary_name, "\n", sep = "")
  }
}

cat("\n[INFO] Cleanup summary\n")
cat("[INFO] Entities deleted: ", entity_deleted, "\n", sep = "")
cat("[INFO] Orphan variables deleted: ", variable_deleted, "\n", sep = "")
cat("[INFO] Orphan vocabularies deleted: ", vocabulary_deleted, "\n", sep = "")

cat("\nClosing DataStore\n")
try(closedatastore(datastore), silent = TRUE)

invisible(NULL)
