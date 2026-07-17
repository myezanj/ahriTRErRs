suppressPackageStartupMessages(library(ahriTRErRs))
if (file.exists(".env")) readRenviron(".env")
if (!nzchar(Sys.getenv("SUPER_PASSWORD", unset = "")) && nzchar(Sys.getenv("SUPER_PWD", unset = ""))) {
  Sys.setenv(SUPER_PASSWORD = Sys.getenv("SUPER_PWD", unset = ""))
}

runtime_manifest_path <- function(root) file.path(root, "share", "ahri-tre", "manifest.json")
resolve_runtime_root <- function() {
  roots <- unique(c(
    Sys.getenv("AHRI_TRE_RUNTIME_ROOT", unset = "/opt/ahri-tre-runtime"),
    file.path(getwd(), ".runtime", "ahri-tre-runtime"),
    "/workspaces/ahriTRErRs/.runtime/ahri-tre-runtime"
  ))
  probes <- normalizePath(path.expand(roots), mustWork = FALSE)
  hits <- probes[file.exists(runtime_manifest_path(probes))]
  runtime_root <- if (length(hits) > 0) hits[[1]] else probes[[1]]
  list(runtime_root = runtime_root, manifest = runtime_manifest_path(runtime_root), probes = probes)
}

attempt_runtime_install <- function(target_root) {
  installer <- file.path(getwd(), ".devcontainer", "install_ahri_tre_runtime.sh")
  if (!file.exists(installer)) {
    return(list(ok = FALSE, message = paste0("installer not found at ", installer)))
  }

  install_env <- c(
    paste0("AHRI_TRE_RUNTIME_ROOT=", target_root),
    "AHRI_TRE_RELEASE_REPOSITORY=AHRIORG/ahriTREr_rs"
  )
  out <- suppressWarnings(system2("bash", c(installer), stdout = TRUE, stderr = TRUE, env = install_env))
  status <- attr(out, "status")
  if (is.null(status)) status <- 0L
  list(ok = identical(status, 0L), message = paste(out, collapse = "\n"))
}

open_client_or_skip <- function() {
  tryCatch(
    AhriTreClient(),
    error = function(e) {
      msg <- conditionMessage(e)
      if (inherits(e, "ahri_tre_compatibility_error") || grepl("protocol range", msg, ignore.case = TRUE)) {
        cat("[WARN] Protocol compatibility check failed: ", msg, "\n", sep = "")
        cat("[WARN] Skipping dataset read for this runtime/build combination.\n")
        return(NULL)
      }
      stop(e)
    }
  )
}

resolve_target_study <- function(studies, candidates = c("Rfam_Database_Collection", "Rfam Database Collection")) {
  study_col <- c("name", "study", "study_name")
  study_col <- study_col[study_col %in% names(studies)][1]
  if (is.na(study_col)) {
    stop("Study columns not found in study_list response")
  }

  values <- as.character(studies[[study_col]])
  values <- values[!is.na(values) & nzchar(values)]
  for (candidate in candidates) {
    if (any(values == candidate)) {
      return(candidate)
    }
  }

  stop("Study not found. Tried candidates: ", paste(candidates, collapse = ", "))
}

to_data_frame_safe <- function(x, label = "data") {
  if (is.character(x) && length(x) == 1L && nzchar(x)) {
    x <- jsonlite::fromJSON(x, simplifyDataFrame = TRUE)
  }
  if (is.data.frame(x)) {
    return(x)
  }
  tryCatch(
    as.data.frame(x),
    error = function(e) {
      cat("[WARN] Could not coerce ", label, " to data.frame: ", conditionMessage(e), "\n", sep = "")
      data.frame(stringsAsFactors = FALSE)
    }
  )
}

