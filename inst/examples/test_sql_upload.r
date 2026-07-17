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

if (file.exists(".env")) {
    readRenviron(".env")
}

cat("=== Diagnostics start ===\n")
cat("timestamp:", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z"), "\n")
cat("R version:", as.character(getRversion()), "\n")

env_keys <- c(
    "TRE_SERVER",
    "TRE_TEST_DBNAME",
    "TRE_DBNAME",
    "TRE_TEST_LAKE_PATH",
    "TRE_TEST_LAKE_DB",
    "LAKE_USER",
    "LAKE_PASSWORD",
    "ORCID_CLIENT_ID",
    "ORCID_CLIENT_SECRET",
    "MSQLServerDSN",
    "MSQLServer",
    "MSQLServerDB",
    "MSQLServerUser",
    "MSQLServerPW"
)

cat("--- ENV checks ---\n")
for (key in env_keys) {
    value <- trimws(Sys.getenv(key, ""))
    cat(key, "=", if (nzchar(value)) "<set>" else "<missing-or-empty>", "\n")
}

mssql_dsn <- trimws(Sys.getenv("MSQLServerDSN", ""))
mssql_server <- trimws(Sys.getenv("MSQLServer", ""))
mssql_db <- trimws(Sys.getenv("MSQLServerDB", ""))
mssql_user <- trimws(Sys.getenv("MSQLServerUser", ""))
mssql_password <- trimws(Sys.getenv("MSQLServerPW", ""))

mssql_driver <- trimws(Sys.getenv("MSSQL_DRIVER", "ODBC Driver 18 for SQL Server"))
mssql_encrypt <- trimws(Sys.getenv("MSSQL_ENCRYPT", "yes"))
mssql_trust_server_cert <- trimws(Sys.getenv("MSSQL_TRUST_SERVER_CERTIFICATE", "yes"))
mssql_port <- suppressWarnings(as.integer(trimws(Sys.getenv("MSQLServerPort", Sys.getenv("MSSQL_PORT", "")))))

datastore <- NULL
conn <- NULL

tryCatch({
    cat("--- Connect TRE datastore (OAuth) ---\n")
    oauth_session <- list(
        issuer = trimws(Sys.getenv("ORCID_ISSUER", "https://orcid.org")),
        client_id = trimws(Sys.getenv("ORCID_CLIENT_ID", Sys.getenv("INSTITUTION_ORCID_CLIENT_ID", ""))),
        client_secret = trimws(Sys.getenv("ORCID_CLIENT_SECRET", Sys.getenv("INSTITUTION_ORCID_CLIENT_SECRET", ""))),
        redirect_uri = trimws(Sys.getenv("ORCID_REDIRECT_URI", "http://127.0.0.1:8890/callback")),
        scope = trimws(Sys.getenv("ORCID_SCOPE", "openid")),
        cache_file = trimws(Sys.getenv("ORCID_TOKEN_CACHE_FILE", "")),
        force_reauth = tolower(trimws(Sys.getenv("ORCID_FORCE_REAUTH", "false"))) %in% c("1", "true", "yes", "on"),
        gui = FALSE
    )
    datastore <- tryCatch(
        suppressWarnings(opendatastore_oauth(
            oauth_config = list(session = oauth_session),
            lake_db = trimws(Sys.getenv("TRE_TEST_LAKE_DB", "ducklake_catalog")),
            lake_user = trimws(Sys.getenv("LAKE_USER", "ducklake_user")),
            lake_password = Sys.getenv("LAKE_PASSWORD", "")
        )),
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
        cat("=== Diagnostics complete (skipped) ===\n")
        quit(save = "no", status = 0L)
    }
    cat("datastore server:", datastore$server, "\n")
    cat("datastore dbname:", datastore$dbname, "\n")
    cat("TRE store connection type:", paste(class(datastore$store), collapse = ","), "\n")
    cat("TRE lake connection type:", paste(class(datastore$lake), collapse = ","), "\n")

    cat("--- Connect MSSQL ---\n")
    if (nzchar(mssql_dsn)) {
        dsn_args <- list(drv = odbc::odbc(), dsn = mssql_dsn, timeout = 30)
        if (nzchar(mssql_user)) dsn_args$uid <- mssql_user
        if (nzchar(mssql_password)) dsn_args$pwd <- mssql_password
        conn <- do.call(DBI::dbConnect, dsn_args)
    } else {
        if (!nzchar(mssql_server) || !nzchar(mssql_db) || !nzchar(mssql_user) || !nzchar(mssql_password)) {
            stop(
                "MSSQL connection details are missing in .env. Set MSQLServerDSN or MSQLServer, MSQLServerDB, MSQLServerUser, MSQLServerPW."
            )
        }
        conn_args <- list(
            drv = odbc::odbc(),
            Driver = mssql_driver,
            Server = mssql_server,
            Database = mssql_db,
            UID = mssql_user,
            PWD = mssql_password,
            Encrypt = mssql_encrypt,
            TrustServerCertificate = mssql_trust_server_cert,
            timeout = 30
        )
        if (!is.na(mssql_port) && mssql_port > 0) {
            conn_args$Port <- mssql_port
        }
        conn <- do.call(DBI::dbConnect, conn_args)
    }

    cat("MSSQL conn is NULL:", is.null(conn), "\n")
    if (is.null(conn) || !DBI::dbIsValid(conn)) {
        stop("MSSQL connection is not valid")
    }
    cat("MSSQL conn type:", paste(class(conn), collapse = ","), "\n")

    cat("--- Domain and Study lookup ---\n")
    domain <- get_domain(datastore, "HDSS")
    study <- get_study(datastore, "HDSS IHS", domain = domain)

    cat("domain found:", !is.null(domain), "\n")
    cat("study rows:", nrow(study), "\n")
    if (is.null(domain) || nrow(study) == 0) {
        stop("Required domain/study not found")
    }
    study <- study[1, , drop = FALSE]

    sql <- "SELECT * FROM dbo.DeathEvents"
    cat("--- SQL ---\n")
    cat(sql, "\n")

    cat("--- Metadata probe via dm_exec_describe_first_result_set ---\n")
    meta_sql <- paste(
        "SELECT name, system_type_name, source_table, source_schema",
        "FROM sys.dm_exec_describe_first_result_set(?, NULL, 1)",
        "WHERE is_hidden = 0",
        "ORDER BY column_ordinal"
    )
    meta_df <- DBI::dbGetQuery(conn, meta_sql, params = list(sql))
    cat("metadata rows:", nrow(meta_df), "\n")
    if (nrow(meta_df) > 0) {
        print(meta_df)
    }

    cat("--- Run sql_to_dataset ---\n")
    dataset <- sql_to_dataset(
        ds = datastore,
        study = study,
        domain = domain,
        dataset_name = "Deaths",
        conn = conn,
        sql = sql,
        description = "Example dataset imported from DeathEvents table in MSSQL server",
        flavour = "MSSQL",
        replace = TRUE
    )

    cat("dataset name:", dataset$version$asset$name, "\n")
    cat("dataset version id:", dataset$version$version_id, "\n")

    cat("--- Read dataset back ---\n")
    df <- read_dataset(datastore, dataset)
    cat("rows:", nrow(df), "cols:", ncol(df), "\n")
}, error = function(err) {
    cat("=== Diagnostics failure ===\n")
    cat(conditionMessage(err), "\n")
    stop(err)
}, finally = {
    cat("--- Cleanup ---\n")
    if (!is.null(conn)) {
        try(DBI::dbDisconnect(conn), silent = TRUE)
        cat("MSSQL connection closed\n")
    }
    if (!is.null(datastore)) {
        try(closedatastore(datastore), silent = TRUE)
        cat("TRE datastore closed\n")
    }
    cat("=== Diagnostics end ===\n")
})

 
 