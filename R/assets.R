# Auto-generated command wrappers for Assets, Datafiles, Datasets

asset_delete <- function(client, study = NULL, name = NULL, reason = NULL, actor = NULL, cascade = NULL, force = NULL, dry_run = NULL, yes = NULL, format = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
    "study" = study,
    "name" = name,
    "reason" = reason,
    "actor" = actor,
    "cascade" = cascade,
    "force" = force,
    "dry-run" = dry_run,
    "yes" = yes,
    "format" = format
  )
  tre_command_call(
    client = client,
    kind = "asset.delete",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Archive/delete plan or result",
    .status_and_purpose = "Delete all versions of a supported asset through archive/delete policy; requires primary or delegate study custodianship.",
    .function_name = "asset_delete"
  )
}

asset_duo_clear <- function(client, study = NULL, asset = NULL, version = NULL, format = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
    "study" = study,
    "asset" = asset,
    "version" = version,
    "format" = format
  )
  tre_command_call(
    client = client,
    kind = "asset.duo.clear",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Asset-version DUO clear result",
    .status_and_purpose = "Remove explicit DUO overrides for one asset version so effective readback can fall back to study defaults.",
    .function_name = "asset_duo_clear"
  )
}

asset_duo_list <- function(client, study = NULL, asset = NULL, version = NULL, effective = NULL, format = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
    "study" = study,
    "asset" = asset,
    "version" = version,
    "effective" = effective,
    "format" = format
  )
  tre_command_call(
    client = client,
    kind = "asset.duo.list",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Asset-version DUO restriction list",
    .status_and_purpose = "List explicit DUO restrictions for one asset version, or effective restrictions with source values when?--effective?is set.",
    .function_name = "asset_duo_list"
  )
}

asset_duo_replace <- function(client, study = NULL, asset = NULL, version = NULL, restrictions = NULL, format = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
    "study" = study,
    "asset" = asset,
    "version" = version,
    "restrictions" = restrictions,
    "format" = format
  )
  tre_command_call(
    client = client,
    kind = "asset.duo.replace",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Asset-version DUO replacement result",
    .status_and_purpose = "Replace the explicit DUO override set for one asset version; empty arrays are rejected in favor of?asset duo clear.",
    .function_name = "asset_duo_replace"
  )
}

asset_get <- function(client, study = NULL, name = NULL, type = NULL, format = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
    "study" = study,
    "name" = name,
    "type" = type,
    "format" = format
  )
  tre_command_call(
    client = client,
    kind = "asset.get",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Asset record",
    .status_and_purpose = "Fetch one asset.",
    .function_name = "asset_get"
  )
}

asset_list <- function(client, study = NULL, type = NULL, format = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
    "study" = study,
    "type" = type,
    "format" = format
  )
  tre_command_call(
    client = client,
    kind = "asset.list",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Asset list",
    .status_and_purpose = "List assets in the resolved study.",
    .function_name = "asset_list"
  )
}

asset_versions <- function(client, study = NULL, asset = NULL, type = NULL, format = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
    "study" = study,
    "asset" = asset,
    "type" = type,
    "format" = format
  )
  tre_command_call(
    client = client,
    kind = "asset.versions",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Asset-version list",
    .status_and_purpose = "List versions of one asset.",
    .function_name = "asset_versions"
  )
}

datafile_delete <- function(client, study = NULL, asset = NULL, version = NULL, reason = NULL, actor = NULL, cascade = NULL, force = NULL, dry_run = NULL, yes = NULL, format = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
    "study" = study,
    "asset" = asset,
    "version" = version,
    "reason" = reason,
    "actor" = actor,
    "cascade" = cascade,
    "force" = force,
    "dry-run" = dry_run,
    "yes" = yes,
    "format" = format
  )
  tre_command_call(
    client = client,
    kind = "datafile.delete",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Archive/delete plan or result",
    .status_and_purpose = "Delete a datafile version or whole datafile asset with managed payload cleanup; requires primary or delegate study custodianship.",
    .function_name = "datafile_delete"
  )
}

datafile_export <- function(client, study = NULL, asset = NULL, version = NULL, to = NULL, overwrite = NULL, format = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
    "study" = study,
    "asset" = asset,
    "version" = version,
    "to" = to,
    "overwrite" = overwrite,
    "format" = format
  )
  tre_command_call(
    client = client,
    kind = "datafile.export",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Export status",
    .status_and_purpose = "Copy a managed datafile payload to a requested path.",
    .function_name = "datafile_export"
  )
}

datafile_list <- function(client, study = NULL, include_versions = NULL, format = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
    "study" = study,
    "include-versions" = include_versions,
    "format" = format
  )
  tre_command_call(
    client = client,
    kind = "datafile.list",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Datafile asset list",
    .status_and_purpose = "List managed datafile assets and optionally their versions.",
    .function_name = "datafile_list"
  )
}

datafile_metadata <- function(client, study = NULL, asset = NULL, version = NULL, format = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
    "study" = study,
    "asset" = asset,
    "version" = version,
    "format" = format
  )
  tre_command_call(
    client = client,
    kind = "datafile.metadata",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Datafile metadata",
    .status_and_purpose = "Show one datafile asset/version.",
    .function_name = "datafile_metadata"
  )
}

