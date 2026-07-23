#' Create runtime configuration
#'
#' @param daemon_endpoint Daemon endpoint URL
#' @param daemon_binary Daemon binary path
#' @param readiness_timeout_ms Timeout in milliseconds
#' @param never_start Never start daemon
#' @return Runtime config object
#' @export
RuntimeConfig <- function(
  daemon_endpoint = NULL,
  daemon_binary = NULL,
  readiness_timeout_ms = 0L,
  never_start = FALSE
) {
  config <- list(
    daemon_endpoint = daemon_endpoint,
    daemon_binary = daemon_binary,
    readiness_timeout_ms = as.integer(readiness_timeout_ms),
    never_start = isTRUE(never_start)
  )
  class(config) <- "ahri_tre_runtime_config"
  config
}

#' Get runtime status
#'
#' @param api C API object
#' @param config Runtime config
#' @return Runtime status
#' @export
runtime_status <- function(api = CApi(), config = RuntimeConfig()) {
  runtime_call(api, "status", config)
}

#' Discover daemon binary
#'
#' @param api C API object
#' @param config Runtime config
#' @return Discovery result
#' @export
runtime_discover_daemon_binary <- function(api = CApi(), config = RuntimeConfig()) {
  runtime_call(api, "discover_daemon_binary", config)
}

#' Ensure runtime is running
#'
#' @param api C API object
#' @param config Runtime config
#' @return Ensure result
#' @export
runtime_ensure <- function(api = CApi(), config = RuntimeConfig()) {
  runtime_call(api, "ensure", config)
}

#' Stop runtime
#'
#' @param api C API object
#' @param config Runtime config
#' @return Stop result
#' @export
runtime_stop <- function(api = CApi(), config = RuntimeConfig()) {
  runtime_call(api, "stop", config)
}

#' Execute runtime call with library path
#'
#' @param api C API object
#' @param code Code to execute
#' @return Result of code
#' @noRd
tre_with_runtime_library_path <- function(api, code) {
  runtime_lib <- dirname(normalizePath(api$library_path, mustWork = FALSE))
  if (!dir.exists(runtime_lib)) {
    return(force(code))
  }

  original_ld_path <- Sys.getenv("LD_LIBRARY_PATH", unset = NA_character_)
  ld_parts <- c(runtime_lib)
  if (!is.na(original_ld_path) && nzchar(original_ld_path)) {
    ld_parts <- c(ld_parts, original_ld_path)
  }

  Sys.setenv(LD_LIBRARY_PATH = paste(unique(ld_parts), collapse = ":"))
  on.exit({
    if (is.na(original_ld_path)) {
      Sys.unsetenv("LD_LIBRARY_PATH")
    } else {
      Sys.setenv(LD_LIBRARY_PATH = original_ld_path)
    }
  }, add = TRUE)

  force(code)
}

#' Make runtime call
#'
#' @param api C API object
#' @param action Action name
#' @param config Runtime config
#' @return Runtime result
#' @noRd
runtime_call <- function(api, action, config) {
  result <- tre_with_runtime_library_path(api, ahri_tre_runtime_call_bridge(
    api$library_path,
    action,
    config$daemon_endpoint,
    config$daemon_binary,
    as.integer(config$readiness_timeout_ms),
    isTRUE(config$never_start)
  ))
  status <- result$status
  check_abi_status(status, api)
  handle <- result$result
  on.exit(result_free(api, handle), add = TRUE)
  result_json(api, handle)
}