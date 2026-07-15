TRE_PROTOCOL_VERSION <- "1.0.0"
TRE_COMMAND_KIND_MAP <- list(
  "asset_delete" = "asset.delete",
  "asset_duo_clear" = "asset.duo.clear",
  "asset_duo_list" = "asset.duo.list",
  "asset_duo_replace" = "asset.duo.replace",
  "asset_get" = "asset.get",
  "asset_list" = "asset.list",
  "asset_versions" = "asset.versions",
  "auth_login" = "auth.login",
  "auth_logout" = "auth.logout",
  "auth_status" = "auth.status",
  "completion" = "completion",
  "daemon_doctor" = "daemon.doctor",
  "daemon_start" = "daemon.start",
  "daemon_status" = "daemon.status",
  "daemon_stop" = "daemon.stop",
  "daemon_version" = "daemon.version",
  "datafile_delete" = "datafile.delete",
  "datafile_export" = "datafile.export",
  "datafile_list" = "datafile.list",
  "datafile_metadata" = "datafile.metadata",
  "datafile_search" = "datafile.search",
  "dataset_data" = "dataset.data",
  "dataset_delete" = "dataset.delete",
  "dataset_export" = "dataset.export",
  "dataset_list" = "dataset.list",
  "dataset_metadata" = "dataset.metadata",
  "dataset_preview" = "dataset.preview",
  "dataset_search" = "dataset.search",
  "dataset_withdraw" = "dataset.withdraw",
  "datastore_adopt" = "datastore.adopt",
  "datastore_create" = "datastore.create",
  "datastore_info" = "datastore.info",
  "datastore_list" = "datastore.list",
  "datastore_ping" = "datastore.ping",
  "datastore_rotate" = "datastore.rotate-lake-credential",
  "datastore_schema" = "datastore.schema-status",
  "doctor" = "doctor",
  "domain_add" = "domain.add",
  "domain_delete" = "domain.delete",
  "domain_get" = "domain.get",
  "domain_list" = "domain.list",
  "entity_add" = "entity.add",
  "entity_delete" = "entity.delete",
  "entity_get" = "entity.get",
  "entity_instance_add" = "entity.instance.add",
  "entity_instance_asset_link_add" = "entity.instance.asset-link.add",
  "entity_instance_asset_link_list" = "entity.instance.asset-link.list",
  "entity_instance_dataset_link_add" = "entity.instance.dataset-link.add",
  "entity_instance_dataset_link_get" = "entity.instance.dataset-link.get",
  "entity_instance_dataset_link_list" = "entity.instance.dataset-link.list",
  "entity_instance_datasets" = "entity.instance.datasets",
  "entity_instance_ensure" = "entity.instance.ensure-from-dataset",
  "entity_instance_get" = "entity.instance.get",
  "entity_instance_list" = "entity.instance.list",
  "entity_instance_map_add" = "entity.instance.map.add",
  "entity_instance_map_get" = "entity.instance.map.get",
  "entity_instance_map_list" = "entity.instance.map.list",
  "entity_list" = "entity.list",
  "entity_relation_add" = "entity-relation.add",
  "entity_relation_delete" = "entity-relation.delete",
  "entity_relation_get" = "entity-relation.get",
  "entity_relation_instance_add" = "entity-relation.instance.add",
  "entity_relation_instance_asset_link_add" = "entity-relation.instance.asset-link.add",
  "entity_relation_instance_asset_link_list" = "entity-relation.instance.asset-link.list",
  "entity_relation_instance_dataset_link_add" = "entity-relation.instance.dataset-link.add",
  "entity_relation_instance_dataset_link_get" = "entity-relation.instance.dataset-link.get",
  "entity_relation_instance_dataset_link_list" = "entity-relation.instance.dataset-link.list",
  "entity_relation_instance_ensure" = "entity-relation.instance.ensure-from-dataset",
  "entity_relation_instance_get" = "entity-relation.instance.get",
  "entity_relation_instance_list" = "entity-relation.instance.list",
  "entity_relation_instance_map_add" = "entity-relation.instance.map.add",
  "entity_relation_instance_map_get" = "entity-relation.instance.map.get",
  "entity_relation_instance_map_list" = "entity-relation.instance.map.list",
  "entity_relation_list" = "entity-relation.list",
  "entity_relation_search" = "entity-relation.search",
  "entity_search" = "entity.search",
  "ingest_datafile" = "ingest.datafile",
  "ingest_dataset_datafile" = "ingest.dataset.from-datafile",
  "ingest_dataset_sql" = "ingest.dataset.from-sql",
  "ingest_dataset_table" = "ingest.dataset.table",
  "ingest_redcap_project" = "ingest.redcap.project",
  "schema_get" = "schema.get",
  "schema_list" = "schema.list",
  "session_close" = "session.close",
  "session_list" = "session.list",
  "session_open" = "session.open-oauth",
  "session_reopen" = "session.reopen",
  "session_status" = "session.status",
  "session_use" = "session.use",
  "study_access_grant" = "study.access.grant",
  "study_access_list" = "study.access.list",
  "study_access_revoke" = "study.access.revoke",
  "study_add" = "study.add",
  "study_add_domain" = "study.add-domain",
  "study_clear_current" = "study.clear-current",
  "study_context_list" = "study.context.list",
  "study_current" = "study.current",
  "study_custodians_add" = "study.custodians.add-delegate",
  "study_custodians_list" = "study.custodians.list",
  "study_custodians_remove" = "study.custodians.remove-delegate",
  "study_custodians_transfer" = "study.custodians.transfer-primary",
  "study_delete" = "study.delete",
  "study_duo_list" = "study.duo.list",
  "study_duo_replace" = "study.duo.replace",
  "study_get" = "study.get",
  "study_list" = "study.list",
  "study_search" = "study.search",
  "study_use" = "study.use",
  "tag_get" = "tag.get",
  "tag_list" = "tag.list",
  "tag_set" = "tag.set",
  "transformation_list" = "transformation.list",
  "variable_add" = "variable.add",
  "variable_delete" = "variable.delete",
  "variable_get" = "variable.get",
  "variable_list" = "variable.list",
  "variable_search" = "variable.search",
  "variable_update" = "variable.update",
  "version" = "version",
  "vocabulary_add" = "vocabulary.add",
  "vocabulary_delete" = "vocabulary.delete",
  "vocabulary_get" = "vocabulary.get",
  "vocabulary_list" = "vocabulary.list"
)

