suppressPackageStartupMessages(library(ahriTRErRs))

load_project_env <- function() {
  env_file <- ".env"
  if (file.exists(env_file)) {
    readRenviron(env_file)
  }
}

runtime_preflight <- function() {
  runtime_root <- Sys.getenv("AHRI_TRE_RUNTIME_ROOT", unset = "")
  if (!nzchar(runtime_root)) {
    runtime_root <- "/opt/ahri-tre-runtime"
    Sys.setenv(AHRI_TRE_RUNTIME_ROOT = runtime_root)
  }
  runtime_root <- normalizePath(path.expand(runtime_root), mustWork = FALSE)
  manifest_path <- file.path(runtime_root, "share", "ahri-tre", "manifest.json")

  env_presence <- c(
    AHRI_TRE_RUNTIME_ROOT = nzchar(Sys.getenv("AHRI_TRE_RUNTIME_ROOT", unset = "")),
    TRE_SERVER = nzchar(Sys.getenv("TRE_SERVER", unset = "")),
    TRE_TEST_DBNAME = nzchar(Sys.getenv("TRE_TEST_DBNAME", unset = "")),
    GITHUB_TOKEN = nzchar(Sys.getenv("GITHUB_TOKEN", unset = ""))
  )

  if (!file.exists(manifest_path)) {
    cat("[WARN] Runtime preflight failed: manifest not found at ", manifest_path, "\n", sep = "")
    cat("[INFO] .env parameter presence: ", paste(names(env_presence), env_presence, sep = "=", collapse = ", "), "\n", sep = "")
    cat("[INFO] To install runtime: bash .devcontainer/install_ahri_tre_runtime.sh\n")
    return(FALSE)
  }

  TRUE
}

