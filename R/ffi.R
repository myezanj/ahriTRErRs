# Constants
STATUS_OK <- 0L
PAYLOAD_KIND_NONE <- 0L
PAYLOAD_KIND_ARROW_IPC <- 1L
PAYLOAD_KIND_PARQUET <- 2L
PAYLOAD_KIND_ARTIFACT <- 3L
RUNTIME_CONFIG_FLAGS_NEVER_START <- 1L

#' Create C API object
#'
#' @param artifact RuntimeArtifact object (optional)
#' @param library_path Path to library (optional)
#' @return C API object
#' @export
CApi <- function(artifact = NULL, library_path = NULL) {
  selected <- artifact %||% discover_runtime_artifact()
  lib_path <- library_path %||% runtime_c_abi_library(selected)

  if (!file.exists(lib_path)) {
    abort_ahri_tre(
      sprintf("C ABI library not found at: %s", lib_path),
      class = "ahri_tre_library_error"
    )
  }

  handle <- ahri_tre_library_open(lib_path)

  if (!inherits(handle, "externalptr") || identical(handle, new("externalptr"))) {
    abort_ahri_tre(
      "Failed to load C ABI library",
      class = "ahri_tre_library_error"
    )
  }

  api <- list(
    library_path = normalizePath(lib_path, mustWork = FALSE),
    handle = handle,
    artifact = selected
  )
  class(api) <- "ahri_tre_c_api"
  api
}

#' Open AHRI TRE library
#'
#' @param path Path to library
#' @return External pointer to library handle
#' @noRd
ahri_tre_library_open <- function(path) {
  .Call("ahri_tre_library_open", path, PACKAGE = "ahriTRErRs")
}

#' Get owned string from library
#'
#' @param path Library path
#' @param symbol_name Symbol name
#' @return Character string
#' @noRd
ahri_tre_owned_string <- function(path, symbol_name) {
  .Call("ahri_tre_owned_string", path, symbol_name, PACKAGE = "ahriTRErRs")
}

#' Get status message from library
#'
#' @param path Library path
#' @param status Status code
#' @return Character message
#' @noRd
ahri_tre_status_message_bridge <- function(path, status) {
  .Call("ahri_tre_status_message_bridge", path, status, PACKAGE = "ahriTRErRs")
}

#' Get result JSON from library
#'
#' @param path Library path
#' @param result Result handle
#' @return JSON string
#' @noRd
ahri_tre_result_response_json_bridge <- function(path, result) {
  .Call("ahri_tre_result_response_json_bridge", path, result, PACKAGE = "ahriTRErRs")
}

#' Free result
#'
#' @param path Library path
#' @param result Result handle
#' @return NULL
#' @noRd
ahri_tre_result_free_bridge <- function(path, result) {
  .Call("ahri_tre_result_free_bridge", path, result, PACKAGE = "ahriTRErRs")
}

#' Call runtime function
#'
#' @param path Library path
#' @param action Action name
#' @param endpoint Daemon endpoint
#' @param binary Daemon binary path
#' @param timeout Timeout in ms
#' @param never_start Never start flag
#' @return Result handle
#' @noRd
ahri_tre_runtime_call_bridge <- function(path, action, endpoint, binary, timeout, never_start) {
  .Call(
    "ahri_tre_runtime_call_bridge",
    path,
    action,
    endpoint,
    binary,
    timeout,
    never_start,
    PACKAGE = "ahriTRErRs"
  )
}

#' Create client
#'
#' @param path Library path
#' @param endpoint Daemon endpoint
#' @param binary Daemon binary path
#' @param timeout Timeout in ms
#' @param never_start Never start flag
#' @return Client handle
#' @noRd
ahri_tre_client_create_bridge <- function(path, endpoint, binary, timeout, never_start) {
  .Call(
    "ahri_tre_client_create_bridge",
    path,
    endpoint,
    binary,
    timeout,
    never_start,
    PACKAGE = "ahriTRErRs"
  )
}

#' Free client
#'
#' @param path Library path
#' @param client Client handle
#' @return NULL
#' @noRd
ahri_tre_client_free_bridge <- function(path, client) {
  .Call("ahri_tre_client_free_bridge", path, client, PACKAGE = "ahriTRErRs")
}

#' Execute protocol JSON request
#'
#' @param path Library path
#' @param client Client handle
#' @param request Request JSON
#' @return Result handle
#' @noRd
ahri_tre_client_execute_protocol_json_bridge <- function(path, client, request) {
  .Call("ahri_tre_client_execute_protocol_json_bridge", path, client, request, PACKAGE = "ahriTRErRs")
}

#' Get payload count
#'
#' @param path Library path
#' @param result Result handle
#' @return Integer count
#' @noRd
ahri_tre_result_payload_count_bridge <- function(path, result) {
  .Call("ahri_tre_result_payload_count_bridge", path, result, PACKAGE = "ahriTRErRs")
}

#' Get payload descriptor
#'
#' @param path Library path
#' @param result Result handle
#' @param index Payload index
#' @return Payload descriptor
#' @noRd
ahri_tre_result_payload_descriptor_bridge <- function(path, result, index) {
  .Call("ahri_tre_result_payload_descriptor_bridge", path, result, index, PACKAGE = "ahriTRErRs")
}

#' Get payload bytes
#'
#' @param path Library path
#' @param result Result handle
#' @param index Payload index
#' @return Raw bytes
#' @noRd
ahri_tre_result_payload_bytes_bridge <- function(path, result, index) {
  .Call("ahri_tre_result_payload_bytes_bridge", path, result, index, PACKAGE = "ahriTRErRs")
}

#' Get owned string from API
#'
#' @param api C API object
#' @param symbol Symbol name
#' @return Character string
#' @noRd
owned_string <- function(api, symbol) {
  ahri_tre_owned_string(api$library_path, as.character(symbol))
}

#' Get status message
#'
#' @param library_path Library path
#' @param status Status code
#' @return Character message
#' @noRd
ahri_tre_status_message <- function(library_path, status) {
  ahri_tre_status_message_bridge(library_path, as.integer(status))
}

#' Get result JSON
#'
#' @param api C API object
#' @param result Result handle
#' @return Parsed JSON
#' @noRd
result_json <- function(api, result) {
  json <- ahri_tre_result_response_json_bridge(api$library_path, result)
  if (!nzchar(json)) {
    return(list())
  }
  jsonlite::fromJSON(json, simplifyVector = FALSE)
}

#' Free result
#'
#' @param api C API object
#' @param result Result handle
#' @return NULL
#' @noRd
result_free <- function(api, result) {
  ahri_tre_result_free_bridge(api$library_path, result)
  invisible(NULL)
}