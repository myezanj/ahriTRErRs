suppressPackageStartupMessages(library(ahriTRErRs))
if (!("opendatastore_oauth" %in% getNamespaceExports("ahriTRErRs"))) {
  cat("[INFO] This legacy example uses datastore APIs not exported by the current ahriTRErRs build.\n")
  cat("[INFO] Skipping execution.\n")
  quit(save = "no", status = 0L)
}

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

example_oauth_session_from_env <- function() {
  list(
    issuer = Sys.getenv("ORCID_ISSUER", "https://orcid.org"),
    client_id = Sys.getenv("ORCID_CLIENT_ID", Sys.getenv("INSTITUTION_ORCID_CLIENT_ID", "")),
    client_secret = Sys.getenv("ORCID_CLIENT_SECRET", Sys.getenv("INSTITUTION_ORCID_CLIENT_SECRET", "")),
    redirect_uri = Sys.getenv("ORCID_REDIRECT_URI", "http://127.0.0.1:8890/callback"),
    scope = Sys.getenv("ORCID_SCOPE", "openid"),
    cache_file = Sys.getenv("ORCID_TOKEN_CACHE_FILE", Sys.getenv("ORCID_CACHE_FILE", "")),
    force_reauth = tolower(Sys.getenv("ORCID_FORCE_REAUTH", "false")) %in% c("1", "true", "yes", "on"),
    persist_cache = !tolower(Sys.getenv("ORCID_MEMORY_ONLY_CACHE", "false")) %in% c("1", "true", "yes", "on"),
    gui = FALSE,
    callback_port = suppressWarnings(as.integer(Sys.getenv("ORCID_CALLBACK_PORT", "8890"))),
    timeout_seconds = suppressWarnings(as.integer(Sys.getenv("ORCID_TIMEOUT_SECONDS", "600")))
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

  oauth_session <- example_oauth_session_from_env()
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

bootstrap <- bootstrap_example_session()
if (is.null(bootstrap)) {
  invisible(FALSE)
  quit(save = "no", status = 0L)
}

runtime <- bootstrap$runtime
datastore <- bootstrap$datastore
force_reingest <- tolower(Sys.getenv("RFAM_FORCE_REINGEST", "false")) %in% c("1", "true", "yes", "y")

cat("[INFO] Runtime platform: ", runtime, "\n", sep = "")
cat("Store connected: ", !is.null(datastore$store), "\n", sep = "")
cat("Lake connected: ", !is.null(datastore$lake), "\n", sep = "")
cat("[INFO] RFAM_FORCE_REINGEST: ", force_reingest, "\n", sep = "")

domains <- get_domains(datastore)
cat("\n[INFO] Domains found: ", nrow(domains), "\n", sep = "")
print(utils::head(domains, 5))

domain <- get_domain(datastore, "Basic Science", return_mode = "objects")

cat("\n[INFO] Studies found: ", nrow(get_studies(datastore, domain = domain)), "\n", sep = "")
study_name <- "Rfam Database Collection"
study <- get_study(datastore, study_name, domain = domain, return_mode = "objects")

if (is.null(study)) {
  cat("\n[INFO] Adding Study...\n")
  study <- add_study(
    datastore,
    study = Study$new(
      name = study_name,
      description = "Collection of RNA sequence families of structural RNAs #RNA #gene"
    ),
    domain = domain
  )
} else {
  cat("\n[INFO] Reusing existing study: ", study_name, "\n", sep = "")
}

cat("\n[INFO] Study added: ", as.character(study$name[[1]]), "\n", sep = "")
cat("\n[INFO] Connecting to MySQL database...\n")
mysql_conn_args <- list(
  server = Sys.getenv("MYSQL_Host"),
  database = Sys.getenv("MYSQL_DB"),
  user = Sys.getenv("MYSQL_User"),
  password = Sys.getenv("MYSQL_Password"),
  driver = Sys.getenv("MYSQL_ODBC_DRIVER", "MariaDB Unicode"),
  port = as.integer(Sys.getenv("MYSQL_PORT"))
)
conn <- do.call(connect_mysql, mysql_conn_args)
cat("[INFO] Connected to MySQL database: ", Sys.getenv("MYSQL_DB"), " at ", Sys.getenv("MYSQL_Host"), "\n", sep = "")

open_datastore <- function() {
  opendatastore_oauth(
    DataStore$new(),
    oauth_config = list(session = example_oauth_session_from_env()),
    migrate_catalog = TRUE
  )
}

refresh_datastore_context <- function() {
  try(closedatastore(datastore), silent = TRUE)
  datastore <<- open_datastore()
  domain <<- get_domain(datastore, "Basic Science", return_mode = "objects")
  study <<- get_study(datastore, study_name, domain = domain, return_mode = "objects")
  if (is.null(study)) {
    study <<- add_study(
      datastore,
      study = Study$new(
        name = study_name,
        description = "Collection of RNA sequence families of structural RNAs #RNA #gene"
      ),
      domain = domain
    )
  }
  cat("[INFO] Reopened DataStore after connection loss.\n")
}

reconnect_source <- function() {
  try(close_source_connection(conn), silent = TRUE)
  conn <<- do.call(connect_mysql, mysql_conn_args)
  cat("[INFO] Reconnected to MySQL source database.\n")
}

is_source_disconnect <- function(err_msg) {
  grepl(
    "Lost connection|server has gone away|communications link failure|external pointer is not valid",
    err_msg,
    ignore.case = TRUE
  )
}

is_datastore_disconnect <- function(err_msg) {
  grepl(
    "Lost connection to database|no OAuth flows are available|connection to server at .* failed|external pointer is not valid|DuckLake transaction|Failed to commit DuckLake transaction",
    err_msg,
    ignore.case = TRUE
  )
}

build_source_sql <- function(table_name) {
  paste0("select * from Rfam.", table_name)
}

pick_existing_dataset_row <- function(existing_ds) {
  if (nrow(existing_ds) == 0) {
    return(existing_ds)
  }
  if ("is_latest" %in% names(existing_ds)) {
    latest_idx <- which(isTRUE(existing_ds$is_latest) | existing_ds$is_latest %in% c(TRUE, "TRUE", "t", "1"))
    if (length(latest_idx) > 0) {
      return(existing_ds[latest_idx[[1]], , drop = FALSE])
    }
  }
  existing_ds[1, , drop = FALSE]
}

ingest_dataset_with_retry <- function(dataset_name, sql, description,
                                      flavour = "MySQL", replace = TRUE, max_retries = 3L) {
  attempt <- 1L
  while (attempt <= max_retries) {
    result <- tryCatch({
      sql_to_dataset(
        ds = datastore,
        study = study,
        domain = domain,
        dataset_name = dataset_name,
        conn = conn,
        sql = sql,
        description = description,
        flavour = flavour,
        replace = replace
      )
    }, error = function(e) e)

    if (!inherits(result, "error")) {
      return(result)
    }

    err_msg <- conditionMessage(result)
    if (is_datastore_disconnect(err_msg) && attempt < max_retries) {
      cat("[WARN] DataStore connection dropped while ingesting ", dataset_name,
          " (attempt ", attempt, "/", max_retries,
          "). Reopening datastore and retrying...\n", sep = "")
      refresh_datastore_context()
      reconnect_source()
      attempt <- attempt + 1L
      next
    }

    if (is_source_disconnect(err_msg) && attempt < max_retries) {
      cat("[WARN] Source connection dropped while ingesting ", dataset_name,
          " (attempt ", attempt, "/", max_retries,
          "). Reconnecting and retrying...\n", sep = "")
      reconnect_source()
      attempt <- attempt + 1L
      next
    }

    if (attempt >= max_retries) {
      cat("[ERROR] Exhausted retries while ingesting ", dataset_name,
          ". Last error: ", err_msg, "\n", sep = "")
    }

    if (!is_source_disconnect(err_msg) && !is_datastore_disconnect(err_msg)) {
      stop(result)
    }

    stop(result)
  }
  stop("Unexpected retry loop exit for dataset: ", dataset_name)
}

rfam_tables <- data.frame(
  table = c(
    "family",
    "full_region",
    "clan",
    "clan_membership",
    "taxonomy",
    "rfamseq"
  ),
  description = c(
    "A list of all Rfam families and family-specific information (family accession, family name, description, etc.) #RNA #gene #sequence",
    "A list of all sequences annotated with Rfam families including INSDC accessions, start and end coordinates, bit scores, etc. #RNA #gene #sequence",
    "Description of all Rfam clans #RNA #gene #sequence",
    "A list of all Rfam families per clan #RNA #gene #sequence",
    "NCBI taxonomy identifiers #RNA #gene #sequence",
    "A list of all analysed sequences including INSDC accessions, taxonomy id, etc. #RNA #gene #sequence"
  ),
  stringsAsFactors = FALSE
)

rfam_datasets <- list()
for (i in seq_len(nrow(rfam_tables))) {
  table_name <- rfam_tables$table[[i]]
  table_description <- rfam_tables$description[[i]]
  table_sql <- build_source_sql(table_name)
  existing_ds <- get_dataset(datastore, as.character(study$name), table_name, include_versions = TRUE)
  existing_ds <- pick_existing_dataset_row(existing_ds)

  if (nrow(existing_ds) >= 1) {
    if (!isTRUE(force_reingest)) {
      cat("\n[INFO] Reusing existing dataset for table: ", table_name,
          " (version ", as.character(existing_ds$version[[1]]), ")\n", sep = "")
      rfam_datasets[[table_name]] <- existing_ds
      next
    }

    cat("\n[INFO] RFAM_FORCE_REINGEST enabled. Re-ingesting existing dataset for table: ",
        table_name, " (version ", as.character(existing_ds$version[[1]]), ")\n", sep = "")
    rfam_datasets[[table_name]] <- ingest_dataset_with_retry(
      dataset_name = table_name,
      sql = table_sql,
      description = table_description,
      flavour = "MySQL",
      replace = TRUE,
      max_retries = as.integer(Sys.getenv("RFAM_INGEST_MAX_RETRIES", "3"))
    )
    cat("[INFO] Dataset re-ingested for ", table_name, ": ", as.character(rfam_datasets[[table_name]]$name[[1]]), "\n", sep = "")
  } else {
    cat("\n[INFO] Adding dataset for table: ", table_name, "\n", sep = "")
    rfam_datasets[[table_name]] <- ingest_dataset_with_retry(
      dataset_name = table_name,
      sql = table_sql,
      description = table_description,
      flavour = "MySQL",
      replace = TRUE,
      max_retries = as.integer(Sys.getenv("RFAM_INGEST_MAX_RETRIES", "3"))
    )
    cat("[INFO] Dataset added for ", table_name, ": ", as.character(rfam_datasets[[table_name]]$name[[1]]), "\n", sep = "")
  }
}

cat("\n[INFO] Creating entities from table metadata...\n")
rfam_entities <- list()
for (i in seq_len(nrow(rfam_tables))) {
  table_name <- rfam_tables$table[[i]]
  table_description <- rfam_tables$description[[i]]
  entity_obj <- upsert_entity(
    datastore,
    Entity$new(
      name = table_name,
      domain = domain,
      description = table_description
    )
  )
  rfam_entities[[table_name]] <- entity_obj
  cat("[INFO] Entity upserted: ", table_name, " (entity_id=", entity_obj$entity_id, ")\n", sep = "")
}

cat("\n[INFO] Reading foreign-key metadata from source database...\n")
fk_sql <- "
SELECT
  TABLE_NAME AS table_name,
  COLUMN_NAME AS column_name,
  REFERENCED_TABLE_NAME AS referenced_table_name,
  REFERENCED_COLUMN_NAME AS referenced_column_name,
  CONSTRAINT_NAME AS constraint_name,
  ORDINAL_POSITION AS ordinal_position
FROM information_schema.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = DATABASE()
  AND REFERENCED_TABLE_NAME IS NOT NULL
ORDER BY TABLE_NAME, CONSTRAINT_NAME, ORDINAL_POSITION"
fk_rows <- tryCatch(
  DBI::dbGetQuery(conn, fk_sql),
  error = function(e) {
    if (grepl("Lost connection|server has gone away|communications link failure", conditionMessage(e), ignore.case = TRUE)) {
      cat("[WARN] Source connection dropped while reading FK metadata. Reconnecting and retrying once...\n")
      reconnect_source()
      return(DBI::dbGetQuery(conn, fk_sql))
    }
    stop(e)
  }
)

if (nrow(fk_rows) == 0) {
  cat("[INFO] No foreign keys found in source metadata.\n")
} else {
  table_set <- rfam_tables$table
  fk_rows <- fk_rows[
    fk_rows$table_name %in% table_set & fk_rows$referenced_table_name %in% table_set,
    , drop = FALSE
  ]

  if (nrow(fk_rows) == 0) {
    cat("[INFO] No foreign keys connecting the selected Rfam tables were found.\n")
  } else {
    fk_key <- paste(fk_rows$table_name, fk_rows$constraint_name, sep = "::")
    fk_groups <- split(fk_rows, fk_key)

    relation_count <- 0L
    for (grp in fk_groups) {
      
      child_table <- as.character(grp$table_name[[1]])
      parent_table <- as.character(grp$referenced_table_name[[1]])
      constraint_name <- as.character(grp$constraint_name[[1]])
      child_columns <- paste(as.character(grp$column_name), collapse = ",")
      parent_columns <- paste(as.character(grp$referenced_column_name), collapse = ",")
      relation_name <- paste0(child_table, "_to_", parent_table)
      
      relation_description <- paste0(
        "Inferred from source FK ", constraint_name,
        ": ", child_table, "(", child_columns, ") -> ",
        parent_table, "(", parent_columns, ")."
      )

      upsert_entityrelation(
        datastore,
        EntityRelation$new(
          name = relation_name,
          subject_entity = rfam_entities[[child_table]],
          object_entity = rfam_entities[[parent_table]],
          domain = domain,
          description = relation_description
        )
      )
      relation_count <- relation_count + 1L
      cat("[INFO] Entity relation upserted: ", relation_name, "\n", sep = "")
    }
    cat("[INFO] Total entity relations upserted from FK metadata: ", relation_count, "\n", sep = "")
  }
}

cat("\nClosing source connection\n")
try(close_source_connection(conn), silent = TRUE)

cat("\nClosing DataStore\n")
try(closedatastore(datastore), silent = TRUE)

invisible(NULL)
