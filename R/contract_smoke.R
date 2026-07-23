#' Contract Smoke Test
#'
#' Performs a comprehensive integration test against a live runtime:
#' - loads the C ABI
#' - checks compatibility
#' - starts/ensures the daemon
#' - executes two protocol requests (one success, one failure)
#' - stops the daemon
#' - returns a diagnostic report with redacted sensitive information.
#'
#' @name contract_smoke
NULL

SMOKE_PROTOCOL_VERSION <- "1.0.0"
SMOKE_SUCCESS_KIND <- "session.list"
SMOKE_FAILURE_KIND <- "binding.contract_smoke.unsupported"
REDACTED <- "<redacted>"
SENSITIVE_DIAGNOSTIC_KEYS <- c(
  "body", "cache_file", "connection_string", "daemon_binary",
  "daemon_endpoint", "lake", "lake_data", "lake_db", "password",
  "path", "raw_request", "request", "root", "secret", "socket", "token"
)

#' Run the contract smoke test
#'
#' @param runtime_root Character. Explicit runtime root path (optional).
#' @param stop_runtime Logical. If `TRUE`, stop the daemon after the test.
#' @param readiness_timeout_ms Integer. Timeout for daemon readiness.
#' @return A report object of class `ahri_tre_contract_smoke_report`.
#' @export
#' @examples
#' \dontrun{
#' report <- run_contract_smoke()
#' print(report$compatibility)
#' }
run_contract_smoke <- function(
  runtime_root = NULL,
  stop_runtime = TRUE,
  readiness_timeout_ms = 30000L
) {
  artifact <- discover_runtime_artifact(runtime_root)
  api <- CApi(artifact = artifact)
  compatibility <- check_protocol_compatibility(api)
  runtime_config <- RuntimeConfig(
    daemon_binary = runtime_daemon_binary(artifact),
    readiness_timeout_ms = readiness_timeout_ms
  )

  runtime_status_value <- safe_lifecycle_summary(runtime_status(api, runtime_config))
  daemon_discovery <- safe_lifecycle_summary(runtime_discover_daemon_binary(api, runtime_config))
  runtime_ensure_value <- safe_lifecycle_summary(runtime_ensure(api, runtime_config))

  client <- AhriTreClient(api = api, runtime_config = runtime_config)
  on.exit(close(client), add = TRUE)
  success <- execute_json(client, smoke_success_request())
  failure <- execute_json(client, smoke_failure_request())

  first_stop <- if (isTRUE(stop_runtime)) {
    safe_lifecycle_summary(runtime_stop(api, runtime_config))
  } else {
    list(skipped = TRUE)
  }
  second_stop <- if (isTRUE(stop_runtime)) {
    safe_lifecycle_summary(runtime_stop(api, runtime_config))
  } else {
    list(skipped = TRUE)
  }

  if (!protocol_result_is_failure(failure)) {
    abort_ahri_tre(
      "unsupported smoke request did not return a protocol failure envelope",
      class = "ahri_tre_contract_smoke_error"
    )
  }

  structure(
    list(
      artifact = list(
        source = if (is.null(runtime_root)) "AHRI_TRE_RUNTIME_ROOT" else "runtime_root",
        manifest_schema_version = artifact$manifest$schema_version %||% NULL,
        package_version = artifact$manifest$package_version %||% artifact$manifest$workspace_version %||% NULL,
        target = artifact$manifest$target %||% NULL,
        paths = REDACTED
      ),
      compatibility = compatibility_summary(compatibility),
      runtime = list(
        status = runtime_status_value,
        daemon_discovery = daemon_discovery,
        ensure = runtime_ensure_value,
        stop = first_stop,
        stop_idempotent = second_stop
      ),
      protocol = list(
        success_kind = SMOKE_SUCCESS_KIND,
        success = safe_envelope_summary(success$envelope),
        failure_kind = SMOKE_FAILURE_KIND,
        failure = protocol_failure_summary(failure$envelope)
      ),
      payloads = payload_smoke_summary(success)
    ),
    class = "ahri_tre_contract_smoke_report"
  )
}

