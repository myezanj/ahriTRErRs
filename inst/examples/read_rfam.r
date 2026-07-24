#!/usr/bin/env Rscript
# Read datasets from the Rfam_Database_Collection study.
# Uses ahriTRErRs package; expects a live session.

library(ahriTRErRs)

`%||%` <- function(x, y) if (is.null(x)) y else x

# ----- Main script -----

runtime_root <- Sys.getenv("AHRI_TRE_RUNTIME_ROOT", unset = "")
runtime_manifest_exists <- function(root) {
  nzchar(root) && file.exists(file.path(root, "share", "ahri-tre", "manifest.json"))
}

if (!runtime_manifest_exists(runtime_root)) {
  candidates <- c(
    "/workspaces/ahriTRErRs/.runtime/ahri-tre-runtime",
    "/opt/ahri-tre-runtime"
  )
  resolved <- ""
  for (cand in candidates) {
    if (runtime_manifest_exists(cand)) {
      resolved <- cand
      break
    }
  }

  if (!nzchar(resolved)) {
    stop("AHRI_TRE_RUNTIME_ROOT is unset or invalid, and no local runtime artifact was found.")
  }

  Sys.setenv(AHRI_TRE_RUNTIME_ROOT = resolved)
  runtime_root <- resolved
  cat("[INFO] Using AHRI_TRE_RUNTIME_ROOT:", resolved, "\n")
}

client <- AhriTreClient()
on.exit(close(client), add = TRUE)

with_client_retry <- function(expr, retries = 1L) {
  attempts <- 0L
  repeat {
    attempts <- attempts + 1L
    out <- try(eval.parent(substitute(expr)), silent = TRUE)
    if (!inherits(out, "try-error")) {
      return(out)
    }

    msg <- as.character(out)
    if (attempts > retries || !grepl("client handle is closed or invalid", msg, fixed = TRUE)) {
      stop(msg)
    }

    cat("[WARN] Client handle invalid; recreating AhriTreClient() and retrying...\n")
    try(close(client), silent = TRUE)
    client <<- AhriTreClient()
  }
}

with_client_retry_or_null <- function(expr, context = "request") {
  out <- try(with_client_retry(eval.parent(substitute(expr))), silent = TRUE)
  if (!inherits(out, "try-error")) {
    return(out)
  }

  msg <- as.character(out)
  if (grepl("request envelope is invalid", msg, fixed = TRUE)) {
    cat("[WARN]", context, "returned invalid request envelope; skipping this step.\n")
    return(NULL)
  }

  stop(msg)
}

parse_first_json_object <- function(lines) {
  if (length(lines) == 0) return(NULL)
  text <- paste(lines, collapse = "\n")
  start <- regexpr("\\{", text)
  if (start[[1]] < 1) return(NULL)
  parsed <- try(jsonlite::fromJSON(substr(text, start[[1]], nchar(text)), simplifyVector = FALSE), silent = TRUE)
  if (inherits(parsed, "try-error")) NULL else parsed
}

to_data_frame <- function(x) {
  if (is.null(x)) return(NULL)
  if (is.data.frame(x)) return(x)
  if (is.list(x)) {
    for (cand in c("rows", "items", "studies", "datasets", "domains", "data")) {
      if (!is.null(x[[cand]])) {
        return(to_data_frame(x[[cand]]))
      }
    }
  }
  converted <- try(jsonlite::fromJSON(jsonlite::toJSON(x, auto_unbox = TRUE), simplifyDataFrame = TRUE), silent = TRUE)
  if (!inherits(converted, "try-error") && is.data.frame(converted)) converted else NULL
}

