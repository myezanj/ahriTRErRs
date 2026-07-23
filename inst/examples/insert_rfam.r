#!/usr/bin/env Rscript
# Ingest RFAM tables from a MySQL database using ahriTRErRs.
# Requires a live session and MySQL connection details in .env.

suppressPackageStartupMessages(library(ahriTRErRs))
suppressPackageStartupMessages(library(DBI))
suppressPackageStartupMessages(library(odbc))

# ----- Main script -----

client <- AhriTreClient()
on.exit(close(client), add = TRUE)

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