compact_null_fields <- function(x) {
  if (length(x) == 0L) {
    return(list())
  }
  x[!vapply(x, is.null, logical(1))]
}

merge_request_body <- function(auto_fields = list(), dot_fields = list(), explicit_body = NULL) {
  if (!is.null(explicit_body)) {
    return(explicit_body)
  }

  body <- compact_null_fields(auto_fields)
  dots <- compact_null_fields(dot_fields)
  if (length(dots) == 0L) {
    return(body)
  }

  named <- names(dots)
  if (is.null(named)) {
    return(c(body, dots))
  }

  for (i in seq_along(dots)) {
    key <- names(dots)[[i]]
    if (is.null(key) || !nzchar(key)) {
      next
    }
    body[[key]] <- dots[[i]]
  }
  body
}

new_tre_protocol_request <- function(kind, body = list(), protocol_version = TRE_PROTOCOL_VERSION) {
  list(
    protocol_version = protocol_version,
    kind = kind,
    body = body %||% list()
  )
}

tre_result_ok <- function(envelope) {
  ok <- envelope$ok
  if (is.logical(ok) && length(ok) == 1L) {
    return(isTRUE(ok))
  }
  is.null(envelope$error) && is.null(envelope$failure)
}

tre_extract_data <- function(envelope) {
  for (key in c("data", "result", "output", "body")) {
    if (!is.null(envelope[[key]])) {
      return(envelope[[key]])
    }
  }
  envelope
}