cli_call <- function(kind, body = list(), context = kind) {
  cli_try_activate_live_session <- function(bin, env) {
    out <- suppressWarnings(system2(bin, args = c("session", "list", "--format", "json"), stdout = TRUE, stderr = TRUE, env = env))
    parsed <- parse_first_json_object(out)
    if (is.null(parsed) || !isTRUE(parsed$ok) || is.null(parsed$data$sessions)) {
      return(FALSE)
    }

    sessions <- parsed$data$sessions
    target <- NULL

    for (s in sessions) {
      n <- s$session$name %||% NULL
      if (is.character(n) && nzchar(n) && identical(s$availability %||% "", "live")) {
        target <- n
        break
      }
    }

    if (is.null(target)) {
      for (s in sessions) {
        n <- s$session$name %||% NULL
        if (!is.character(n) || !nzchar(n)) next
        mode <- s$auth_mode %||% ""
        live <- identical(s$availability %||% "", "live")
        if (!live && grepl("oauth", mode, ignore.case = TRUE)) {
          ro <- suppressWarnings(system2(bin, args = c("session", "reopen", n, "--format", "json"), stdout = TRUE, stderr = TRUE, env = env))
          rj <- parse_first_json_object(ro)
          if (!is.null(rj) && isTRUE(rj$ok)) {
            target <- n
            break
          }
        }
      }
    }

    if (is.null(target)) return(FALSE)

    use <- suppressWarnings(system2(bin, args = c("session", "use", target, "--format", "json"), stdout = TRUE, stderr = TRUE, env = env))
    uj <- parse_first_json_object(use)
    !is.null(uj) && isTRUE(uj$ok)
  }

  run_cli <- function(args, env, context, retried = FALSE) {
    out <- try(suppressWarnings(system2(bin, args = args, stdout = TRUE, stderr = TRUE, env = env)), silent = TRUE)
    if (inherits(out, "try-error")) {
      stop(context, " CLI fallback failed to execute: ", as.character(out))
    }
    parsed <- parse_first_json_object(out)
    if (is.null(parsed)) {
      stop(context, " CLI fallback failed: could not parse JSON response.")
    }
    if (!isTRUE(parsed$ok)) {
      msg <- parsed$error$message %||% parsed$message %||% "CLI command failed"
      if (!retried && grepl("no live session is selected", msg, fixed = TRUE) && cli_try_activate_live_session(bin, env)) {
        return(run_cli(args, env, context, retried = TRUE))
      }
      stop(context, " CLI fallback failed: ", msg)
    }
    parsed$data %||% list()
  }

  runtime <- Sys.getenv("AHRI_TRE_RUNTIME_ROOT", "")
  bin <- file.path(runtime, "bin", "ahri-tre")
  runtime_lib <- file.path(runtime, "lib")
  if (!nzchar(runtime) || !file.exists(bin)) {
    stop("CLI fallback unavailable: ahri-tre binary not found under AHRI_TRE_RUNTIME_ROOT.")
  }

  args <- strsplit(kind, "\\.", fixed = FALSE)[[1]]
  if (length(body) > 0) {
    for (k in names(body)) {
      v <- body[[k]]
      if (is.null(v)) next
      flag <- paste0("--", gsub("_", "-", k, fixed = TRUE))
      if (is.logical(v) && length(v) == 1L) {
        if (isTRUE(v)) args <- c(args, flag)
        next
      }
      for (item in as.character(v)) {
        args <- c(args, flag, item)
      }
    }
  }

  env <- c(paste0("LD_LIBRARY_PATH=", paste(c(runtime_lib, Sys.getenv("LD_LIBRARY_PATH")), collapse = ":")))
  run_cli(args, env, context, retried = FALSE)
}

