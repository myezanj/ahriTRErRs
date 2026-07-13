# Auto-generated command wrappers for Authentication, Daemon, Sessions

auth_login <- function(client, write_token_file = NULL, write_auth_context = NULL, cache_token = NULL, format = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
    "write-token-file" = write_token_file,
    "write-auth-context" = write_auth_context,
    "cache-token" = cache_token,
    "format" = format
  )
  tre_command_call(
    client = client,
    kind = "auth.login",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Text or JSON auth artifact summary",
    .status_and_purpose = "Run interactive OAuth and optionally persist reusable auth material.",
    .function_name = "auth_login"
  )
}

auth_logout <- function(client, auth_context = NULL, token_file = NULL, cached = NULL, format = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
    "auth-context" = auth_context,
    "token-file" = token_file,
    "cached" = cached,
    "format" = format
  )
  tre_command_call(
    client = client,
    kind = "auth.logout",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Text or JSON logout status",
    .status_and_purpose = "Remove token material.",
    .function_name = "auth_logout"
  )
}

auth_status <- function(client, format = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
  )
  tre_command_call(
    client = client,
    kind = "auth.status",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Text or JSON auth status",
    .status_and_purpose = "Inspect reusable auth material.",
    .function_name = "auth_status"
  )
}

daemon_doctor <- function(client, format = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
  )
  tre_command_call(
    client = client,
    kind = "daemon.doctor",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Text or?daemon.doctor?protocol envelope",
    .status_and_purpose = "Query daemon runtime, socket, state, session, and protocol readiness checks.",
    .function_name = "daemon_doctor"
  )
}

daemon_start <- function(client, format = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
  )
  tre_command_call(
    client = client,
    kind = "daemon.start",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Text or JSON daemon status",
    .status_and_purpose = "Start the local daemon process.",
    .function_name = "daemon_start"
  )
}

daemon_status <- function(client, format = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
  )
  tre_command_call(
    client = client,
    kind = "daemon.status",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Text or JSON daemon status",
    .status_and_purpose = "Inspect daemon reachability.",
    .function_name = "daemon_status"
  )
}

daemon_stop <- function(client, format = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
  )
  tre_command_call(
    client = client,
    kind = "daemon.stop",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Text or JSON daemon status",
    .status_and_purpose = "Stop the local daemon.",
    .function_name = "daemon_stop"
  )
}

daemon_version <- function(client, format = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
  )
  tre_command_call(
    client = client,
    kind = "daemon.version",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Text or?daemon.version?protocol envelope",
    .status_and_purpose = "Query running daemon build identity and protocol compatibility.",
    .function_name = "daemon_version"
  )
}

session_close <- function(client, name = NULL, all = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
    "name" = name,
    "all" = all
  )
  tre_command_call(
    client = client,
    kind = "session.close",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Text status",
    .status_and_purpose = "Close one or all sessions.",
    .function_name = "session_close"
  )
}

session_list <- function(client, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
  )
  tre_command_call(
    client = client,
    kind = "session.list",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Text list",
    .status_and_purpose = "List known local sessions, including the Authenticated TRE user for live authenticated sessions.",
    .function_name = "session_list"
  )
}

session_open <- function(client, name = NULL, profile = NULL, env_file = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
    "name" = name,
    "profile" = profile,
    "env-file" = env_file
  )
  tre_command_call(
    client = client,
    kind = "session.open-oauth",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Text session status",
    .status_and_purpose = "Open an interactive OAuth-backed live session. Open a live session from stored OAuth material. Open a live session from an injected token.",
    .function_name = "session_open"
  )
}

session_reopen <- function(client, name = NULL, force_reauth = NULL, clear_token_cache = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
    "name" = name,
    "force-reauth" = force_reauth,
    "clear-token-cache" = clear_token_cache
  )
  tre_command_call(
    client = client,
    kind = "session.reopen",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Text session status",
    .status_and_purpose = "Reopen a persisted non-secret session.",
    .function_name = "session_reopen"
  )
}

session_status <- function(client, name = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
  )
  tre_command_call(
    client = client,
    kind = "session.status",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Text status",
    .status_and_purpose = "Show session metadata and live state.",
    .function_name = "session_status"
  )
}

session_use <- function(client, name = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
  )
  tre_command_call(
    client = client,
    kind = "session.use",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Text status",
    .status_and_purpose = "Select the active local session.",
    .function_name = "session_use"
  )
}


