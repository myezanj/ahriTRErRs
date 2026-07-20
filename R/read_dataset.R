is_scalar_character_value <- function(x) {
  is.character(x) && length(x) == 1L && !is.na(x) && nzchar(x)
}

resolve_dataset_client <- function(ds) {
  if (inherits(ds, "ahri_tre_client")) {
    return(ds)
  }

  if (is.list(ds) && inherits(ds$client, "ahri_tre_client")) {
    return(ds$client)
  }

  abort_ahri_tre(
    "`ds` must be an `ahri_tre_client` or a list-like DataStore object with `$client`.",
    class = "ahri_tre_argument_error"
  )
}

validate_read_dataset_inputs <- function(study_name, dataset_name, include_versions, version) {
  if (!is_scalar_character_value(study_name)) {
    abort_ahri_tre("`study_name` must be a non-empty character scalar.", class = "ahri_tre_argument_error")
  }

  if (!is_scalar_character_value(dataset_name)) {
    abort_ahri_tre("`dataset_name` must be a non-empty character scalar.", class = "ahri_tre_argument_error")
  }

  if (!(is.logical(include_versions) && length(include_versions) == 1L && !is.na(include_versions))) {
    abort_ahri_tre("`include_versions` must be a single TRUE/FALSE value.", class = "ahri_tre_argument_error")
  }

  if (!(is.null(version) || is_scalar_character_value(version))) {
    abort_ahri_tre(
      "`version` must be NULL or a non-empty character scalar.",
      class = "ahri_tre_argument_error"
    )
  }
}

normalize_dataset_records <- function(value) {
  if (is.null(value)) {
    return(data.frame())
  }

  if (is.data.frame(value)) {
    return(value)
  }

  if (is.character(value) && length(value) == 1L && nzchar(value)) {
    parsed <- try(jsonlite::fromJSON(value, simplifyDataFrame = TRUE), silent = TRUE)
    if (!inherits(parsed, "try-error")) {
      return(normalize_dataset_records(parsed))
    }
  }

  if (is.list(value)) {
    for (candidate in c("items", "rows", "data", "result", "output", "body", "datasets")) {
      if (!is.null(value[[candidate]])) {
        return(normalize_dataset_records(value[[candidate]]))
      }
    }

    as_df <- try(
      jsonlite::fromJSON(
        jsonlite::toJSON(value, auto_unbox = TRUE),
        simplifyDataFrame = TRUE
      ),
      silent = TRUE
    )
    if (!inherits(as_df, "try-error") && is.data.frame(as_df)) {
      return(as_df)
    }
  }

  data.frame()
}

first_available_dataset_field <- function(df, names) {
  if (!is.data.frame(df) || nrow(df) == 0L) {
    return(character())
  }

  present <- names[names %in% colnames(df)]
  if (length(present) == 0L) {
    return(rep(NA_character_, nrow(df)))
  }

  as.character(df[[present[[1]]]])
}

select_version_reference <- function(client, study_name, dataset_name, include_versions, version) {
  if (is.null(version) && !isTRUE(include_versions)) {
    return(NULL)
  }

  listed <- try(
    dataset_list(
      client,
      study = study_name,
      include_versions = TRUE,
      format = "json"
    ),
    silent = TRUE
  )

  if (inherits(listed, "try-error")) {
    return(NULL)
  }

  entries <- normalize_dataset_records(listed$data)
  if (!is.data.frame(entries) || nrow(entries) == 0L) {
    return(NULL)
  }

  dataset_values <- first_available_dataset_field(entries, c("name", "dataset", "dataset_name", "asset"))
  version_values <- first_available_dataset_field(entries, c("version", "version_label", "dataset_version", "label"))

  matches_name <- which(!is.na(dataset_values) & dataset_values == dataset_name)
  if (length(matches_name) == 0L) {
    return(NULL)
  }

  selected <- matches_name[[1]]
  if (!is.null(version)) {
    matches_version <- matches_name[which(!is.na(version_values[matches_name]) & version_values[matches_name] == version)]
    if (length(matches_version) == 0L) {
      return(NULL)
    }
    selected <- matches_version[[1]]
  }

  dataset_value <- dataset_values[[selected]]
  version_value <- version_values[[selected]]
  if (!is_scalar_character_value(dataset_value)) {
    return(NULL)
  }

  if (is_scalar_character_value(version_value)) {
    return(paste0(dataset_value, "@", version_value))
  }

  dataset_value
}

extract_rows_from_dataset_result <- function(result) {
  payloads <- result$payloads %||% list()
  arrow_payload_index <- which(vapply(payloads, function(p) identical(p$kind, "arrow_ipc"), logical(1)))[1]
  if (!is.na(arrow_payload_index)) {
    converted <- try(arrow_ipc_to_table(payloads[[arrow_payload_index]]), silent = TRUE)
    if (!inherits(converted, "try-error")) {
      return(as.data.frame(converted))
    }
  }

  normalize_dataset_records(result$data)
}

