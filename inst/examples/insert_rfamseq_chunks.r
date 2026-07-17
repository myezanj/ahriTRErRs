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
replace_requested <- tolower(Sys.getenv("RFAMSEQ_REPLACE_EXISTING", "true")) %in% c("1", "true", "yes", "y")
if (!isTRUE(replace_requested)) {
  cat("[WARN] RFAMSEQ_REPLACE_EXISTING=false ignored for this script: forcing full chunk refresh.\n")
}
replace_datasets <- TRUE

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
  study <<- get_study(datastore, "Rfam Database Collection", domain = domain, return_mode = "objects")
  if (is.null(study)) {
    study <<- add_study(
      datastore,
      study = Study$new(
        name = "Rfam Database Collection",
        description = "Collection of RNA sequence families of structural RNAs #RNA #gene"
      ),
      domain = domain
    )
  }
  cat("[INFO] Reopened DataStore after connection loss.\n")
}

cat("[INFO] Runtime platform: ", runtime, "\n", sep = "")
cat("[INFO] Store connected: ", !is.null(datastore$store), "\n", sep = "")
cat("[INFO] Lake connected: ", !is.null(datastore$lake), "\n", sep = "")
cat("[INFO] Replace existing datasets: ", replace_datasets, "\n", sep = "")

domain <- get_domain(datastore, "Basic Science", return_mode = "objects")
study <- get_study(datastore, "Rfam Database Collection", domain = domain, return_mode = "objects")
if (is.null(study)) {
  study <- add_study(
    datastore,
    study = Study$new(
      name = "Rfam Database Collection",
      description = "Collection of RNA sequence families of structural RNAs #RNA #gene"
    ),
    domain = domain
  )
} else {
  cat("[INFO] Reusing existing study: Rfam Database Collection\n")
}

mysql_conn_args <- list(
  server = Sys.getenv("MYSQL_Host"),
  database = Sys.getenv("MYSQL_DB"),
  user = Sys.getenv("MYSQL_User"),
  password = Sys.getenv("MYSQL_Password"),
  driver = Sys.getenv("MYSQL_ODBC_DRIVER", "MariaDB Unicode"),
  port = as.integer(Sys.getenv("MYSQL_PORT"))
)
conn <- do.call(connect_mysql, mysql_conn_args)

configure_mysql_session_timeouts <- function(connection) {
  wait_timeout <- as.integer(Sys.getenv("RFAM_MYSQL_WAIT_TIMEOUT", "28800"))
  net_timeout <- as.integer(Sys.getenv("RFAM_MYSQL_NET_TIMEOUT", "600"))
  timeout_statements <- c(
    sprintf("SET SESSION wait_timeout = %d", wait_timeout),
    sprintf("SET SESSION interactive_timeout = %d", wait_timeout),
    sprintf("SET SESSION net_read_timeout = %d", net_timeout),
    sprintf("SET SESSION net_write_timeout = %d", net_timeout)
  )

  for (statement in timeout_statements) {
    DBI::dbExecute(connection, statement)
  }

  cat(
    "[INFO] MySQL session timeouts configured: wait_timeout=", wait_timeout,
    ", net_timeout=", net_timeout,
    "\n",
    sep = ""
  )
}

configure_mysql_session_timeouts(conn)
cat("[INFO] Connected to MySQL database: ", Sys.getenv("MYSQL_DB"), " at ", Sys.getenv("MYSQL_Host"), "\n", sep = "")

is_transient_disconnect <- function(err_msg) {
  grepl(
    paste(
      c(
        "Lost connection",
        "server has gone away",
        "communications link failure",
        "SSL error: unexpected eof while reading",
        "Unknown server host",
        "Temporary failure in name resolution",
        "Name or service not known",
        "getaddrinfo",
        "No route to host",
        "Connection timed out",
        "disconnected by the server because of inactivity",
        "wait_timeout",
        "interactive_timeout",
        "net_read_timeout",
        "net_write_timeout"
      ),
      collapse = "|"
    ),
    err_msg,
    ignore.case = TRUE
  )
}

is_datastore_disconnect <- function(err_msg) {
  grepl(
    "Lost connection to database|no OAuth flows are available|connection to server at .* failed|Failed to commit DuckLake transaction|DuckLake transaction|transaction conflict",
    err_msg,
    ignore.case = TRUE
  )
}

is_duplicate_asset_name_conflict <- function(err_msg) {
  grepl(
    "duplicate key value violates unique constraint \"i_assets_studyname\"|i_assets_studyname",
    err_msg,
    ignore.case = TRUE
  )
}