sync_lake_env_from_session <- function(run_cli, session_name = NULL) {
  out <- run_cli(c("session", "list", "--format", "json"))
  parsed <- try(jsonlite::fromJSON(paste(out, collapse = "\n"), simplifyVector = FALSE), silent = TRUE)
  if (inherits(parsed, "try-error") || !isTRUE(parsed$ok) || is.null(parsed$data$sessions)) {
    return(FALSE)
  }

  sessions <- parsed$data$sessions
  selected <- NULL

  if (length(sessions) > 0L) {
    for (s in sessions) {
      if (!is.null(session_name) && nzchar(session_name) && identical(s$session$name, session_name)) {
        selected <- s
        break
      }
      if (isTRUE(s$active)) {
        selected <- s
      }
    }
  }

  if (is.null(selected)) {
    return(FALSE)
  }

  live_lake_data <- if (!is.null(selected$datastore$lake_data$path)) as.character(selected$datastore$lake_data$path) else ""
  live_lake_db <- ""
  if (!is.null(selected$datastore$lake_db$path)) {
    live_lake_db <- as.character(selected$datastore$lake_db$path)
  } else if (!is.null(selected$datastore$catalog_schema)) {
    live_lake_db <- as.character(selected$datastore$catalog_schema)
  }

  if (nzchar(live_lake_data)) {
    Sys.setenv(TRE_LAKE_PATH = live_lake_data)
  }
  if (nzchar(live_lake_db)) {
    Sys.setenv(TRE_LAKE_DB = live_lake_db)
  }

  if (nzchar(live_lake_data) || nzchar(live_lake_db)) {
    cat("[INFO] Synced lake config from session metadata: TRE_LAKE_PATH=", live_lake_data, ", TRE_LAKE_DB=", live_lake_db, "\n", sep = "")
    return(TRUE)
  }

  FALSE
}

extract_studies_table <- function(studies_raw) {
  if (is.list(studies_raw) && !is.null(studies_raw$studies) && is.list(studies_raw$studies)) {
    names_vec <- vapply(studies_raw$studies, function(entry) {
      if (is.list(entry) && !is.null(entry$study) && is.list(entry$study) && !is.null(entry$study$name)) {
        as.character(entry$study$name[[1]])
      } else {
        NA_character_
      }
    }, character(1), USE.NAMES = FALSE)
    ids_vec <- vapply(studies_raw$studies, function(entry) {
      if (is.list(entry) && !is.null(entry$study) && is.list(entry$study) && !is.null(entry$study$study_id)) {
        as.character(entry$study$study_id[[1]])
      } else {
        NA_character_
      }
    }, character(1), USE.NAMES = FALSE)
    return(data.frame(name = names_vec, study_id = ids_vec, stringsAsFactors = FALSE))
  }
  to_data_frame_safe(studies_raw, label = "studies")
}

extract_dataset_names <- function(datasets_raw) {
  if (is.list(datasets_raw) && !is.null(datasets_raw$datasets) && is.list(datasets_raw$datasets)) {
    names_vec <- vapply(datasets_raw$datasets, function(entry) {
      if (is.list(entry) && !is.null(entry$catalog) && is.list(entry$catalog) &&
          !is.null(entry$catalog$asset) && is.list(entry$catalog$asset) &&
          !is.null(entry$catalog$asset$name)) {
        as.character(entry$catalog$asset$name[[1]])
      } else {
        NA_character_
      }
    }, character(1), USE.NAMES = FALSE)
    return(unique(names_vec[!is.na(names_vec) & nzchar(names_vec)]))
  }

  datasets_df <- to_data_frame_safe(datasets_raw, label = "datasets")
  dataset_col <- c("name", "dataset", "dataset_name")
  dataset_col <- dataset_col[dataset_col %in% names(datasets_df)][1]
  if (is.na(dataset_col)) {
    return(character())
  }
  values <- unique(as.character(datasets_df[[dataset_col]]))
  values[nzchar(values) & !is.na(values)]
}

read_dataset_rows_safe <- function(client, study_name, dataset_name, limit = 10L) {
  preview_result <- try(
    dataset_preview(
      client,
      study = study_name,
      dataset = dataset_name,
      limit = limit,
      format = "json"
    ),
    silent = TRUE
  )

  if (!inherits(preview_result, "try-error")) {
    rows <- to_data_frame_safe(preview_result$data, label = paste0("preview rows for dataset ", dataset_name))
    return(list(ok = TRUE, rows = rows, source = "dataset_preview"))
  }

  preview_msg <- as.character(preview_result)
  if (grepl("Table with name .* does not exist because schema .* does not exist", preview_msg, ignore.case = TRUE)) {
    return(list(ok = FALSE, message = paste0("dataset_preview failed: ", preview_msg)))
  }

  data_result <- try(
    dataset_data(
      client,
      study = study_name,
      dataset = dataset_name,
      limit = limit,
      format = "json"
    ),
    silent = TRUE
  )

  if (!inherits(data_result, "try-error")) {
    rows <- data_result$data
    if (!is.null(data_result$payloads)) {
      arrow_i <- which(vapply(data_result$payloads, function(p) identical(p$kind, "arrow_ipc"), logical(1)))[1]
      if (!is.na(arrow_i)) {
        rows <- as.data.frame(arrow_ipc_to_table(data_result$payloads[[arrow_i]]))
      }
    }
    rows <- to_data_frame_safe(rows, label = paste0("rows for dataset ", dataset_name))
    return(list(ok = TRUE, rows = rows, source = "dataset_data"))
  }

  list(
    ok = FALSE,
    message = paste0(
      "dataset_preview failed: ", preview_msg,
      " | dataset_data failed: ", as.character(data_result)
    )
  )
}

