#!/usr/bin/env Rscript
# Ingest RFAM tables from a MySQL database using ahriTRErRs.
# Requires a live session and MySQL connection details in .env.

suppressPackageStartupMessages(library(ahriTRErRs))
suppressPackageStartupMessages(library(DBI))
suppressPackageStartupMessages(library(odbc))

# ----- Helper functions (self-contained) -----

resolve_runtime_root <- function() {
  candidates <- unique(c(
    Sys.getenv("AHRI_TRE_RUNTIME_ROOT", ""),
    file.path(getwd(), ".runtime", "ahri-tre-runtime"),
    "/opt/ahri-tre-runtime"
  ))
  candidates <- candidates[nzchar(candidates)]
  roots <- normalizePath(path.expand(candidates), mustWork = FALSE)
  manifests <- file.path(roots, "share", "ahri-tre", "manifest.json")
  hits <- roots[file.exists(manifests)]
  if (length(hits) > 0L) hits[[1]] else roots[[1]]
}

setup_runtime <- function() {
  root <- resolve_runtime_root()
  if (!file.exists(file.path(root, "share", "ahri-tre", "manifest.json"))) {
    stop("AHRI TRE runtime not found. Set AHRI_TRE_RUNTIME_ROOT or install runtime.")
  }
  Sys.setenv(AHRI_TRE_RUNTIME_ROOT = root)
  cat("[INFO] Using runtime root:", root, "\n")
  invisible(root)
}

create_client <- function(max_attempts = 2L) {
  for (attempt in seq_len(max_attempts)) {
    client <- tryCatch(AhriTreClient(), error = function(e) e)
    if (!inherits(client, "error")) {
      return(client)
    }
    if (attempt < max_attempts) {
      cat("[WARN] Client creation failed, retrying...\n")
      Sys.sleep(1)
    } else {
      stop("Failed to create client after ", max_attempts, " attempts: ", conditionMessage(client))
    }
  }
}

has_live_session <- function(client) {
  status <- try(session_status(client, format = "json")$object, silent = TRUE)
  if (inherits(status, "try-error") || is.null(status$session)) return(FALSE)
  isTRUE(status$session$active) && identical(status$session$availability %||% "", "live")
}

ensure_session <- function(client, fail = TRUE) {
  if (has_live_session(client)) return(TRUE)
  cat("[WARN] No live session is active.\n")
  cat("Run 'Rscript inst/examples/open_oauth_session.r' to open one.\n")
  if (isTRUE(fail)) stop("Live session required.")
  FALSE
}

# ----- Main script -----

setup_runtime()
client <- create_client()
on.exit(close(client), add = TRUE)

if (!ensure_session(client, fail = TRUE)) quit(save = "no", status = 1)

# MySQL connection details
mysql_server <- Sys.getenv("MYSQL_Host", "")
mysql_db <- Sys.getenv("MYSQL_DB", "")
mysql_user <- Sys.getenv("MYSQL_User", "")
mysql_password <- Sys.getenv("MYSQL_Password", "")
if (!nzchar(mysql_server) || !nzchar(mysql_db) || !nzchar(mysql_user) || !nzchar(mysql_password)) {
  stop("Set MYSQL_Host, MYSQL_DB, MYSQL_User, MYSQL_Password in .env.")
}

conn <- dbConnect(
  odbc::odbc(),
  Driver = Sys.getenv("MYSQL_ODBC_DRIVER", "MariaDB Unicode"),
  Server = mysql_server,
  Database = mysql_db,
  UID = mysql_user,
  PWD = mysql_password,
  Port = as.integer(Sys.getenv("MYSQL_PORT", 3306))
)
on.exit(try(dbDisconnect(conn), silent = TRUE), add = TRUE)

# Define tables
rfam_tables <- c(
  family = "A list of all Rfam families and family-specific information",
  full_region = "A list of all sequences annotated with Rfam families",
  clan = "Description of all Rfam clans",
  clan_membership = "A list of all Rfam families per clan",
  taxonomy = "NCBI taxonomy identifiers",
  rfamseq = "A list of all analysed sequences"
)

domain_name <- "Basic_Science"
study_name <- "Rfam_Database_Collection"

# Ensure study exists (if not, create it)
study_info <- try(study_get(client, name = study_name, format = "json"), silent = TRUE)
if (inherits(study_info, "try-error") || is.null(study_info$object$study)) {
  cat("[INFO] Creating study:", study_name, "\n")
  study_add(client, name = study_name, domain = domain_name, format = "json")
}

# Ingest each table
for (table_name in names(rfam_tables)) {
  cat("\n[INFO] Ingesting table:", table_name, "\n")
  sql <- paste0("SELECT * FROM Rfam.", table_name)
  result <- try_tre(
    ingest_dataset_sql(
      client,
      study = study_name,
      domain = domain_name,
      dataset = table_name,
      sql = sql,
      flavour = "MySQL",
      format = "json"
    ),
    context = paste("Ingest", table_name)
  )
  if (!is.null(result$envelope$ok) && isTRUE(result$envelope$ok)) {
    cat("[SUCCESS] Table", table_name, "ingested.\n")
  } else {
    cat("[ERROR] Failed to ingest", table_name, "\n")
  }
}

cat("\n[INFO] Done.\n")