best_effort_delete_dataset_asset <- function(asset_name, context = "") {
  tryCatch(
    {
      delete_asset_by_name(
        ds = datastore,
        study = study,
        asset_name = asset_name,
        force = TRUE,
        delete_physical = TRUE,
        asset_type = "dataset"
      )
      if (nzchar(context)) {
        cat("[INFO] Removed existing dataset asset '", asset_name, "' (", context, ").\n", sep = "")
      } else {
        cat("[INFO] Removed existing dataset asset '", asset_name, "'.\n", sep = "")
      }
      TRUE
    },
    error = function(e) {
      FALSE
    }
  )
}

reconnect_source <- function() {
  max_retries <- max(1L, as.integer(Sys.getenv("RFAM_RECONNECT_MAX_RETRIES", "3")))
  for (attempt in seq_len(max_retries)) {
    result <- tryCatch({
      try(close_source_connection(conn), silent = TRUE)
      conn <<- do.call(connect_mysql, mysql_conn_args)
      configure_mysql_session_timeouts(conn)
      TRUE
    }, error = function(e) e)

    if (!inherits(result, "error")) {
      cat("[INFO] Reconnected to MySQL source database.\n")
      return(invisible(TRUE))
    }

    err_msg <- conditionMessage(result)
    if (!is_transient_disconnect(err_msg) || attempt >= max_retries) {
      stop(result)
    }

    cat("[WARN] Reconnect attempt ", attempt, "/", max_retries,
        " failed (", err_msg, "). Retrying...\n", sep = "")
  }

  invisible(FALSE)
}

ingest_with_retry <- function(dataset_name, sql, description, max_retries = 3L) {
  max_retries <- max(1L, as.integer(max_retries))
  source_attempt <- 1L
  datastore_attempt <- 1L
  duplicate_conflict_retry_used <- FALSE

  while (source_attempt <= max_retries && datastore_attempt <= max_retries) {
    result <- tryCatch({
      sql_to_dataset(
        ds = datastore,
        study = study,
        domain = domain,
        dataset_name = dataset_name,
        conn = conn,
        sql = sql,
        description = description,
        flavour = "MySQL",
        replace = replace_datasets
      )
    }, error = function(e) e)

    if (!inherits(result, "error")) {
      return(result)
    }

    err_msg <- conditionMessage(result)
    if (is_datastore_disconnect(err_msg) && datastore_attempt < max_retries) {
      cat("[WARN] DataStore connection dropped while ingesting ", dataset_name,
          " (attempt ", datastore_attempt, "/", max_retries,
          "). Reopening datastore and retrying...\n", sep = "")
      refresh_datastore_context()
      reconnect_source()
      datastore_attempt <- datastore_attempt + 1L
      next
    }

    if (is_transient_disconnect(err_msg) && source_attempt < max_retries) {
      cat("[WARN] Source connection dropped while ingesting ", dataset_name,
          " (attempt ", source_attempt, "/", max_retries,
          "). Reconnecting and retrying...\n", sep = "")
      reconnect_source()
      source_attempt <- source_attempt + 1L
      next
    }

    if (is_duplicate_asset_name_conflict(err_msg) && isTRUE(replace_datasets) && !duplicate_conflict_retry_used) {
      cat("[WARN] Duplicate dataset asset conflict for ", dataset_name,
          ". Deleting stale asset and retrying once...\n", sep = "")
      best_effort_delete_dataset_asset(dataset_name, "duplicate asset conflict")
      duplicate_conflict_retry_used <- TRUE
      next
    }

    if (is_datastore_disconnect(err_msg) && datastore_attempt >= max_retries) {
      cat("[ERROR] Exhausted datastore retries while ingesting ", dataset_name,
          ". Last error: ", err_msg, "\n", sep = "")
    } else if (is_transient_disconnect(err_msg) && source_attempt >= max_retries) {
      cat("[ERROR] Exhausted source retries while ingesting ", dataset_name,
          ". Last error: ", err_msg, "\n", sep = "")
    } else {
      cat("[ERROR] Exhausted retries while ingesting ", dataset_name,
          ". Last error: ", err_msg, "\n", sep = "")
    }

    if (!is_transient_disconnect(err_msg) && !is_datastore_disconnect(err_msg)) {
      stop(result)
    }

    stop(result)
  }

  stop("Exceeded retry loop bounds for dataset: ", dataset_name)
}