#' Create a success request for smoke test
#' @noRd
smoke_success_request <- function() {
  list(
    protocol_version = SMOKE_PROTOCOL_VERSION,
    kind = SMOKE_SUCCESS_KIND,
    body = list(include_unavailable = TRUE)
  )
}

#' Create a failure request for smoke test
#' @noRd
smoke_failure_request <- function() {
  list(
    protocol_version = SMOKE_PROTOCOL_VERSION,
    kind = SMOKE_FAILURE_KIND,
    body = list()
  )
}

#' Summarize payloads from smoke test
#' @noRd
payload_smoke_summary <- function(result) {
  payloads <- result$payloads %||% list()
  if (length(payloads) == 0L) {
    return(list(
      count = 0L,
      arrow_ipc = "not returned by this protocol smoke request",
      dataframe_conversion = "covered by external binding tests with tabular fixtures"
    ))
  }
  list(
    count = length(payloads),
    descriptors = lapply(payloads, function(payload) {
      redact_diagnostics(list(
        kind = payload$kind,
        protocol_ref = payload$protocol_ref,
        media_type = payload$media_type,
        suggested_name = payload$suggested_name,
        size_bytes = payload$size_bytes,
        bytes_available = !is.null(payload$data)
      ))
    })
  )
}

#' Redact sensitive information from diagnostic output
#' @noRd
redact_diagnostics <- function(value) {
  if (is.list(value)) {
    result <- lapply(names(value), function(name) {
      if (diagnostic_key_is_sensitive(name)) {
        REDACTED
      } else {
        redact_diagnostics(value[[name]])
      }
    })
    names(result) <- names(value)
    return(result)
  }
  if (is.character(value)) {
    return(ifelse(vapply(value, looks_path_or_secret, logical(1)), REDACTED, value))
  }
  value
}

#' Summarize compatibility info
#' @noRd
compatibility_summary <- function(compatibility) {
  list(
    abi_version = compatibility$abi_version,
    library_version = compatibility$library_version,
    protocol_version = compatibility$protocol_version,
    runtime_minimum = compatibility$protocol_minimum,
    runtime_maximum = compatibility$protocol_maximum,
    runtime_rule = compatibility$protocol_rule
  )
}

#' Safely summarize a lifecycle envelope
#' @noRd
safe_lifecycle_summary <- function(envelope) {
  keys <- c("schema", "schema_version", "kind", "status", "action", "message", "diagnostics")
  redact_diagnostics(envelope[intersect(keys, names(envelope))])
}

#' Safely summarize a protocol envelope
#' @noRd
safe_envelope_summary <- function(envelope) {
  redact_diagnostics(list(
    ok = envelope$ok %||% NULL,
    status = envelope$status %||% NULL,
    kind = envelope$kind %||% NULL,
    protocol_version = envelope$protocol_version %||% NULL,
    request_id = envelope$request_id %||% NULL
  ))
}

#' Check if a protocol result indicates failure
#' @noRd
protocol_result_is_failure <- function(result) {
  ok <- result$envelope$ok
  if (is.logical(ok) && length(ok) == 1L) {
    return(!ok)
  }
  !is.null(result$envelope$error) || !is.null(result$envelope$failure)
}

#' Check if a diagnostic key is sensitive
#' @noRd
diagnostic_key_is_sensitive <- function(name) {
  key <- tolower(name)
  any(vapply(SENSITIVE_DIAGNOSTIC_KEYS, function(sensitive) {
    grepl(sensitive, key, fixed = TRUE)
  }, logical(1)))
}

#' Check if a string looks like a path or secret
#' @noRd
looks_path_or_secret <- function(value) {
  lower <- tolower(value)
  grepl("password=", lower, fixed = TRUE) ||
    grepl("token=", lower, fixed = TRUE) ||
    grepl("bearer ", lower, fixed = TRUE) ||
    startsWith(value, "/") ||
    startsWith(value, "~") ||
    grepl(":/", value, fixed = TRUE) ||
    grepl("\\\\", value)
}