#!/usr/bin/env Rscript
#
# Open an OAuth live session using a generated profile.
# This script calls write_oauth_profile.r to create a profile, then runs session open-oauth.
#
# Environment variables:
#   AHRI_TRE_OPEN_OAUTH_DRY_RUN  - If "true", only generate profile, do not open session.
#   AHRI_TRE_RUNTIME_ROOT         - Runtime root (auto-discovered)
#   All variables required by write_oauth_profile.r (TRE_SERVER, TRE_DBNAME, ORCID_*)

suppressPackageStartupMessages(library(ahriTRErRs))

if (file.exists(".env")) readRenviron(".env")

# Source the profile helper
profile_script <- file.path(getwd(), "inst", "examples", "write_oauth_profile.r")
if (!file.exists(profile_script)) {
  profile_script <- system.file("examples", "write_oauth_profile.r", package = "ahriTRErRs")
}
if (!file.exists(profile_script)) {
  stop("Could not locate write_oauth_profile.r", call. = FALSE)
}

profile_helper <- new.env(parent = globalenv())
sys.source(profile_script, envir = profile_helper)

`%||%` <- function(lhs, rhs) if (is.null(lhs)) rhs else lhs

truthy_env <- function(name, default = FALSE) {
  value <- tolower(trimws(Sys.getenv(name, unset = if (default) "true" else "false")))
  value %in% c("1", "true", "yes", "on")
}

abort_with_status <- function(message, status = 1L) {
  cat("[ERROR] ", message, "\n", sep = "")
  quit(save = "no", status = as.integer(status))
}

main <- function() {
  # Generate OAuth profile
  profile_info <- tryCatch(
    profile_helper$main(),
    error = function(e) {
      abort_with_status(paste("Failed to generate OAuth profile:", e$message))
    }
  )

  runtime_root <- Sys.getenv("AHRI_TRE_RUNTIME_ROOT", "/opt/ahri-tre-runtime")
  Sys.setenv(AHRI_TRE_RUNTIME_ROOT = runtime_root)

  cli_bin <- file.path(runtime_root, "bin", "ahri-tre")
  if (!file.exists(cli_bin)) {
    abort_with_status(paste("CLI binary not found at", cli_bin))
  }

  runtime_lib <- file.path(runtime_root, "lib")
  ld_path <- Sys.getenv("LD_LIBRARY_PATH", unset = "")
  cli_env <- c(paste0("LD_LIBRARY_PATH=", paste(unique(c(runtime_lib, ld_path[nzchar(ld_path)])), collapse = ":")))
  args <- c("session", "open-oauth", profile_info$datastore, "--profile", profile_info$profile_path)

  cat("[INFO] OAuth profile: ", profile_info$profile_path, "\n", sep = "")
  cat("[INFO] Command: ", cli_bin, " ", paste(shQuote(args, type = "sh"), collapse = " "), "\n", sep = "")

  if (truthy_env("AHRI_TRE_OPEN_OAUTH_DRY_RUN")) {
    cat("[INFO] Dry-run mode enabled via AHRI_TRE_OPEN_OAUTH_DRY_RUN.\n")
    return(invisible(profile_info))
  }

  open_out <- suppressWarnings(system2(cli_bin, args = args, stdout = "", stderr = "", env = cli_env))
  open_status <- as.integer(open_out %||% 0L)
  if (!identical(open_status, 0L)) {
    abort_with_status("session open-oauth did not complete successfully.", open_status)
  }

  # Verify session is active
  client <- AhriTreClient()
  on.exit(close(client), add = TRUE)
  status_result <- try(session_status(client, format = "json")$object, silent = TRUE)
  if (inherits(status_result, "try-error")) {
    abort_with_status(paste0("session status check failed after open-oauth: ", as.character(status_result)))
  }

  session_info <- status_result$session %||% list()
  active <- isTRUE(session_info$active)
  availability <- session_info$availability[[1]] %||% ""
  cat(
    sprintf("[INFO] Post-open session active=%s, availability=%s, reason=%s\n",
            as.character(session_info$active %||% NA),
            as.character(availability),
            session_info$unavailable_reason[[1]] %||% "")
  )
  if (!active || identical(availability, "missing")) {
    abort_with_status("post-open session is still not active.")
  }

  invisible(profile_info)
}

if (sys.nframe() == 0L) main()