pick_existing_dataset_row <- function(existing_ds) {
  if (nrow(existing_ds) == 0) return(existing_ds)
  if ("is_latest" %in% names(existing_ds)) {
    latest_idx <- which(isTRUE(existing_ds$is_latest) | existing_ds$is_latest %in% c(TRUE, "TRUE", "t", "1"))
    if (length(latest_idx) > 0) return(existing_ds[latest_idx[[1]], , drop = FALSE])
  }
  existing_ds[1, , drop = FALSE]
}

lake_table_ref <- function(con, table_name) {
  parts <- strsplit(as.character(table_name), ".", fixed = TRUE)[[1]]
  if (length(parts) != 2) {
    stop("Invalid table reference: ", table_name)
  }
  paste0(
    DBI::dbQuoteIdentifier(con, parts[[1]]),
    ".",
    DBI::dbQuoteIdentifier(con, parts[[2]])
  )
}

consolidate_from_chunks <- function(consolidated_name, chunk_rows) {
  if (nrow(chunk_rows) == 0) {
    stop("No chunk datasets are available for consolidation.")
  }

  chunk_rows <- chunk_rows[order(chunk_rows$name), , drop = FALSE]
  source_refs <- vapply(
    as.character(chunk_rows$table_name),
    function(x) lake_table_ref(datastore$lake, x),
    FUN.VALUE = character(1)
  )

  cat("[INFO] Creating consolidated dataset from chunk datasets: ", consolidated_name, "\n", sep = "")
  consolidated <- sql_to_dataset(
    ds = datastore,
    study = study,
    domain = domain,
    dataset_name = consolidated_name,
    conn = datastore$lake,
    sql = paste0("SELECT * FROM ", source_refs[[1]], " WHERE 1=0"),
    description = "A consolidated rfamseq dataset materialized from chunk datasets after chunk ingestion. #RNA #gene #sequence",
    flavour = "DUCKDB",
    replace = replace_datasets
  )

  consolidated_row <- get_dataset(datastore, as.character(study$name), consolidated_name, include_versions = TRUE)
  consolidated_row <- pick_existing_dataset_row(consolidated_row)
  target_ref <- lake_table_ref(datastore$lake, as.character(consolidated_row$table_name[[1]]))

  select_blocks <- paste0("SELECT * FROM ", source_refs)
  insert_sql <- paste0(target_ref, " ", paste(select_blocks, collapse = " UNION ALL "))
  DBI::dbExecute(datastore$lake, paste0("INSERT INTO ", insert_sql))

  invisible(consolidated)
}

delete_existing_rfamseq_assets <- function() {
  existing_assets <- get_study_assets(datastore, study, include_versions = TRUE)
  target_rows <- existing_assets[
    existing_assets$asset_type == "dataset" &
      (grepl("^rfamseq_part_[0-9]{5}$", existing_assets$name) | existing_assets$name == "rfamseq"),
    ,
    drop = FALSE
  ]

  if (nrow(target_rows) == 0) {
    cat("[INFO] No existing rfamseq chunk or consolidated datasets found to delete before rebuild.\n")
    return(invisible(NULL))
  }

  target_names <- sort(unique(as.character(target_rows$name)))
  cat("[INFO] Deleting ", length(target_names),
      " existing rfamseq dataset(s) before creating fresh chunks.\n", sep = "")
  for (asset_name in target_names) {
    cat("[INFO] Deleting existing dataset: ", asset_name, "\n", sep = "")
    delete_asset_by_name(
      ds = datastore,
      study = study,
      asset_name = asset_name,
      force = TRUE,
      delete_physical = TRUE,
      asset_type = "dataset"
    )
  }
}

delete_existing_rfamseq_assets()

max_chunks <- max(1L, as.integer(Sys.getenv("RFAMSEQ_MAX_CHUNKS", "5")))
count_sql <- "select count(*) as n from Rfam.rfamseq"
count_result <- tryCatch(
  DBI::dbGetQuery(conn, count_sql),
  error = function(e) {
    if (is_transient_disconnect(conditionMessage(e))) {
      cat("[WARN] Source connection dropped while counting rfamseq rows. Reconnecting and retrying once...\n")
      reconnect_source()
      return(DBI::dbGetQuery(conn, count_sql))
    }
    stop(e)
  }
)