tre_is_invalid_request_envelope <- function(envelope) {
  if (is.null(envelope) || !is.list(envelope)) {
    return(FALSE)
  }
  if (!identical(envelope$kind %||% "", "protocol.invalid_request")) {
    return(FALSE)
  }
  message <- envelope$error$message %||% envelope$message %||% ""
  grepl("request envelope is invalid", message, fixed = TRUE)
}

tre_is_no_live_session_envelope <- function(envelope) {
  if (is.null(envelope) || !is.list(envelope)) {
    return(FALSE)
  }
  message <- envelope$error$message %||% envelope$message %||% ""
  grepl("no live session is selected", message, fixed = TRUE)
}

tre_is_daemon_connection_envelope <- function(envelope) {
  if (is.null(envelope) || !is.list(envelope)) {
    return(FALSE)
  }
  message <- envelope$error$message %||% envelope$message %||% ""
  any(vapply(
    c(
      "daemon closed the protocol connection",
      "daemon socket",
      "stale"
    ),
    function(p) grepl(p, message, fixed = TRUE),
    logical(1)
  ))
}

tre_auto_session_enabled <- function() {
  flag <- tolower(Sys.getenv("AHRI_TRE_AUTO_SESSION_USE", unset = "true"))
  !flag %in% c("0", "false", "no", "off")
}

tre_cli_binary <- function() {
  runtime_root <- Sys.getenv("AHRI_TRE_RUNTIME_ROOT", unset = "")
  if (!nzchar(runtime_root)) {
    runtime_root <- "/opt/ahri-tre-runtime"
  }
  path <- file.path(normalizePath(path.expand(runtime_root), mustWork = FALSE), "bin", "ahri-tre")
  if (!file.exists(path)) {
    return(NULL)
  }
  path
}

tre_parse_first_json_object <- function(lines) {
  if (length(lines) == 0L) {
    return(NULL)
  }
  text <- paste(lines, collapse = "\n")
  start <- regexpr("\\{", text)
  if (start[[1]] < 1L) {
    return(NULL)
  }
  json_text <- substr(text, start[[1]], nchar(text))
  parsed <- try(jsonlite::fromJSON(json_text, simplifyVector = FALSE), silent = TRUE)
  if (inherits(parsed, "try-error")) {
    return(NULL)
  }
  parsed
}

tre_cli_args_from_body <- function(kind, body) {
  tokens <- strsplit(kind, "\\.", fixed = FALSE)[[1]]
  args <- as.list(tokens)

  if (length(body) == 0L) {
    return(unlist(args, use.names = FALSE))
  }

  for (key in names(body)) {
    value <- body[[key]]
    if (is.null(value)) {
      next
    }

    cli_key <- gsub("_", "-", key, fixed = TRUE)
    flag <- paste0("--", cli_key)

    if (is.logical(value) && length(value) == 1L) {
      if (isTRUE(value)) {
        args <- c(args, flag)
      }
      next
    }

    if (length(value) == 0L || is.list(value)) {
      next
    }

    for (item in as.character(value)) {
      args <- c(args, flag, item)
    }
  }

  unlist(args, use.names = FALSE)
}