dataset_read_preflight <- function(client, study_name, dataset_names) {
  if (length(dataset_names) == 0L) {
    return(invisible(TRUE))
  }

  sample_dataset <- dataset_names[[1]]
  probe <- try(
    dataset_preview(
      client,
      study = study_name,
      dataset = sample_dataset,
      limit = 1L,
      format = "json"
    ),
    silent = TRUE
  )

  if (!inherits(probe, "try-error")) {
    cat("[INFO] Dataset read preflight passed using dataset_preview for sample dataset: ", sample_dataset, "\n", sep = "")
    return(invisible(TRUE))
  }

  msg <- as.character(probe)
  if (grepl("Table with name .* does not exist because schema .* does not exist", msg, ignore.case = TRUE)) {
    cat("[WARN] Dataset read preflight failed: lake schema/table missing for sample dataset ", sample_dataset, ".\n", sep = "")
    cat("[INFO] This usually means the datastore catalog has dataset metadata but underlying DuckLake tables are absent or not mounted.\n")
    cat("[INFO] Verify TRE_LAKE_PATH and TRE_LAKE_DB match the active session and that the study dataset tables exist in the lake backend.\n")
    print_backend_read_checklist(study_name = study_name, dataset_name = sample_dataset)
    return(invisible(FALSE))
  }

  if (grepl("request envelope is invalid", msg, ignore.case = TRUE)) {
    cat("[WARN] Dataset read preflight failed: runtime rejected dataset preview request envelope for sample dataset ", sample_dataset, ".\n", sep = "")
    cat("[INFO] Runtime/SDK protocol alignment may be incomplete for dataset read operations.\n")
    return(invisible(FALSE))
  }

  cat("[WARN] Dataset read preflight failed for sample dataset ", sample_dataset, ": ", msg, "\n", sep = "")
  invisible(FALSE)
}

should_fail_fast_after_preflight <- function() {
  value <- tolower(trimws(Sys.getenv("AHRI_TRE_READ_PREFLIGHT_FAIL_FAST", unset = "false")))
  value %in% c("1", "true", "yes", "on")
}

print_backend_read_checklist <- function(study_name, dataset_name) {
  lake_path <- Sys.getenv("TRE_LAKE_PATH", unset = "")
  lake_db <- Sys.getenv("TRE_LAKE_DB", unset = "")
  session_name <- ""
  runtime_root <- Sys.getenv("AHRI_TRE_RUNTIME_ROOT", unset = "")
  cli_bin <- if (nzchar(runtime_root)) file.path(runtime_root, "bin", "ahri-tre") else ""
  if (nzchar(cli_bin) && file.exists(cli_bin)) {
    cli_env <- c(paste0("LD_LIBRARY_PATH=", file.path(runtime_root, "lib"), ":", Sys.getenv("LD_LIBRARY_PATH", unset = "")))
    status_out <- suppressWarnings(system2(cli_bin, c("session", "status", "--format", "json"), stdout = TRUE, stderr = TRUE, env = cli_env))
    status_json <- try(jsonlite::fromJSON(paste(status_out, collapse = "\n"), simplifyVector = FALSE), silent = TRUE)
    if (!inherits(status_json, "try-error") && isTRUE(status_json$ok) && !is.null(status_json$data$session$datastore$datastore)) {
      session_name <- as.character(status_json$data$session$datastore$datastore)
    }
  }
  if (!nzchar(session_name)) {
    session_name <- Sys.getenv("TRE_DATASTORE", unset = Sys.getenv("TRE_DBNAME", unset = ""))
  }

  cat("[INFO] Backend checklist (copy/paste):\n")
  cat("[INFO] 1. Confirm live session context:\n")
  cat("[INFO]    ahri-tre session status --format json\n")
  cat("[INFO] 2. Confirm metadata exists for this dataset:\n")
  cat("[INFO]    ahri-tre dataset metadata --study ", study_name, " --dataset ", dataset_name, " --format json\n", sep = "")
  cat("[INFO] 3. Probe data path directly:\n")
  cat("[INFO]    ahri-tre dataset preview --study ", study_name, " --dataset ", dataset_name, " --limit 1 --format json\n", sep = "")
  if (nzchar(session_name)) {
    cat("[INFO] 4. Inspect datastore binding:\n")
    cat("[INFO]    ahri-tre datastore info --datastore ", session_name, " --format json\n", sep = "")
  }
  if (nzchar(lake_path) || nzchar(lake_db)) {
    cat("[INFO] 5. Check effective lake env:\n")
    cat("[INFO]    TRE_LAKE_PATH=", lake_path, "\n", sep = "")
    cat("[INFO]    TRE_LAKE_DB=", lake_db, "\n", sep = "")
  }
}