total_rows <- as.numeric(count_result$n[[1]])
if (!is.finite(total_rows) || total_rows <= 0) {
  cat("[INFO] rfamseq has no rows to ingest.\n")
} else {
  chunk_count <- min(max_chunks, as.integer(total_rows))
  chunk_size <- as.integer(ceiling(total_rows / chunk_count))
  cat("[INFO] Ingesting full rfamseq across ", chunk_count, " near-equal chunk(s) of up to ",
      chunk_size, " rows (total rows=", format(total_rows, scientific = FALSE), ")\n", sep = "")

  ingested_chunk_rows <- list()

  for (chunk_idx in seq_len(chunk_count)) {
    offset <- (chunk_idx - 1L) * chunk_size
    dataset_name <- sprintf("rfamseq_part_%05d", chunk_idx)
    sql <- sprintf("select * from Rfam.rfamseq limit %d offset %d", chunk_size, offset)
    description <- paste0(
      "A list of analysed sequences including INSDC accessions, taxonomy id, etc. #RNA #gene #sequence",
      " [rfamseq chunk ", chunk_idx, "/", chunk_count, "]"
    )

    existing_ds <- get_dataset(datastore, as.character(study$name), dataset_name, include_versions = TRUE)
    existing_ds <- pick_existing_dataset_row(existing_ds)

    if (nrow(existing_ds) >= 1) {
      if (!isTRUE(replace_datasets)) {
        cat("[INFO] Reusing existing dataset: ", dataset_name,
            " (version ", as.character(existing_ds$version[[1]]), ")\n", sep = "")
        ingested_chunk_rows[[length(ingested_chunk_rows) + 1L]] <- existing_ds
        next
      }
    }

    if (isTRUE(replace_datasets)) {
      best_effort_delete_dataset_asset(dataset_name, "pre-create replace guard")
    }

    cat("[INFO] Adding dataset for chunk: ", dataset_name,
        " (offset=", format(offset, scientific = FALSE), ")\n", sep = "")
    ingest_with_retry(
      dataset_name = dataset_name,
      sql = sql,
      description = description,
      max_retries = as.integer(Sys.getenv("RFAM_INGEST_MAX_RETRIES", "3"))
    )

    created_ds <- get_dataset(datastore, as.character(study$name), dataset_name, include_versions = TRUE)
    created_ds <- pick_existing_dataset_row(created_ds)
    if (nrow(created_ds) >= 1) {
      ingested_chunk_rows[[length(ingested_chunk_rows) + 1L]] <- created_ds
    }
  }

  consolidated_name <- "rfamseq"
  consolidated_ds <- get_dataset(datastore, as.character(study$name), consolidated_name, include_versions = TRUE)
  consolidated_ds <- pick_existing_dataset_row(consolidated_ds)

  if (nrow(consolidated_ds) >= 1) {
    if (!isTRUE(replace_datasets)) {
      cat("[INFO] Reusing consolidated dataset: ", consolidated_name,
          " (version ", as.character(consolidated_ds$version[[1]]), ")\n", sep = "")
    } else {
      consolidated_ds <- data.frame()
    }
  }

  if (nrow(consolidated_ds) == 0) {
    if (length(ingested_chunk_rows) == 0) {
      for (chunk_idx in seq_len(chunk_count)) {
        chunk_name <- sprintf("rfamseq_part_%05d", chunk_idx)
        existing_chunk <- get_dataset(datastore, as.character(study$name), chunk_name, include_versions = TRUE)
        existing_chunk <- pick_existing_dataset_row(existing_chunk)
        if (nrow(existing_chunk) >= 1) {
          ingested_chunk_rows[[length(ingested_chunk_rows) + 1L]] <- existing_chunk
        }
      }
    }

    chunk_rows <- if (length(ingested_chunk_rows) > 0) {
      do.call(rbind, ingested_chunk_rows)
    } else {
      data.frame()
    }

    consolidate_from_chunks(consolidated_name, chunk_rows)
  }

  chunk_assets <- get_study_assets(datastore, study, include_versions = TRUE)
  chunk_rows <- chunk_assets[
    chunk_assets$asset_type == "dataset" & grepl("^rfamseq_part_[0-9]{5}$", chunk_assets$name),
    ,
    drop = FALSE
  ]

  if (nrow(chunk_rows) == 0) {
    cat("[INFO] No chunk datasets found for cleanup.\n")
  } else {
    cat("[INFO] Deleting ", nrow(chunk_rows), " chunk dataset(s) after consolidation.\n", sep = "")
    for (i in seq_len(nrow(chunk_rows))) {
      chunk_name <- as.character(chunk_rows$name[[i]])
      cat("[INFO] Deleting chunk dataset: ", chunk_name, "\n", sep = "")
      delete_asset_by_name(
        ds = datastore,
        study = study,
        asset_name = chunk_name,
        force = TRUE,
        delete_physical = TRUE,
        asset_type = "dataset"
      )
    }
  }
}

cat("\nClosing source connection\n")
try(close_source_connection(conn), silent = TRUE)

cat("\nClosing DataStore\n")
try(closedatastore(datastore), silent = TRUE)

invisible(NULL)