tre_execute_via_cli <- function(kind, body) {
  cli_bin <- tre_cli_binary()
  if (is.null(cli_bin)) {
    return(NULL)
  }

  runtime_root <- Sys.getenv("AHRI_TRE_RUNTIME_ROOT", unset = "")
  if (!nzchar(runtime_root)) {
    runtime_root <- "/opt/ahri-tre-runtime"
  }

  runtime_lib <- file.path(normalizePath(path.expand(runtime_root), mustWork = FALSE), "lib")
  ld_path <- Sys.getenv("LD_LIBRARY_PATH", unset = "")
  env <- c(paste0("LD_LIBRARY_PATH=", paste(c(runtime_lib, ld_path), collapse = ":")))
  args <- tre_cli_args_from_body(kind, body)

  output <- suppressWarnings(system2(cli_bin, args = args, stdout = TRUE, stderr = TRUE, env = env))
  parsed <- tre_parse_first_json_object(output)
  if (is.null(parsed)) {
    return(NULL)
  }

  if (isTRUE(parsed$ok)) {
    envelope <- list(ok = TRUE, kind = parsed$command %||% kind, data = parsed$data %||% list())
  } else {
    message <- parsed$error$message %||% parsed$message %||% "CLI command failed"
    envelope <- list(
      ok = FALSE,
      kind = parsed$command %||% kind,
      error = list(code = parsed$code %||% "cli_error", message = message)
    )
  }

  list(envelope = envelope, payloads = list())
}

tre_cli_try_activate_live_session <- function() {
  cli_bin <- tre_cli_binary()
  if (is.null(cli_bin)) {
    return(FALSE)
  }

  runtime_root <- Sys.getenv("AHRI_TRE_RUNTIME_ROOT", unset = "")
  if (!nzchar(runtime_root)) {
    runtime_root <- "/opt/ahri-tre-runtime"
  }
  runtime_lib <- file.path(normalizePath(path.expand(runtime_root), mustWork = FALSE), "lib")
  ld_path <- Sys.getenv("LD_LIBRARY_PATH", unset = "")
  env <- c(paste0("LD_LIBRARY_PATH=", paste(c(runtime_lib, ld_path), collapse = ":")))

  sessions_out <- suppressWarnings(system2(
    cli_bin,
    args = c("session", "list", "--format", "json"),
    stdout = TRUE,
    stderr = TRUE,
    env = env
  ))
  sessions_json <- tre_parse_first_json_object(sessions_out)
  if (is.null(sessions_json) || !isTRUE(sessions_json$ok)) {
    return(FALSE)
  }

  sessions <- sessions_json$data$sessions
  if (is.null(sessions) || length(sessions) == 0L) {
    return(FALSE)
  }

  session_name <- NULL
  for (s in sessions) {
    if (identical(s$availability %||% "", "live")) {
      session_name <- s$session$name %||% NULL
      if (is.character(session_name) && nzchar(session_name)) {
        break
      }
      session_name <- NULL
    }
  }

  if (is.null(session_name)) {
    for (s in sessions) {
      name <- s$session$name %||% NULL
      mode <- s$auth_mode %||% ""
      availability <- s$availability %||% ""
      if (!is.character(name) || !nzchar(name)) {
        next
      }
      if (identical(availability, "live") || !grepl("oauth", mode, ignore.case = TRUE)) {
        next
      }

      reopen_out <- suppressWarnings(system2(
        cli_bin,
        args = c("session", "reopen", name, "--format", "json"),
        stdout = TRUE,
        stderr = TRUE,
        env = env
      ))
      reopen_json <- tre_parse_first_json_object(reopen_out)
      if (isTRUE(reopen_json$ok)) {
        session_name <- name
        break
      }
    }

    if (is.null(session_name)) {
      return(FALSE)
    }
  }

  use_out <- suppressWarnings(system2(
    cli_bin,
    args = c("session", "use", session_name, "--format", "json"),
    stdout = TRUE,
    stderr = TRUE,
    env = env
  ))
  use_json <- tre_parse_first_json_object(use_out)
  isTRUE(use_json$ok)
}