profile_env <- "/workspaces/ahriTRErRs/.runtime/ahri-tre-runtime/share/ahri-tre/profile.env"
if (file.exists(profile_env) && file.access(profile_env, 4) == 0) { readRenviron(profile_env); cat("[INFO] Loaded runtime profile env: ", profile_env, "\n", sep = "") }
req <- c("TRE_SERVER"); miss <- req[!nzchar(Sys.getenv(req, unset = ""))]
if (length(miss) > 0) stop("Missing required vars: ", paste(miss, collapse = ", "), call. = FALSE)
cat("[INFO] Runtime profile env verification passed.\n")
server <- Sys.getenv("TRE_SERVER", unset = ""); lake_db <- Sys.getenv("TRE_LAKE_DB", unset = Sys.getenv("TRE_TEST_LAKE_DB", unset = "")); lake_data <- Sys.getenv("TRE_LAKE_PATH", unset = Sys.getenv("TRE_TEST_LAKE_PATH", unset = ""))
if (nzchar(lake_db)) Sys.setenv(TRE_LAKE_DB = lake_db); if (nzchar(lake_data)) Sys.setenv(TRE_LAKE_PATH = lake_data)
runtime_probe <- resolve_runtime_root()
runtime_root <- runtime_probe$runtime_root
manifest <- runtime_probe$manifest
if (!file.exists(manifest)) {
  cat("[WARN] Runtime preflight failed: manifest not found at ", manifest, "\n", sep = "")
  auto_install <- tolower(trimws(Sys.getenv("AHRI_TRE_AUTO_INSTALL_RUNTIME", unset = "true"))) %in% c("1", "true", "yes", "on")
  if (auto_install) {
    cat("[INFO] Attempting runtime auto-install into /workspaces/ahriTRErRs/.runtime/ahri-tre-runtime\n")
    install_result <- attempt_runtime_install("/workspaces/ahriTRErRs/.runtime/ahri-tre-runtime")
    runtime_probe <- resolve_runtime_root()
    runtime_root <- runtime_probe$runtime_root
    manifest <- runtime_probe$manifest
    if (!isTRUE(install_result$ok) || !file.exists(manifest)) {
      cat("[WARN] Runtime auto-install did not produce a valid manifest.\n")
      if (nzchar(install_result$message)) {
        msg_lines <- strsplit(install_result$message, "\n", fixed = TRUE)[[1]]
        tail_lines <- tail(msg_lines[nzchar(msg_lines)], 12)
        if (length(tail_lines) > 0) {
          cat("[INFO] Installer output (tail):\n", paste(tail_lines, collapse = "\n"), "\n", sep = "")
        }
      }
    }
  }

  if (!file.exists(manifest)) {
    cat("[INFO] To install runtime manually: AHRI_TRE_RUNTIME_ROOT=/workspaces/ahriTRErRs/.runtime/ahri-tre-runtime bash .devcontainer/install_ahri_tre_runtime.sh\n")
    cat("[INFO] If release access is unavailable, place a runtime archive in .devcontainer/runtime/ and rerun.\n")
    cat("[WARN] Skipping script execution.\n")
    invisible(FALSE)
  } else {
    cat("[INFO] Runtime manifest is now available at ", manifest, "\n", sep = "")
    Sys.setenv(AHRI_TRE_RUNTIME_ROOT = runtime_root)
    session_name <- "pilot_tre"; cli_bin <- file.path(runtime_root, "bin", "ahri-tre")
    cli_env <- paste0("LD_LIBRARY_PATH=", file.path(runtime_root, "lib"), ":", Sys.getenv("LD_LIBRARY_PATH", unset = ""))
    run_cli <- function(args, env = cli_env) suppressWarnings(system2(cli_bin, args, stdout = TRUE, stderr = TRUE, env = env))
    stop_before_study <- FALSE
    cat("[INFO] Using ahriTRErRs package wrappers.\n[INFO] AHRI_TRE_RUNTIME_ROOT=", runtime_root, "\n[INFO] OAuth flag: --profile <profile>\n", sep = "")
    cat("[INFO] Resolved datastore config: server=", server, ", datastore=", session_name, ", lake_db=", lake_db, ", lake_data=", lake_data, "\n", sep = "")
    if (file.exists(cli_bin)) {
      cat("[INFO] Session list snapshot:\n", paste(run_cli(c("session", "list", "--format", "json")), collapse = "\n"), "\n", sep = "")
      if (nzchar(session_name)) run_cli(c("session", "use", session_name, "--format", "json"))
      sync_lake_env_from_session(run_cli, session_name)
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
          super_user <- Sys.getenv("SUPER_USER", unset = ""); super_password <- Sys.getenv("SUPER_PASSWORD", unset = Sys.getenv("SUPER_PWD", unset = ""))
          if (!nzchar(super_user) || !nzchar(super_password)) cat("[WARN] SUPER_USER/SUPER_PASSWORD (or SUPER_PWD) not set; schema migration cannot run automatically.\n")
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
            cat("[INFO] Missing SUPER_USER/SUPER_PASSWORD (or SUPER_PWD) for automatic schema migration.\n[INFO] Run: ahri-tre datastore schema-status --datastore ", session_name, " --super-user \"$SUPER_USER\" --super-password-env SUPER_PASSWORD --env-file .env --format json\n[INFO] Run: ahri-tre datastore schema-migrate --datastore ", session_name, " --super-user \"$SUPER_USER\" --super-password-env SUPER_PASSWORD --env-file .env --format json\n", sep = "")
            stop_before_study <- TRUE
          }
        }
        unlink(open_profile_env, force = TRUE)
      }
    }
    if (isTRUE(stop_before_study)) { cat("[WARN] Skipping study_list until session/datastore remediation is completed.\n"); invisible(FALSE) } else {
      if (file.exists(cli_bin) && nzchar(session_name)) {
        status_text <- paste(run_cli(c("session", "status", "--format", "json")), collapse = "\n")
        if (grepl("no live session is selected", status_text, ignore.case = TRUE) ||
          grepl("\"ok\": false", status_text, fixed = TRUE)) {
          cat("[WARN] Session status is not live immediately before study read.\n")
          cat("[INFO] Session status output:\n", status_text, "\n", sep = "")
          cat("[INFO] Open or select a live session and rerun this example.\n")
          invisible(FALSE)
        }
      }

      target_study <- "Rfam_Database_Collection"
      client <- open_client_or_skip()
      if (is.null(client)) {
        invisible(FALSE)
      } else {
        on.exit(close(client), add = TRUE)
      studies_result <- tryCatch(
        study_list(client, format = "json"),
        error = function(e) {
          msg <- conditionMessage(e)
          if (grepl("no live session is selected|daemon", msg, ignore.case = TRUE)) {
            cat("[WARN] Unable to query studies: ", msg, "\n", sep = "")
            cat("[INFO] Open or select a session first, then rerun this example.\n")
            return(NULL)
          }
            if (grepl("invalid NCName", msg, ignore.case = TRUE)) {
              cat("[WARN] Study metadata decode failed: ", msg, "\n", sep = "")
              cat("[INFO] The datastore contains a study name that violates NCName rules; clean/rename the offending study and rerun.\n")
              return(NULL)
            } else {
              stop(e)
            }
        }
      )
      if (is.null(studies_result)) {
        invisible(FALSE)
      } else {
      studies <- studies_result$data
      studies <- extract_studies_table(studies)
      cat("\n[INFO] Studies found: ", nrow(studies), "\n", sep = "")
      target_study <- resolve_target_study(studies)
      cat("\n[INFO] Selected study: ", target_study, "\n", sep = "")
      datasets <- dataset_list(client, study = target_study, include_versions = TRUE, format = "json")$data
      dataset_names <- extract_dataset_names(datasets)
      cat("[INFO] Dataset entries found for selected study: ", length(dataset_names), "\n", sep = "")
      preflight_ok <- dataset_read_preflight(client, target_study, dataset_names)
      fail_fast <- !isTRUE(preflight_ok) && should_fail_fast_after_preflight()
      if (isTRUE(fail_fast)) {
        cat("[WARN] Stopping early because AHRI_TRE_READ_PREFLIGHT_FAIL_FAST is enabled.\n")
      } else if (!isTRUE(preflight_ok)) {
        cat("[INFO] Continuing despite preflight failure. Set AHRI_TRE_READ_PREFLIGHT_FAIL_FAST=true to stop early.\n")
      }
      if (isTRUE(fail_fast)) {
        cat("[INFO] Skipping dataset iteration due to fail-fast preflight mode.\n")
        invisible(FALSE)
      } else if (length(dataset_names) == 0L) { cat("[WARN] No dataset names resolved for study.\n"); invisible(FALSE) } else {
        total_rows_read <- 0L
        for (i in seq_along(dataset_names)) {
          dataset_name <- dataset_names[[i]]
          cat("\n[INFO] Reading dataset ", i, "/", length(dataset_names), ": ", dataset_name, "\n", sep = "")
          rows_result <- read_dataset_rows_safe(client, target_study, dataset_name, limit = 10L)
          if (!isTRUE(rows_result$ok)) {
            cat("[WARN] Dataset read failed: ", rows_result$message, "\n", sep = "")
            next
          }
          rows <- rows_result$rows
          total_rows_read <- total_rows_read + nrow(rows)
          cat("[INFO] Loaded dataset ", dataset_name, " via ", rows_result$source, ": rows=", nrow(rows), ", cols=", ncol(rows), "\n", sep = "")
        }
        cat("\n[INFO] Total rows read across all datasets: ", total_rows_read, "\n", sep = "")
      }
      }
      }
    }
  }
} else {
  Sys.setenv(AHRI_TRE_RUNTIME_ROOT = runtime_root)
  session_name <- "pilot_tre"; cli_bin <- file.path(runtime_root, "bin", "ahri-tre")
  cli_env <- paste0("LD_LIBRARY_PATH=", file.path(runtime_root, "lib"), ":", Sys.getenv("LD_LIBRARY_PATH", unset = ""))
  run_cli <- function(args, env = cli_env) suppressWarnings(system2(cli_bin, args, stdout = TRUE, stderr = TRUE, env = env))
  stop_before_study <- FALSE
  cat("[INFO] Using ahriTRErRs package wrappers.\n[INFO] AHRI_TRE_RUNTIME_ROOT=", runtime_root, "\n[INFO] OAuth flag: --profile <profile>\n", sep = "")
  cat("[INFO] Resolved datastore config: server=", server, ", datastore=", session_name, ", lake_db=", lake_db, ", lake_data=", lake_data, "\n", sep = "")
  if (file.exists(cli_bin)) {
    cat("[INFO] Session list snapshot:\n", paste(run_cli(c("session", "list", "--format", "json")), collapse = "\n"), "\n", sep = "")
    if (nzchar(session_name)) run_cli(c("session", "use", session_name, "--format", "json"))
    sync_lake_env_from_session(run_cli, session_name)
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
        super_user <- Sys.getenv("SUPER_USER", unset = ""); super_password <- Sys.getenv("SUPER_PASSWORD", unset = Sys.getenv("SUPER_PWD", unset = ""))
        if (!nzchar(super_user) || !nzchar(super_password)) cat("[WARN] SUPER_USER/SUPER_PASSWORD (or SUPER_PWD) not set; schema migration cannot run automatically.\n")
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
          cat("[INFO] Missing SUPER_USER/SUPER_PASSWORD (or SUPER_PWD) for automatic schema migration.\n[INFO] Run: ahri-tre datastore schema-status --datastore ", session_name, " --super-user \"$SUPER_USER\" --super-password-env SUPER_PASSWORD --env-file .env --format json\n[INFO] Run: ahri-tre datastore schema-migrate --datastore ", session_name, " --super-user \"$SUPER_USER\" --super-password-env SUPER_PASSWORD --env-file .env --format json\n", sep = "")
          stop_before_study <- TRUE
        }
      }
      unlink(open_profile_env, force = TRUE)
    }
  }
  if (isTRUE(stop_before_study)) { cat("[WARN] Skipping study_list until session/datastore remediation is completed.\n"); invisible(FALSE) } else {
    if (file.exists(cli_bin) && nzchar(session_name)) {
      status_text <- paste(run_cli(c("session", "status", "--format", "json")), collapse = "\n")
        if (grepl("no live session is selected", status_text, ignore.case = TRUE) ||
          grepl("\"ok\": false", status_text, fixed = TRUE)) {
        cat("[WARN] Session status is not live immediately before study read.\n")
        cat("[INFO] Session status output:\n", status_text, "\n", sep = "")
        cat("[INFO] Open or select a live session and rerun this example.\n")
        invisible(FALSE)
      }
    }

    target_study <- "Rfam_Database_Collection"
    client <- open_client_or_skip()
    if (is.null(client)) {
      invisible(FALSE)
    } else {
      on.exit(close(client), add = TRUE)
    studies_result <- tryCatch(
      study_list(client, format = "json"),
      error = function(e) {
        msg <- conditionMessage(e)
        if (grepl("no live session is selected|daemon", msg, ignore.case = TRUE)) {
          cat("[WARN] Unable to query studies: ", msg, "\n", sep = "")
          cat("[INFO] Open or select a session first, then rerun this example.\n")
          return(NULL)
        }
          if (grepl("invalid NCName", msg, ignore.case = TRUE)) {
            cat("[WARN] Study metadata decode failed: ", msg, "\n", sep = "")
            cat("[INFO] The datastore contains a study name that violates NCName rules; clean/rename the offending study and rerun.\n")
            return(NULL)
          } else {
            stop(e)
          }
      }
    )
    if (is.null(studies_result)) {
      invisible(FALSE)
    } else {
    studies <- studies_result$data
    studies <- extract_studies_table(studies)
    cat("\n[INFO] Studies found: ", nrow(studies), "\n", sep = "")
    target_study <- resolve_target_study(studies)
    cat("\n[INFO] Selected study: ", target_study, "\n", sep = "")
    datasets <- dataset_list(client, study = target_study, include_versions = TRUE, format = "json")$data
    dataset_names <- extract_dataset_names(datasets)
    cat("[INFO] Dataset entries found for selected study: ", length(dataset_names), "\n", sep = "")
    preflight_ok <- dataset_read_preflight(client, target_study, dataset_names)
    fail_fast <- !isTRUE(preflight_ok) && should_fail_fast_after_preflight()
    if (isTRUE(fail_fast)) {
      cat("[WARN] Stopping early because AHRI_TRE_READ_PREFLIGHT_FAIL_FAST is enabled.\n")
    } else if (!isTRUE(preflight_ok)) {
      cat("[INFO] Continuing despite preflight failure. Set AHRI_TRE_READ_PREFLIGHT_FAIL_FAST=true to stop early.\n")
    }
    if (isTRUE(fail_fast)) {
      cat("[INFO] Skipping dataset iteration due to fail-fast preflight mode.\n")
      invisible(FALSE)
    } else if (length(dataset_names) == 0L) { cat("[WARN] No dataset names resolved for study.\n"); invisible(FALSE) } else {
      total_rows_read <- 0L
      for (i in seq_along(dataset_names)) {
        dataset_name <- dataset_names[[i]]
        cat("\n[INFO] Reading dataset ", i, "/", length(dataset_names), ": ", dataset_name, "\n", sep = "")
        rows_result <- read_dataset_rows_safe(client, target_study, dataset_name, limit = 10L)
        if (!isTRUE(rows_result$ok)) {
          cat("[WARN] Dataset read failed: ", rows_result$message, "\n", sep = "")
          next
        }
        rows <- rows_result$rows
        total_rows_read <- total_rows_read + nrow(rows)
        cat("[INFO] Loaded dataset ", dataset_name, " via ", rows_result$source, ": rows=", nrow(rows), ", cols=", ncol(rows), "\n", sep = "")
      }
      cat("\n[INFO] Total rows read across all datasets: ", total_rows_read, "\n", sep = "")
    }
    }
    }
  }
}