datafile_search <- function(client, study = NULL, cursor = NULL, limit = NULL, width = NULL, format = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
    "study" = study,
    "cursor" = cursor,
    "limit" = limit,
    "width" = width,
    "format" = format
  )
  tre_command_call(
    client = client,
    kind = "datafile.search",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Datafile search results",
    .status_and_purpose = "Search bounded datafile catalog summaries without reading file payloads.",
    .function_name = "datafile_search"
  )
}

normalize_dataset_data_records <- function(value) {
  # Keep row coercion behavior consistent across dataset wrappers.
  normalize_dataset_records(value)
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

extract_dataset_data_rows <- function(result) {
  payloads <- result$payloads %||% list()
  arrow_payload_index <- which(vapply(payloads, function(p) identical(p$kind, "arrow_ipc"), logical(1)))[1]

  if (!is.na(arrow_payload_index)) {
    converted <- try(arrow_ipc_to_table(payloads[[arrow_payload_index]]), silent = TRUE)
    if (!inherits(converted, "try-error")) {
      return(as.data.frame(converted))
    }
  }

  normalize_dataset_data_records(result$data)
}

extract_dataset_preview_rows <- function(result) {
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

  normalize_dataset_data_records(payload)
}

dataset_data <- function(client, study = NULL, dataset = NULL, limit = NULL, to = NULL, format = "json", compress = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
    "study" = study,
    "dataset" = dataset,
    "limit" = limit,
    "to" = to,
    "format" = format,
    "compress" = compress
  )
  result <- tre_command_call(
    client = client,
    kind = "dataset.data",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Tabular data stream or export file",
    .status_and_purpose = "Read or export dataset data.",
    .function_name = "dataset_data"
  )

  # Ensure dataset rows are directly retrievable from wrapper output.
  result$rows <- extract_dataset_data_rows(result)
  result
}

dataset_delete <- function(client, study = NULL, dataset = NULL, version = NULL, reason = NULL, actor = NULL, cascade = NULL, force = NULL, dry_run = NULL, yes = NULL, format = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
    "study" = study,
    "dataset" = dataset,
    "version" = version,
    "reason" = reason,
    "actor" = actor,
    "cascade" = cascade,
    "force" = force,
    "dry-run" = dry_run,
    "yes" = yes,
    "format" = format
  )
  tre_command_call(
    client = client,
    kind = "dataset.delete",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Archive/delete plan or result",
    .status_and_purpose = "Delete a dataset version or whole dataset asset with mandatory lake table cleanup; requires primary or delegate study custodianship.",
    .function_name = "dataset_delete"
  )
}

dataset_export <- function(client, study = NULL, dataset = NULL, limit = NULL, to = NULL, format = NULL, compress = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
    "study" = study,
    "dataset" = dataset,
    "limit" = limit,
    "to" = to,
    "format" = format,
    "compress" = compress
  )
  tre_command_call(
    client = client,
    kind = "dataset.export",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Export file",
    .status_and_purpose = "Export dataset rows to a file or directory-derived file.",
    .function_name = "dataset_export"
  )
}

dataset_list <- function(client, study = NULL, include_versions = NULL, format = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
    "study" = study,
    "include-versions" = include_versions,
    "format" = format
  )
  tre_command_call(
    client = client,
    kind = "dataset.list",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Dataset list",
    .status_and_purpose = "List dataset assets and optionally their versions.",
    .function_name = "dataset_list"
  )
}

dataset_metadata <- function(client, study = NULL, dataset = NULL, with_variables = NULL, format = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
    "study" = study,
    "dataset" = dataset,
    "with-variables" = with_variables,
    "format" = format
  )
  tre_command_call(
    client = client,
    kind = "dataset.metadata",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Dataset metadata",
    .status_and_purpose = "Show dataset metadata and variable count;?--with-variables?includes variable definitions.",
    .function_name = "dataset_metadata"
  )
}

dataset_preview <- function(client, study = NULL, dataset = NULL, limit = NULL, width = NULL, format = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
    "study" = study,
    "dataset" = dataset,
    "limit" = limit,
    "width" = width,
    "format" = format
  )
  result <- tre_command_call(
    client = client,
    kind = "dataset.preview",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Text or JSON row preview",
    .status_and_purpose = "Preview dataset rows.",
    .function_name = "dataset_preview"
  )

  # Keep row extraction behavior consistent with dataset_data.
  result$rows <- extract_dataset_preview_rows(result)
  result
}

dataset_search <- function(client, study = NULL, cursor = NULL, limit = NULL, width = NULL, format = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
    "study" = study,
    "cursor" = cursor,
    "limit" = limit,
    "width" = width,
    "format" = format
  )
  tre_command_call(
    client = client,
    kind = "dataset.search",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Dataset search results",
    .status_and_purpose = "Search bounded dataset catalog summaries; row filtering stays in dataset data/preview/export paths.",
    .function_name = "dataset_search"
  )
}

dataset_withdraw <- function(client, study = NULL, dataset = NULL, version = NULL, reason = NULL, actor = NULL, force = NULL, drop_lake_table = NULL, format = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
    "study" = study,
    "dataset" = dataset,
    "version" = version,
    "reason" = reason,
    "actor" = actor,
    "force" = force,
    "drop-lake-table" = drop_lake_table,
    "format" = format
  )
  tre_command_call(
    client = client,
    kind = "dataset.withdraw",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Withdrawal result",
    .status_and_purpose = "Withdraw one faulty dataset version with audited provenance; requires primary or delegate study custodianship.",
    .function_name = "dataset_withdraw"
  )
}


