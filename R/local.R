# Auto-generated command wrappers for Local Commands

completion <- function(client, shell = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
    "shell" = shell
  )
  tre_command_call(
    client = client,
    kind = "completion",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Shell completion script",
    .status_and_purpose = "Generate completions for the public CLI.",
    .function_name = "completion"
  )
}

doctor <- function(client, strict = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
    "strict" = strict
  )
  tre_command_call(
    client = client,
    kind = "doctor",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Text or JSON readiness report",
    .status_and_purpose = "Check local, session, and Automation readiness.",
    .function_name = "doctor"
  )
}

schema_get <- function(client, schema_id = NULL, format = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
    "schema_id" = schema_id,
    "format" = format
  )
  tre_command_call(
    client = client,
    kind = "schema.get",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Schema document",
    .status_and_purpose = "Print one known JSON Schema document.",
    .function_name = "schema_get"
  )
}

schema_list <- function(client, format = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
    "format" = format
  )
  tre_command_call(
    client = client,
    kind = "schema.list",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Schema identifiers",
    .status_and_purpose = "List stable JSON control-plane schema IDs and the coverage map.",
    .function_name = "schema_list"
  )
}

version <- function(client, format = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
    "format" = format
  )
  tre_command_call(
    client = client,
    kind = "version",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Text version or JSON build metadata",
    .status_and_purpose = "Print CLI version and build metadata.",
    .function_name = "version"
  )
}


