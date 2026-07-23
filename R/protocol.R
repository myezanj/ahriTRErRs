#' Check if client handle is valid
#'
#' @param handle External pointer
#' @return Logical
#' @noRd
tre_client_handle_is_valid <- function(handle) {
  identical(typeof(handle), "externalptr") && !identical(handle, new("externalptr"))
}

#' Create AHRI TRE client
#'
#' @param api C API object
#' @param runtime_config Runtime config
#' @param check_compatibility Check protocol compatibility
#' @return AhriTreClient object
#' @export
AhriTreClient <- function(api = CApi(), runtime_config = RuntimeConfig(), check_compatibility = TRUE) {
  if (isTRUE(check_compatibility)) {
    check_protocol_compatibility(api)
  }

  if (!tre_client_handle_is_valid(api$handle)) {
    abort_ahri_tre(
      "API handle is invalid",
      class = "ahri_tre_client_create_error"
    )
  }

  created <- tre_with_runtime_library_path(api, ahri_tre_client_create_bridge(
    api$library_path,
    runtime_config$daemon_endpoint,
    runtime_config$daemon_binary,
    as.integer(runtime_config$readiness_timeout_ms),
    isTRUE(runtime_config$never_start)
  ))

  check_abi_status(created$status, api)

  if (!tre_client_handle_is_valid(created$client)) {
    abort_ahri_tre(
      "AHRI TRE client handle could not be created; ensure the runtime and daemon are available, then create a new AhriTreClient().",
      class = "ahri_tre_client_create_error"
    )
  }

  client <- list(api = api, handle = created$client)
  class(client) <- "ahri_tre_client"

  reg.finalizer(client$handle, function(handle) {
    if (tre_client_handle_is_valid(handle)) {
      try(ahri_tre_client_free_bridge(api$library_path, handle), silent = TRUE)
    }
  }, onexit = TRUE)

  client
}

#' Close AHRI TRE client
#'
#' @param con Client to close
#' @param ... Additional arguments
#' @return NULL
#' @export
#' @method close ahri_tre_client
close.ahri_tre_client <- function(con, ...) {
  if (tre_client_handle_is_valid(con$handle)) {
    try(ahri_tre_client_free_bridge(con$api$library_path, con$handle), silent = TRUE)
  }
  invisible(NULL)
}

#' Execute JSON protocol request
#'
#' @param client AhriTreClient object
#' @param request Request object
#' @return Protocol result
#' @export
execute_json <- function(client, request) {
  if (!tre_client_handle_is_valid(client$handle)) {
    abort_ahri_tre(
      "AHRI TRE client handle is closed or invalid; create a new AhriTreClient().",
      class = "ahri_tre_client_state_error"
    )
  }

  data <- request_bytes(request)
  executed <- ahri_tre_client_execute_protocol_json_bridge(
    client$api$library_path,
    client$handle,
    data
  )
  check_abi_status(executed$status, client$api)
  result <- executed$result
  on.exit(result_free(client$api, result), add = TRUE)
  envelope <- result_json(client$api, result)
  payloads <- payloads_from_result(client$api, result)

  structure(
    list(envelope = envelope, payloads = payloads),
    class = "ahri_tre_protocol_result"
  )
}

#' Summarize protocol failure
#'
#' @param envelope Response envelope
#' @return Failure summary
#' @export
protocol_failure_summary <- function(envelope) {
  status <- envelope$status %||% envelope$kind %||% "unknown"
  error <- envelope$error %||% envelope$failure %||% list()
  message <- error$message %||% envelope$message %||% "protocol request failed"
  code <- error$code %||% envelope$code %||% NA_character_
  list(status = status, code = code, message = message)
}

#' Convert request to bytes
#'
#' @param request Request object
#' @return Raw bytes
#' @noRd
request_bytes <- function(request) {
  if (is.raw(request)) {
    return(request)
  }
  if (is.character(request) && length(request) == 1L) {
    return(charToRaw(enc2utf8(request)))
  }
  charToRaw(jsonlite::toJSON(request, auto_unbox = TRUE, null = "null"))
}