tre_cli_try_restart_daemon <- function() {
  cli_bin <- tre_cli_binary()
  if (is.null(cli_bin)) {
    return(FALSE)
  }

  runtime_root <- Sys.getenv("AHRI_TRE_RUNTIME_ROOT", unset = "")
  if (!nzchar(runtime_root)) {
    runtime_root <- "/opt/ahri-tre-runtime"
  }
  runtime_lib <- file.path(normalizePath(path.expand(runtime_root), mustWork = FALSE), "lib")
  ld_path <- Sys.getenv("LD_LIBRARY_PATH", unset = "")
  env <- c(paste0("LD_LIBRARY_PATH=", paste(c(runtime_lib, ld_path), collapse = ":")))

  start_out <- suppressWarnings(system2(
    cli_bin,
    args = c("daemon", "start", "--format", "json"),
    stdout = TRUE,
    stderr = TRUE,
    env = env
  ))
  start_json <- tre_parse_first_json_object(start_out)
  isTRUE(start_json$ok)
}

tre_normalize_output <- function(result, output_label = NULL, status_and_purpose = NULL, function_name = NULL) {
  envelope <- result$envelope %||% list()
  if (!tre_result_ok(envelope)) {
    failure <- protocol_failure_summary(envelope)
    abort_ahri_tre(
      sprintf("%s failed: %s", function_name %||% "TRE command", failure$message),
      class = "ahri_tre_protocol_error"
    )
  }

  structure(
    list(
      function_name = function_name,
      output_label = output_label,
      status_and_purpose = status_and_purpose,
      data = tre_extract_data(envelope),
      envelope = envelope,
      payloads = result$payloads %||% list()
    ),
    class = "ahri_tre_wrapper_result"
  )
}

tre_command_call <- function(
  client,
  kind,
  ...,
  .auto_fields = list(),
  .body = NULL,
  .protocol_version = TRE_PROTOCOL_VERSION,
  .output_label = NULL,
  .status_and_purpose = NULL,
  .function_name = NULL
) {
  body <- merge_request_body(
    auto_fields = .auto_fields,
    dot_fields = list(...),
    explicit_body = .body
  )

  request <- new_tre_protocol_request(
    kind = kind,
    body = body,
    protocol_version = .protocol_version
  )

  result <- execute_json(client = client, request = request)
  used_cli <- FALSE

  if (tre_is_invalid_request_envelope(result$envelope %||% list())) {
    cli_result <- tre_execute_via_cli(kind = kind, body = body)
    if (!is.null(cli_result)) {
      result <- cli_result
      used_cli <- TRUE
    }
  }

  if (tre_auto_session_enabled() && tre_is_no_live_session_envelope(result$envelope %||% list())) {
    if (tre_cli_try_activate_live_session()) {
      if (isTRUE(used_cli)) {
        cli_result <- tre_execute_via_cli(kind = kind, body = body)
        if (!is.null(cli_result)) {
          result <- cli_result
        }
      } else {
        result <- execute_json(client = client, request = request)
        if (tre_is_invalid_request_envelope(result$envelope %||% list())) {
          cli_result <- tre_execute_via_cli(kind = kind, body = body)
          if (!is.null(cli_result)) {
            result <- cli_result
          }
        }
      }
    }
  }

  if (tre_is_no_live_session_envelope(result$envelope %||% list())) {
    cli_result <- tre_execute_via_cli(kind = kind, body = body)
    if (!is.null(cli_result)) {
      result <- cli_result
      used_cli <- TRUE
    }
  }

  if (tre_auto_session_enabled() && tre_is_daemon_connection_envelope(result$envelope %||% list())) {
    if (tre_cli_try_restart_daemon()) {
      if (isTRUE(used_cli)) {
        cli_result <- tre_execute_via_cli(kind = kind, body = body)
        if (!is.null(cli_result)) {
          result <- cli_result
        }
      } else {
        result <- execute_json(client = client, request = request)
        if (tre_is_invalid_request_envelope(result$envelope %||% list())) {
          cli_result <- tre_execute_via_cli(kind = kind, body = body)
          if (!is.null(cli_result)) {
            result <- cli_result
          }
        }
      }
    }
  }

  tre_normalize_output(
    result = result,
    output_label = .output_label,
    status_and_purpose = .status_and_purpose,
    function_name = .function_name
  )
}