is_connectivity_failure <- function(message) {
  grepl(
    paste(
      c(
        "AHRI TRE runtime manifest was not found",
        "runtime manifest was not found under the artifact root",
        "Failed to locate TRE runtime artifacts",
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

normalize_records <- function(value) {
  if (is.null(value)) {
    return(data.frame())
  }
  if (is.data.frame(value)) {
    return(value)
  }
  if (is.character(value) && length(value) == 1L && nzchar(value)) {
    parsed <- try(jsonlite::fromJSON(value, simplifyDataFrame = TRUE), silent = TRUE)
    if (!inherits(parsed, "try-error")) {
      return(normalize_records(parsed))
    }
  }
  if (is.list(value)) {
    for (candidate in c("items", "rows", "data", "result", "output", "body", "studies", "datasets")) {
      if (!is.null(value[[candidate]])) {
        return(normalize_records(value[[candidate]]))
      }
    }
    as_df <- try(jsonlite::fromJSON(jsonlite::toJSON(value, auto_unbox = TRUE), simplifyDataFrame = TRUE), silent = TRUE)
    if (!inherits(as_df, "try-error") && is.data.frame(as_df)) {
      return(as_df)
    }
  }
  data.frame()
}

first_present_column <- function(df, candidates) {
  present <- candidates[candidates %in% names(df)]
  if (length(present) == 0L) {
    return(rep(NA_character_, nrow(df)))
  }
  as.character(df[[present[[1]]]])
}

extract_rows_from_dataset_data <- function(result) {
  payloads <- result$payloads %||% list()
  arrow_payload_index <- which(vapply(payloads, function(p) identical(p$kind, "arrow_ipc"), logical(1)))[1]
  if (!is.na(arrow_payload_index)) {
    converted <- try(arrow_ipc_to_table(payloads[[arrow_payload_index]]), silent = TRUE)
    if (!inherits(converted, "try-error")) {
      return(as.data.frame(converted))
    }
    cat("[WARN] Arrow IPC payload detected but conversion failed; falling back to JSON body.\n")
  }
  normalize_records(result$data)
}

`%||%` <- function(lhs, rhs) {
  if (is.null(lhs)) rhs else lhs
}

requested_study_name <- "Rfam Database Collection"

load_project_env()

cat("[INFO] Using ahritre package wrappers.\n")
cat("[INFO] AHRI_TRE_RUNTIME_ROOT=", Sys.getenv("AHRI_TRE_RUNTIME_ROOT", unset = ""), "\n", sep = "")

if (!runtime_preflight()) {
  cat("[WARN] AHRI TRE runtime files are not installed for the configured artifact root; skipping script execution.\n")
  invisible(FALSE)
} else {

bootstrap <- tryCatch(
  {
    client <- AhriTreClient()
    list(client = client)
  },
  error = function(e) {
    message_text <- conditionMessage(e)
    if (is_connectivity_failure(message_text)) {
      stop(
        paste0(
          "TRE runtime/datastore is unavailable. TRE_SERVER=",
          Sys.getenv("TRE_SERVER", unset = ""),
          ", TRE_TEST_DBNAME=",
          Sys.getenv("TRE_TEST_DBNAME", unset = ""),
          ". Details: ",
          message_text
        ),
        call. = FALSE
      )
    }
    stop(e)
  }
)
if (is.null(bootstrap)) {
  invisible(FALSE)
} else {
  client <- bootstrap$client
  on.exit(close(client), add = TRUE)

  auth_state <- try(auth_status(client, format = "json"), silent = TRUE)
  if (inherits(auth_state, "try-error")) {
    cat("[WARN] Could not query auth status; continuing.\n")
  } else {
    cat("[INFO] Auth status queried successfully.\n")
  }

  studies_result <- study_list(client, format = "json", include_unavailable = TRUE)
  studies <- normalize_records(studies_result$data)
  cat("\n[INFO] Studies found: ", nrow(studies), "\n", sep = "")
  if (nrow(studies) > 0) {
    print(utils::head(studies, 5))
  }

  study_names <- first_present_column(studies, c("name", "study", "study_name"))
  if (!any(study_names == requested_study_name)) {
    stop("Study not found: ", requested_study_name)
  }

  cat("\n[INFO] Selected study: ", requested_study_name, "\n", sep = "")

  assets_result <- asset_list(
    client,
    study = requested_study_name,
    format = "json"
  )
  assets <- normalize_records(assets_result$data)
  cat("[INFO] Asset entries found for selected study: ", nrow(assets), "\n", sep = "")
  if (nrow(assets) > 0) {
    print(utils::head(assets, 10))
  }

  asset_names <- unique(first_present_column(assets, c("name", "asset", "asset_name")))
  asset_names <- asset_names[nzchar(asset_names) & !is.na(asset_names)]
  for (i in seq_along(asset_names)) {
    asset_name <- asset_names[[i]]
    cat("\n[INFO] Reading asset versions ", i, "/", length(asset_names), ": ", asset_name, "\n", sep = "")
    versions_result <- try(
      asset_versions(
        client,
        study = requested_study_name,
        asset = asset_name,
        format = "json"
      ),
      silent = TRUE
    )
    if (inherits(versions_result, "try-error")) {
      cat("[WARN] Asset version read failed: ", as.character(versions_result), "\n", sep = "")
      next
    }
    versions <- normalize_records(versions_result$data)
    cat("[INFO] Asset version entries for ", asset_name, ": ", nrow(versions), "\n", sep = "")
    if (nrow(versions) > 0) {
      print(utils::head(versions, 5))
    }
  }

  datafiles_result <- datafile_list(
    client,
    study = requested_study_name,
    include_versions = TRUE,
    format = "json"
  )
  datafiles <- normalize_records(datafiles_result$data)
  cat("\n[INFO] Datafile asset entries found for selected study: ", nrow(datafiles), "\n", sep = "")
  if (nrow(datafiles) > 0) {
    print(utils::head(datafiles, 10))
  }

  datasets_result <- dataset_list(
    client,
    study = requested_study_name,
    include_versions = TRUE,
    format = "json"
  )
  datasets <- normalize_records(datasets_result$data)
  cat("[INFO] Dataset entries found for selected study: ", nrow(datasets), "\n", sep = "")
  if (nrow(datasets) > 0) {
    print(utils::head(datasets, 5))
  }

  if (nrow(datasets) > 0 && "name" %in% names(datasets)) {
    datasets <- datasets[order(datasets$name), , drop = FALSE]
  }

  dataset_names <- unique(first_present_column(datasets, c("name", "dataset", "dataset_name")))
  dataset_names <- dataset_names[nzchar(dataset_names) & !is.na(dataset_names)]

  total_rows_read <- 0L

  for (i in seq_along(dataset_names)) {
    dataset_name <- dataset_names[[i]]
    cat("\n[INFO] Reading dataset ", i, "/", length(dataset_names), ": ", dataset_name, "\n", sep = "")

    data_result <- try(
      dataset_data(
        client,
        study = requested_study_name,
        dataset = dataset_name,
        limit = NULL,
        format = "json"
      ),
      silent = TRUE
    )
    if (inherits(data_result, "try-error")) {
      cat("[WARN] Dataset read failed: ", as.character(data_result), "\n", sep = "")
      next
    }

    rows <- extract_rows_from_dataset_data(data_result)
    total_rows_read <- total_rows_read + nrow(rows)
    cat("[INFO] Loaded dataset ", dataset_name, ": rows=", nrow(rows), ", cols=", ncol(rows), "\n", sep = "")

    if (ncol(rows) > 0) {
      print(rows[, seq_len(min(5, ncol(rows))), drop = FALSE])
    } else {
      print(rows)
    }
  }

  cat("\n[INFO] Total rows read across all datasets: ", total_rows_read, "\n", sep = "")
}
}
