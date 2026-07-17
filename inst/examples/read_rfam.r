suppressPackageStartupMessages(library(ahritre))
if (file.exists(".env")) readRenviron(".env")
profile_env <- "/workspaces/ahriTREr_rs/.runtime/ahri-tre-runtime/share/ahri-tre/profile.env"
if (file.exists(profile_env) && file.access(profile_env, 4) == 0) { readRenviron(profile_env); cat("[INFO] Loaded runtime profile env: ", profile_env, "\n", sep = "") }
req <- c("TRE_SERVER"); miss <- req[!nzchar(Sys.getenv(req, unset = ""))]
if (length(miss) > 0) stop("Missing required vars: ", paste(miss, collapse = ", "), call. = FALSE)
cat("[INFO] Runtime profile env verification passed.\n")
server <- Sys.getenv("TRE_SERVER", unset = ""); lake_db <- Sys.getenv("TRE_LAKE_DB", unset = Sys.getenv("TRE_TEST_LAKE_DB", unset = "")); lake_data <- Sys.getenv("TRE_LAKE_PATH", unset = Sys.getenv("TRE_TEST_LAKE_PATH", unset = ""))
if (nzchar(lake_db)) Sys.setenv(TRE_LAKE_DB = lake_db); if (nzchar(lake_data)) Sys.setenv(TRE_LAKE_PATH = lake_data)
roots <- unique(c(Sys.getenv("AHRI_TRE_RUNTIME_ROOT", unset = "/opt/ahri-tre-runtime"), file.path(getwd(), ".runtime", "ahri-tre-runtime"), "/workspaces/ahriTREr_rs/.runtime/ahri-tre-runtime"))
probes <- normalizePath(path.expand(roots), mustWork = FALSE); hits <- probes[file.exists(file.path(probes, "share", "ahri-tre", "manifest.json"))]
runtime_root <- if (length(hits) > 0) hits[[1]] else probes[[1]]; manifest <- file.path(runtime_root, "share", "ahri-tre", "manifest.json")
if (!file.exists(manifest)) {
  cat("[WARN] Runtime preflight failed: manifest not found at ", manifest, "\n", sep = "")
  cat("[INFO] To install runtime: bash .devcontainer/install_ahri_tre_runtime.sh\n")
  cat("[WARN] Skipping script execution.\n")
  invisible(FALSE)
} else {
  Sys.setenv(AHRI_TRE_RUNTIME_ROOT = runtime_root)
  session_name <- "pilot_tre"; cli_bin <- file.path(runtime_root, "bin", "ahri-tre")
  cli_env <- paste0("LD_LIBRARY_PATH=", file.path(runtime_root, "lib"), ":", Sys.getenv("LD_LIBRARY_PATH", unset = ""))
  run_cli <- function(args, env = cli_env) suppressWarnings(system2(cli_bin, args, stdout = TRUE, stderr = TRUE, env = env))
  stop_before_study <- FALSE
  cat("[INFO] Using ahritre package wrappers.\n[INFO] AHRI_TRE_RUNTIME_ROOT=", runtime_root, "\n[INFO] OAuth flag: --profile <profile>\n", sep = "")
  cat("[INFO] Resolved datastore config: server=", server, ", datastore=", session_name, ", lake_db=", lake_db, ", lake_data=", lake_data, "\n", sep = "")
  if (file.exists(cli_bin)) {
    cat("[INFO] Session list snapshot:\n", paste(run_cli(c("session", "list", "--format", "json")), collapse = "\n"), "\n", sep = "")
    if (nzchar(session_name)) run_cli(c("session", "use", session_name, "--format", "json"))
    token_cache <- path.expand(Sys.getenv("ORCID_CACHE_FILE", unset = Sys.getenv("ORCID_TOKEN_CACHE_FILE", unset = "")))
    if (nzchar(session_name) && nzchar(token_cache) && file.exists(token_cache)) {
      open_profile_env <- tempfile("tre-open-profile-", fileext = ".env")
      open_base <- c(paste0("TRE_SERVER=", server), paste0("TRE_PORT=", Sys.getenv("TRE_PORT", unset = "5432")), paste0("TRE_DBNAME=", session_name), paste0("TRE_DATASTORE=", session_name))
      extra <- c(TRE_LAKE_PATH = lake_data, TRE_LAKE_DB = lake_db, LAKE_USER = Sys.getenv("LAKE_USER", unset = ""), LAKE_PASSWORD = Sys.getenv("LAKE_PASSWORD", unset = ""))
      writeLines(c(open_base, paste0(names(extra[nzchar(extra)]), "=", extra[nzchar(extra)])), open_profile_env)
      open_out <- run_cli(c("session", "open-stored-oauth", session_name, token_cache, "--env-file", open_profile_env, "--format", "json"))
      open_text <- paste(open_out, collapse = "\n")
      cat("[INFO] Session open-stored-oauth attempt:\n", open_text, "\n", sep = "")
      if (grepl("missing identity table public\\.datastore_identity", open_text, ignore.case = TRUE)) {
        super_user <- Sys.getenv("SUPER_USER", unset = ""); super_password <- Sys.getenv("SUPER_PASSWORD", unset = "")
        if (!nzchar(super_user) || !nzchar(super_password)) cat("[WARN] SUPER_USER/SUPER_PASSWORD not set; schema migration cannot run automatically.\n")
        if (nzchar(super_user) && nzchar(super_password)) {
          lake_user <- Sys.getenv("LAKE_USER", unset = "")
          if (nzchar(lake_user) && identical(super_user, lake_user)) {
            cat("[WARN] SUPER_USER currently matches LAKE_USER; datastore schema migration usually requires a PostgreSQL superuser account.\n[INFO] Set SUPER_USER/SUPER_PASSWORD to a PostgreSQL superuser and rerun this script.\n")
            stop_before_study <- TRUE
          } else {
            status_env <- c(cli_env, paste0("SUPER_PASSWORD=", super_password))
            status_out <- run_cli(c("datastore", "schema-status", "--datastore", session_name, "--super-user", super_user, "--super-password-env", "SUPER_PASSWORD", "--env-file", open_profile_env, "--format", "json"), status_env)
            migrate_out <- run_cli(c("datastore", "schema-migrate", "--datastore", session_name, "--super-user", super_user, "--super-password-env", "SUPER_PASSWORD", "--env-file", open_profile_env, "--format", "json"), status_env)
            cat("[INFO] Schema status attempt:\n", paste(status_out, collapse = "\n"), "\n[INFO] Schema migrate attempt:\n", paste(migrate_out, collapse = "\n"), "\n", sep = "")
            if (grepl("authentication error|missing identity table public\\.datastore_identity", paste(c(status_out, migrate_out), collapse = "\n"), ignore.case = TRUE)) {
              cat("[WARN] Schema migration did not complete successfully; stopping before study_list.\n[INFO] Use PostgreSQL superuser credentials in SUPER_USER/SUPER_PASSWORD and rerun this script.\n")
              stop_before_study <- TRUE
            }
          }
        } else {
          cat("[INFO] Missing SUPER_USER/SUPER_PASSWORD for automatic schema migration.\n[INFO] Run: ahri-tre datastore schema-status --datastore ", session_name, " --super-user \"$SUPER_USER\" --super-password-env SUPER_PASSWORD --env-file .env --format json\n[INFO] Run: ahri-tre datastore schema-migrate --datastore ", session_name, " --super-user \"$SUPER_USER\" --super-password-env SUPER_PASSWORD --env-file .env --format json\n", sep = "")
          stop_before_study <- TRUE
        }
      }
      unlink(open_profile_env, force = TRUE)
    }
  }
  if (isTRUE(stop_before_study)) { cat("[WARN] Skipping study_list until session/datastore remediation is completed.\n"); invisible(FALSE) } else {
    target_study <- "Rfam Database Collection"
    client <- AhriTreClient(); on.exit(close(client), add = TRUE)
    studies <- study_list(client, format = "json")$data
    if (is.character(studies) && length(studies) == 1L && nzchar(studies)) studies <- jsonlite::fromJSON(studies, simplifyDataFrame = TRUE)
    if (!is.data.frame(studies)) studies <- as.data.frame(studies)
    cat("\n[INFO] Studies found: ", nrow(studies), "\n", sep = "")
    study_col <- c("name", "study", "study_name"); study_col <- study_col[study_col %in% names(studies)][1]
    if (is.na(study_col) || !any(as.character(studies[[study_col]]) == target_study)) stop("Study not found: ", target_study)
    cat("\n[INFO] Selected study: ", target_study, "\n", sep = "")
    datasets <- dataset_list(client, study = target_study, include_versions = TRUE, format = "json")$data
    if (is.character(datasets) && length(datasets) == 1L && nzchar(datasets)) datasets <- jsonlite::fromJSON(datasets, simplifyDataFrame = TRUE)
    if (!is.data.frame(datasets)) datasets <- as.data.frame(datasets)
    cat("[INFO] Dataset entries found for selected study: ", nrow(datasets), "\n", sep = "")
    dataset_col <- c("name", "dataset", "dataset_name"); dataset_col <- dataset_col[dataset_col %in% names(datasets)][1]
    dataset_names <- if (is.na(dataset_col)) character() else unique(as.character(datasets[[dataset_col]]))
    dataset_names <- dataset_names[nzchar(dataset_names) & !is.na(dataset_names)]
    if (length(dataset_names) == 0L) { cat("[WARN] No dataset names resolved for study.\n"); invisible(FALSE) } else {
      total_rows_read <- 0L
      for (i in seq_along(dataset_names)) {
        dataset_name <- dataset_names[[i]]
        cat("\n[INFO] Reading dataset ", i, "/", length(dataset_names), ": ", dataset_name, "\n", sep = "")
        result <- dataset_data(client, study = target_study, dataset = dataset_name, limit = 10L, format = "json")
        rows <- result$data
        if (!is.null(result$payloads)) {
          arrow_i <- which(vapply(result$payloads, function(p) identical(p$kind, "arrow_ipc"), logical(1)))[1]
          if (!is.na(arrow_i)) rows <- as.data.frame(arrow_ipc_to_table(result$payloads[[arrow_i]]))
        }
        if (is.character(rows) && length(rows) == 1L && nzchar(rows)) rows <- jsonlite::fromJSON(rows, simplifyDataFrame = TRUE)
        if (!is.data.frame(rows)) rows <- as.data.frame(rows)
        total_rows_read <- total_rows_read + nrow(rows)
        cat("[INFO] Loaded dataset ", dataset_name, ": rows=", nrow(rows), ", cols=", ncol(rows), "\n", sep = "")
      }
      cat("\n[INFO] Total rows read across all datasets: ", total_rows_read, "\n", sep = "")
    }
  }
}
