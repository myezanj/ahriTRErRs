AhriTreClient <- function(api = CApi(), runtime_config = RuntimeConfig(), check_compatibility = TRUE) {
  if (isTRUE(check_compatibility)) {
    check_protocol_compatibility(api)
  }
  created <- ahri_tre_client_create_bridge(
    api$library_path,
    runtime_config$daemon_endpoint,
    runtime_config$daemon_binary,
    as.integer(runtime_config$readiness_timeout_ms),
    isTRUE(runtime_config$never_start)
  )
  check_abi_status(created$status, api)
  client <- list(api = api, handle = created$client)
  class(client) <- "ahri_tre_client"
  reg.finalizer(client$handle, function(handle) {
    # The handle may already be freed explicitly via close().
    try(ahri_tre_client_free_bridge(api$library_path, handle), silent = TRUE)
  }, onexit = TRUE)
  client
}

#' @export
#' @method close ahri_tre_client
close.ahri_tre_client <- function(con, ...) {
  try(ahri_tre_client_free_bridge(con$api$library_path, con$handle), silent = TRUE)
  invisible(NULL)
}

execute_json <- function(client, request) {
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

protocol_failure_summary <- function(envelope) {
  status <- envelope$status %||% envelope$kind %||% "unknown"
  error <- envelope$error %||% envelope$failure %||% list()
  message <- error$message %||% envelope$message %||% "protocol request failed"
  code <- error$code %||% envelope$code %||% NA_character_
  list(status = status, code = code, message = message)
}

request_bytes <- function(request) {
  if (is.raw(request)) {
    return(request)
  }
  if (is.character(request) && length(request) == 1L) {
    return(charToRaw(enc2utf8(request)))
  }
  charToRaw(jsonlite::toJSON(request, auto_unbox = TRUE, null = "null"))
}