protocol_call <- function(kind, body = list(), context = kind, allow_invalid = FALSE) {
  request <- list(protocol_version = "1.0.0", kind = kind, body = body)
  result <- try(with_client_retry(execute_json(client, request)), silent = TRUE)

  if (inherits(result, "try-error")) {
    msg <- as.character(result)
    if (grepl("request envelope is invalid", msg, fixed = TRUE)) {
      if (allow_invalid) {
        cat("[WARN]", context, "returned invalid request envelope; skipping this step.\n")
        return(NULL)
      }
      cli_out <- try(cli_call(kind, body, context), silent = TRUE)
      if (inherits(cli_out, "try-error")) {
        cli_msg <- as.character(cli_out)
        if (allow_invalid && grepl("no live session is selected", cli_msg, fixed = TRUE)) {
          cat("[WARN]", context, "requires a live session; skipping this step.\n")
          return(NULL)
        }
        stop(cli_msg)
      }
      return(cli_out)
    }
    stop(msg)
  }

  envelope <- result$envelope %||% list()
  ok <- isTRUE(envelope$ok) || (is.null(envelope$error) && is.null(envelope$failure))
  if (ok) {
    return(envelope$data %||% envelope$result %||% envelope$output %||% envelope$body %||% list())
  }

  msg <- envelope$error$message %||% envelope$message %||% "protocol request failed"
  if (grepl("request envelope is invalid", msg, fixed = TRUE)) {
    if (allow_invalid) {
      cat("[WARN]", context, "returned invalid request envelope; skipping this step.\n")
      return(NULL)
    }
    cli_out <- try(cli_call(kind, body, context), silent = TRUE)
    if (inherits(cli_out, "try-error")) {
      cli_msg <- as.character(cli_out)
      if (allow_invalid && grepl("no live session is selected", cli_msg, fixed = TRUE)) {
        cat("[WARN]", context, "requires a live session; skipping this step.\n")
        return(NULL)
      }
      stop(cli_msg)
    }
    return(cli_out)
  }
  stop(context, " failed: ", msg)
}

# List domains
domains <- protocol_call("domain.list", list(format = "json"), context = "domain_list", allow_invalid = TRUE)
if (!is.null(domains)) {
  cat("\n[INFO] Domains found:\n")
  print(to_data_frame(domains))
}

# Get Basic_Science domain
domain_info <- protocol_call("domain.get", list(name = "Basic_Science", format = "json"), context = "domain_get", allow_invalid = TRUE)
if (!is.null(domain_info)) {
  if (is.null(domain_info$domain)) {
    cat("[WARN] Domain 'Basic_Science' not found; continuing.\n")
  } else {
    cat("\n[INFO] Domain details:\n")
    print(domain_info$domain)
  }
}

# List studies
studies <- protocol_call("study.list", list(format = "json"), context = "study_list", allow_invalid = TRUE)
if (is.null(studies)) {
  cat("[WARN] study_list unavailable. Open/select a live session first:\n")
  cat("       ahri-tre session list\n")
  cat("       ahri-tre session use <name>\n")
  cat("       ahri-tre session open-oauth <name> --profile <profile>\n")
  quit(save = "no", status = 0)
}
studies_df <- to_data_frame(studies)
cat("\n[INFO] Studies found:\n")
print(studies_df)

study_name <- "Rfam_Database_Collection"
study <- protocol_call("study.get", list(name = study_name, format = "json"), context = "study_get", allow_invalid = TRUE)
if (is.null(study) || is.null(study$study)) {
  cat("[WARN] study_get failed or study was not returned; proceeding with study name fallback.\n")
}
cat("\n[INFO] Using study:", study_name, "\n")

# List datasets in the study
datasets <- protocol_call("dataset.list", list(study = study_name, include_versions = TRUE, format = "json"), context = "dataset_list")
datasets_df <- to_data_frame(datasets)
cat("\n[INFO] Datasets in study:\n")
print(datasets_df)

# Get dataset names
if (is.null(datasets_df) || is.null(datasets_df$name)) {
  stop("dataset_list did not return tabular dataset names.")
}
ds_names <- unique(datasets_df$name)
if (length(ds_names) == 0) {
  cat("[WARN] No datasets found.\n")
  quit(save = "no", status = 0)
}

# Read first few rows from each dataset
for (nm in ds_names) {
  cat("\n[INFO] Reading dataset:", nm, "\n")
  rows <- try(to_data_frame(protocol_call("dataset.data", list(study = study_name, dataset = nm, limit = 10, format = "json"), context = paste0("dataset_data:", nm))), silent = TRUE)
  if (inherits(rows, "try-error")) {
    cat("[WARN] Failed to read:", as.character(rows), "\n")
    next
  }
  cat("[INFO] Rows:", nrow(rows), " Cols:", ncol(rows), "\n")
  if (nrow(rows) > 0) print(utils::head(rows, 3))
}

cat("\n[INFO] Done.\n")