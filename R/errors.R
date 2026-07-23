#' Create a new AHRI TRE error
#'
#' @param message Error message
#' @param class Additional error classes
#' @param call Call information
#' @return Error object
#' @noRd
new_ahri_tre_error <- function(message, class = character(), call = NULL) {
  structure(
    list(message = message, call = call),
    class = c(class, "ahri_tre_error", "error", "condition")
  )
}

#' Abort with AHRI TRE error
#'
#' @param message Error message
#' @param class Additional error classes
#' @param call Call information
#' @return Throws error
#' @noRd
abort_ahri_tre <- function(message, class = character(), call = NULL) {
  stop(new_ahri_tre_error(message, class = class, call = call))
}

#' Check ABI status
#'
#' @param status Status code
#' @param api API object (optional)
#' @return Invisibly returns NULL on success
#' @noRd
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

#' Handle TRE errors with context
#'
#' @param expr Expression to evaluate
#' @param context Error context
#' @param fallback Optional fallback value
#' @return Result or fallback
#' @export
try_tre <- function(expr, context = NULL, fallback = NULL) {
  result <- tryCatch(expr, error = function(e) e)

  if (inherits(result, "error")) {
    context_msg <- if (!is.null(context)) paste0(" [", context, "]") else ""

    if (grepl("lake filesystem operation failed: Permission denied", result$message, fixed = TRUE)) {
      abort_ahri_tre(
        paste0("Lake write permission denied", context_msg),
        class = "tre_permission_error"
      )
    }

    if (grepl("no live session is selected", result$message, fixed = TRUE)) {
      abort_ahri_tre(
        paste0("No live session available", context_msg),
        class = "tre_session_error"
      )
    }

    if (grepl("required pointer was null", result$message, fixed = TRUE)) {
      abort_ahri_tre(
        paste0("Client pointer is invalid", context_msg),
        class = "tre_pointer_error"
      )
    }

    if (!is.null(fallback)) {
      return(fallback)
    }

    stop(result)
  }

  result
}

#' Format a try-error for display
#'
#' @param err Error object
#' @return Formatted error message
#' @export
format_try_error <- function(err) {
  if (inherits(err, "try-error")) {
    condition <- attr(err, "condition")
    if (!is.null(condition)) {
      return(conditionMessage(condition))
    }
    return(as.character(err))
  }
  as.character(err)
}

#' Check if error is a known TRE error type
#'
#' @param err Error object
#' @param type Error type to check
#' @return Logical
#' @export
is_tre_error <- function(err, type = NULL) {
  if (!inherits(err, "error")) {
    return(FALSE)
  }
  if (is.null(type)) {
    return(inherits(err, "ahri_tre_error"))
  }
  classes <- c(type, paste0("tre_", type), paste0("ahri_tre_", type))
  inherits(err, classes)
}

#' Create a warning with context
#'
#' @param message Warning message
#' @param context Warning context
#' @param ... Additional arguments passed to warning
#' @noRd
warn_tre <- function(message, context = NULL, ...) {
  context_msg <- if (!is.null(context)) paste0(" [", context, "]") else ""
  warning(paste0(message, context_msg), ...)
}