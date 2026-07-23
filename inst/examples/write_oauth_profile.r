#!/usr/bin/env Rscript
#
# Generate an OAuth profile file for use with session open-oauth.
#
# Environment variables:
#   TRE_SERVER            - Server URL
#   TRE_DBNAME            - Datastore name (also used as TRE_DATASTORE)
#   TRE_PORT              - Port (default: 5432)
#   ORCID_CACHE_FILE      - Path to ORCID token cache
#   ORCID_CLIENT_ID       - Optional
#   ORCID_CLIENT_SECRET   - Optional
#   ORCID_ISSUER          - Optional
#   ORCID_REDIRECT_URI    - Optional
#   ORCID_SCOPE           - Optional
#   TRE_LAKE_PATH         - Optional
#   TRE_LAKE_DB           - Optional
#   LAKE_USER             - Optional
#   LAKE_PASSWORD         - Optional
#   AHRI_TRE_OAUTH_PROFILE_OUT - Output path (default: .runtime/ahri-tre-open-oauth.env)

suppressPackageStartupMessages(library(ahriTRErRs))
if (file.exists(".env")) readRenviron(".env")

`%||%` <- function(lhs, rhs) if (is.null(lhs)) rhs else lhs

first_env <- function(names, default = "") {
  for (name in names) {
    value <- Sys.getenv(name, unset = "")
    if (nzchar(value)) return(value)
  }
  default
}

required_value <- function(names, label) {
  value <- trimws(first_env(names))
  if (!nzchar(value)) {
    stop("Missing required setting for ", label, ": set one of ", paste(names, collapse = ", "), call. = FALSE)
  }
  value
}

resolve_output_path <- function() {
  candidate <- trimws(first_env(
    c("AHRI_TRE_OAUTH_PROFILE_OUT"),
    default = file.path(getwd(), ".runtime", "ahri-tre-open-oauth.env")
  ))
  normalizePath(path.expand(candidate), mustWork = FALSE)
}

main <- function() {
  datastore <- required_value(c("TRE_DATASTORE", "TRE_TEST_DBNAME", "TRE_DBNAME"), "TRE datastore")
  server <- required_value(c("TRE_SERVER"), "TRE server")
  port <- trimws(first_env(c("TRE_PORT"), default = "5432"))
  cache_file <- required_value(c("ORCID_CACHE_FILE", "ORCID_TOKEN_CACHE_FILE"), "ORCID cache file")
  cache_file <- normalizePath(path.expand(cache_file), mustWork = FALSE)
  output_path <- resolve_output_path()

  dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
  dir.create(dirname(cache_file), recursive = TRUE, showWarnings = FALSE)

  profile_lines <- c(
    paste0("TRE_SERVER=", shQuote(server, type = "sh")),
    paste0("TRE_PORT=", shQuote(port, type = "sh")),
    paste0("TRE_DBNAME=", shQuote(datastore, type = "sh")),
    paste0("TRE_DATASTORE=", shQuote(datastore, type = "sh")),
    paste0("ORCID_CACHE_FILE=", shQuote(cache_file, type = "sh"))
  )

  optional_fields <- c(
    TRE_LAKE_PATH = first_env(c("TRE_LAKE_PATH", "TRE_TEST_LAKE_PATH")),
    TRE_LAKE_DB = first_env(c("TRE_LAKE_DB", "TRE_TEST_LAKE_DB")),
    LAKE_USER = first_env(c("LAKE_USER")),
    LAKE_PASSWORD = first_env(c("LAKE_PASSWORD")),
    ORCID_CLIENT_ID = first_env(c("ORCID_CLIENT_ID")),
    ORCID_CLIENT_SECRET = first_env(c("ORCID_CLIENT_SECRET")),
    ORCID_ISSUER = first_env(c("ORCID_ISSUER")),
    ORCID_REDIRECT_URI = first_env(c("ORCID_REDIRECT_URI")),
    ORCID_SCOPE = first_env(c("ORCID_SCOPE"))
  )
  optional_fields <- optional_fields[nzchar(optional_fields)]
  if (length(optional_fields)) {
    profile_lines <- c(profile_lines, paste0(names(optional_fields), "=", vapply(optional_fields, shQuote, character(1), type = "sh")))
  }

  writeLines(profile_lines, output_path, useBytes = TRUE)

  cat(sprintf("[INFO] OAuth profile written to: %s\n", output_path))
  cat("[INFO] Override output path with AHRI_TRE_OAUTH_PROFILE_OUT if needed.\n")
  cat(sprintf("[INFO] Datastore: %s\n", datastore))
  cat(sprintf("[INFO] ORCID cache file: %s\n", cache_file))
  cat(sprintf("[INFO] Next step: %s session open-oauth %s --profile %s\n",
              file.path(runtime_root, "bin", "ahri-tre"), datastore, shQuote(output_path, type = "sh")))
  invisible(list(profile_path = output_path, datastore = datastore, cache_file = cache_file))
}

if (sys.nframe() == 0L) main()