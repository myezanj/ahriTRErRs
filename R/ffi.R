STATUS_OK <- 0L
PAYLOAD_KIND_NONE <- 0L
PAYLOAD_KIND_ARROW_IPC <- 1L
PAYLOAD_KIND_PARQUET <- 2L
PAYLOAD_KIND_ARTIFACT <- 3L
RUNTIME_CONFIG_FLAGS_NEVER_START <- 1L

CApi <- function(artifact = NULL, library_path = NULL) {
  selected <- artifact %||% discover_runtime_artifact()
  lib_path <- library_path %||% runtime_c_abi_library(selected)
  handle <- ahri_tre_library_open(lib_path)
  api <- list(
    library_path = normalizePath(lib_path, mustWork = FALSE),
    handle = handle,
    artifact = selected
  )
  class(api) <- "ahri_tre_c_api"
  api
}

ahri_tre_library_open <- function(path) {
  .Call("ahri_tre_library_open", path, PACKAGE = "ahritre")
}

ahri_tre_owned_string <- function(path, symbol_name) {
  .Call("ahri_tre_owned_string", path, symbol_name, PACKAGE = "ahritre")
}

ahri_tre_status_message_bridge <- function(path, status) {
  .Call("ahri_tre_status_message_bridge", path, status, PACKAGE = "ahritre")
}

ahri_tre_result_response_json_bridge <- function(path, result) {
  .Call("ahri_tre_result_response_json_bridge", path, result, PACKAGE = "ahritre")
}

ahri_tre_result_free_bridge <- function(path, result) {
  .Call("ahri_tre_result_free_bridge", path, result, PACKAGE = "ahritre")
}

ahri_tre_runtime_call_bridge <- function(path, action, endpoint, binary, timeout, never_start) {
  .Call(
    "ahri_tre_runtime_call_bridge",
    path,
    action,
    endpoint,
    binary,
    timeout,
    never_start,
    PACKAGE = "ahritre"
  )
}

ahri_tre_client_create_bridge <- function(path, endpoint, binary, timeout, never_start) {
  .Call(
    "ahri_tre_client_create_bridge",
    path,
    endpoint,
    binary,
    timeout,
    never_start,
    PACKAGE = "ahritre"
  )
}

ahri_tre_client_free_bridge <- function(path, client) {
  .Call("ahri_tre_client_free_bridge", path, client, PACKAGE = "ahritre")
}

ahri_tre_client_execute_protocol_json_bridge <- function(path, client, request) {
  .Call("ahri_tre_client_execute_protocol_json_bridge", path, client, request, PACKAGE = "ahritre")
}

ahri_tre_result_payload_count_bridge <- function(path, result) {
  .Call("ahri_tre_result_payload_count_bridge", path, result, PACKAGE = "ahritre")
}

ahri_tre_result_payload_descriptor_bridge <- function(path, result, index) {
  .Call("ahri_tre_result_payload_descriptor_bridge", path, result, index, PACKAGE = "ahritre")
}

ahri_tre_result_payload_bytes_bridge <- function(path, result, index) {
  .Call("ahri_tre_result_payload_bytes_bridge", path, result, index, PACKAGE = "ahritre")
}

owned_string <- function(api, symbol) {
  ahri_tre_owned_string(api$library_path, as.character(symbol))
}

ahri_tre_status_message <- function(library_path, status) {
  ahri_tre_status_message_bridge(library_path, as.integer(status))
}

result_json <- function(api, result) {
  json <- ahri_tre_result_response_json_bridge(api$library_path, result)
  if (!nzchar(json)) {
    return(list())
  }
  jsonlite::fromJSON(json, simplifyVector = FALSE)
}

result_free <- function(api, result) {
  ahri_tre_result_free_bridge(api$library_path, result)
  invisible(NULL)
}
