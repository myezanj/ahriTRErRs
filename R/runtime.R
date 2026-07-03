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

runtime_status <- function(api = CApi(), config = RuntimeConfig()) {
  runtime_call(api, "status", config)
}

runtime_discover_daemon_binary <- function(api = CApi(), config = RuntimeConfig()) {
  runtime_call(api, "discover_daemon_binary", config)
}

runtime_ensure <- function(api = CApi(), config = RuntimeConfig()) {
  runtime_call(api, "ensure", config)
}

runtime_stop <- function(api = CApi(), config = RuntimeConfig()) {
  runtime_call(api, "stop", config)
}

runtime_call <- function(api, action, config) {
  result <- ahri_tre_runtime_call_bridge(
    api$library_path,
    action,
    config$daemon_endpoint,
    config$daemon_binary,
    as.integer(config$readiness_timeout_ms),
    isTRUE(config$never_start)
  )
  status <- result$status
  check_abi_status(status, api)
  handle <- result$result
  on.exit(result_free(api, handle), add = TRUE)
  result_json(api, handle)
}
