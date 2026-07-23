#' Create a payload object
#'
#' @param kind Payload kind
#' @param protocol_ref Protocol reference
#' @param media_type Media type
#' @param suggested_name Suggested file name
#' @param size_bytes Size in bytes
#' @param data Raw data
#' @return Payload object
#' @export
Payload <- function(kind, protocol_ref = NULL, media_type = NULL, suggested_name = NULL,
                    size_bytes = 0, data = NULL) {
  payload <- list(
    kind = kind,
    protocol_ref = protocol_ref,
    media_type = media_type,
    suggested_name = suggested_name,
    size_bytes = as.numeric(size_bytes),
    data = data
  )
  class(payload) <- "ahri_tre_payload"
  payload
}

#' Extract payloads from result
#'
#' @param api C API object
#' @param result Result handle
#' @return List of payloads
#' @noRd
payloads_from_result <- function(api, result) {
  count <- ahri_tre_result_payload_count_bridge(api$library_path, result)
  if (count == 0L) {
    return(list())
  }
  lapply(seq_len(count), function(index) payload_from_result(api, result, index - 1L))
}

#' Extract a single payload from result
#'
#' @param api C API object
#' @param result Result handle
#' @param index Payload index
#' @return Payload object
#' @noRd
payload_from_result <- function(api, result, index) {
  descriptor <- ahri_tre_result_payload_descriptor_bridge(api$library_path, result, as.integer(index))
  check_abi_status(descriptor$status, api)

  bytes <- ahri_tre_result_payload_bytes_bridge(api$library_path, result, as.integer(index))
  check_abi_status(bytes$status, api)

  Payload(
    kind = payload_kind_name(descriptor$kind),
    protocol_ref = descriptor$protocol_ref,
    media_type = descriptor$media_type,
    suggested_name = descriptor$suggested_name,
    size_bytes = descriptor$size_bytes,
    data = bytes$data
  )
}

#' Convert Arrow IPC payload to table
#'
#' @param payload Payload object
#' @return Arrow table
#' @export
arrow_ipc_to_table <- function(payload) {
  if (!identical(payload$kind, "arrow_ipc") || is.null(payload$data)) {
    abort_ahri_tre(
      "payload does not contain Arrow IPC bytes",
      class = "ahri_tre_payload_error"
    )
  }

  if (!requireNamespace("arrow", quietly = TRUE)) {
    abort_ahri_tre(
      "install arrow for Arrow IPC conversion",
      class = "ahri_tre_payload_error"
    )
  }

  connection <- rawConnection(payload$data)
  on.exit(close(connection), add = TRUE)
  arrow::read_ipc_stream(connection)
}

#' Get payload kind name
#'
#' @param kind Payload kind code
#' @return Character name
#' @noRd
payload_kind_name <- function(kind) {
  switch(
    as.character(as.integer(kind)),
    "1" = "arrow_ipc",
    "2" = "parquet",
    "3" = "artifact",
    "none"
  )
}