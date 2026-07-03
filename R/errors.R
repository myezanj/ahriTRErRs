new_ahri_tre_error <- function(message, class = character(), call = NULL) {
  structure(
    list(message = message, call = call),
    class = c(class, "ahri_tre_error", "error", "condition")
  )
}

abort_ahri_tre <- function(message, class = character(), call = NULL) {
  stop(new_ahri_tre_error(message, class = class, call = call))
}

check_abi_status <- function(status, api = NULL) {
  if (identical(as.integer(status), 0L)) {
    return(invisible(NULL))
  }
  message <- if (is.null(api)) {
    sprintf("AHRI TRE ABI status %s", status)
  } else {
    ahri_tre_status_message(api$library_path, as.integer(status))
  }
  abort_ahri_tre(message, class = "ahri_tre_abi_error")
}