extract_rows_from_dataset_preview_result <- function(result) {
  payload <- result$object %||% result$data %||% result
  preview <- if (is.list(payload) && is.list(payload$preview)) payload$preview else payload

  if (is.list(preview) && is.list(preview$rows) && length(preview$rows) > 0L) {
    row_vectors <- lapply(preview$rows, function(row) {
      if (is.list(row)) {
        unlist(row, use.names = FALSE)
      } else {
        as.character(row)
      }
    })
    mat <- do.call(rbind, row_vectors)
    df <- as.data.frame(mat, stringsAsFactors = FALSE)

    if (is.list(preview$columns) && length(preview$columns) == ncol(df)) {
      col_names <- vapply(preview$columns, function(col) {
        if (is.list(col) && !is.null(col$name)) as.character(col$name[[1]]) else NA_character_
      }, character(1), USE.NAMES = FALSE)
      if (all(!is.na(col_names) & nzchar(col_names))) {
        names(df) <- col_names
      }
    }

    return(df)
  }

  if (is.list(preview) && is.list(preview$columns) && length(preview$columns) > 0L) {
    col_names <- vapply(preview$columns, function(col) {
      if (is.list(col) && !is.null(col$name)) as.character(col$name[[1]]) else NA_character_
    }, character(1), USE.NAMES = FALSE)
    if (all(!is.na(col_names) & nzchar(col_names))) {
      empty_cols <- replicate(length(col_names), character(0), simplify = FALSE)
      names(empty_cols) <- col_names
      return(as.data.frame(empty_cols, stringsAsFactors = FALSE))
    }
  }

  normalize_dataset_records(payload)
}

is_dataset_data_protocol_failure <- function(message) {
  if (!is.character(message) || length(message) == 0L) {
    return(FALSE)
  }
  grepl("request envelope is invalid", message[[1]], fixed = TRUE) ||
    grepl("protocol request kind is not supported", message[[1]], fixed = TRUE)
}

#' Read dataset rows with optional version preference
#'
#' @param ds DataStore object.
#' @param study_name Character study name.
#' @param dataset_name Character dataset asset name.
#' @param include_versions Logical; if `TRUE` search across all dataset versions.
#' @param version Optional dataset version label (for example `"1.2.3"` or
#'   `"v1_2_3"`). If omitted, the latest version is returned. If provided but
#'   not available, the latest available version is returned.
#'
#' @return A `data.frame` with dataset rows.
#' @export
read_dataset <- function(
  ds,
  study_name,
  dataset_name,
  include_versions = FALSE,
  version = NULL
) {
  validate_read_dataset_inputs(study_name, dataset_name, include_versions, version)
  client <- resolve_dataset_client(ds)

  preferred_reference <- select_version_reference(
    client = client,
    study_name = study_name,
    dataset_name = dataset_name,
    include_versions = include_versions,
    version = version
  )

  attempts <- unique(c(preferred_reference, dataset_name))
  errors <- character()

  for (dataset_ref in attempts) {
    if (!is_scalar_character_value(dataset_ref)) {
      next
    }

    result <- try(
      dataset_data(
        client,
        study = study_name,
        dataset = dataset_ref,
        limit = NULL,
        format = "json"
      ),
      silent = TRUE
    )

    if (inherits(result, "try-error")) {
      err_message <- as.character(result)
      errors <- c(errors, err_message)

      # Runtime compatibility fallback: preview can remain supported even when
      # full dataset.data transport is unavailable for this runtime/session.
      if (is_dataset_data_protocol_failure(err_message)) {
        preview_result <- try(
          dataset_preview(
            client,
            study = study_name,
            dataset = dataset_ref,
            limit = 100,
            format = "json"
          ),
          silent = TRUE
        )

        if (!inherits(preview_result, "try-error")) {
          rows <- preview_result$rows
          if (!is.data.frame(rows)) {
            rows <- extract_rows_from_dataset_preview_result(preview_result)
          }
          attr(rows, "study_name") <- study_name
          attr(rows, "dataset_name") <- dataset_name
          attr(rows, "dataset_reference") <- dataset_ref
          attr(rows, "read_mode") <- "preview"
          return(rows)
        }

        errors <- c(errors, as.character(preview_result))
      }

      next
    }

    rows <- extract_rows_from_dataset_result(result)
    attr(rows, "study_name") <- study_name
    attr(rows, "dataset_name") <- dataset_name
    attr(rows, "dataset_reference") <- dataset_ref
    return(rows)
  }

  abort_ahri_tre(
    paste0(
      "Failed to retrieve dataset '",
      dataset_name,
      "' for study '",
      study_name,
      "'. ",
      if (length(errors) > 0L) errors[[length(errors)]] else "No matching dataset reference could be resolved."
    ),
    class = "ahri_tre_dataset_retrieval_error"
  )
}