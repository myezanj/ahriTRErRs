# Auto-generated command wrappers for Study, Governance

study_access_grant <- function(client, study = NULL, user = NULL, format = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
    "study" = study,
    "user" = user,
    "format" = format
  )
  tre_command_call(
    client = client,
    kind = "study.access.grant",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Grant result",
    .status_and_purpose = "Grant study access.",
    .function_name = "study_access_grant"
  )
}

study_access_list <- function(client, study = NULL, format = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
    "study" = study,
    "format" = format
  )
  tre_command_call(
    client = client,
    kind = "study.access.list",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Access grant list",
    .status_and_purpose = "List study access grants.",
    .function_name = "study_access_list"
  )
}

study_access_revoke <- function(client, study = NULL, user = NULL, format = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
    "study" = study,
    "user" = user,
    "format" = format
  )
  tre_command_call(
    client = client,
    kind = "study.access.revoke",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Revocation result",
    .status_and_purpose = "Revoke study access.",
    .function_name = "study_access_revoke"
  )
}

study_add <- function(client, name = NULL, external_id = NULL, study_type = NULL, domain = NULL, format = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
    "name" = name,
    "external-id" = external_id,
    "study-type" = study_type,
    "domain" = domain,
    "format" = format
  )
  tre_command_call(
    client = client,
    kind = "study.add",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Study registration",
    .status_and_purpose = "Register a study and link it to a domain.",
    .function_name = "study_add"
  )
}

study_add_domain <- function(client, study = NULL, domain = NULL, format = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
    "study" = study,
    "domain" = domain,
    "format" = format
  )
  tre_command_call(
    client = client,
    kind = "study.add-domain",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Study registration",
    .status_and_purpose = "Link the current or explicit study to a domain.",
    .function_name = "study_add_domain"
  )
}

study_clear_current <- function(client, study = NULL, format = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
    "study" = study,
    "format" = format
  )
  tre_command_call(
    client = client,
    kind = "study.clear-current",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Text or JSON status",
    .status_and_purpose = "Clear current study from session metadata.",
    .function_name = "study_clear_current"
  )
}

study_context_list <- function(client, include_unavailable = NULL, format = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
    "include-unavailable" = include_unavailable,
    "format" = format
  )
  tre_command_call(
    client = client,
    kind = "study.context.list",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Study context list",
    .status_and_purpose = "List available study contexts.",
    .function_name = "study_context_list"
  )
}

study_current <- function(client, study = NULL, format = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
    "study" = study,
    "format" = format
  )
  tre_command_call(
    client = client,
    kind = "study.current",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Text or JSON status",
    .status_and_purpose = "Show the current study.",
    .function_name = "study_current"
  )
}

study_custodians_add <- function(client, study = NULL, delegate = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
    "study" = study,
    "delegate" = delegate
  )
  tre_command_call(
    client = client,
    kind = "study.custodians.add-delegate",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Custodian link",
    .status_and_purpose = "Add a delegate custodian.",
    .function_name = "study_custodians_add"
  )
}

study_custodians_list <- function(client, study = NULL, format = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
    "study" = study,
    "format" = format
  )
  tre_command_call(
    client = client,
    kind = "study.custodians.list",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Custodian list",
    .status_and_purpose = "List study custodians.",
    .function_name = "study_custodians_list"
  )
}

study_custodians_remove <- function(client, study = NULL, format = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
    "study" = study,
    "format" = format
  )
  tre_command_call(
    client = client,
    kind = "study.custodians.remove-delegate",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Removal result",
    .status_and_purpose = "Remove a delegate custodian.",
    .function_name = "study_custodians_remove"
  )
}

study_custodians_transfer <- function(client, study = NULL, format = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
    "study" = study,
    "format" = format
  )
  tre_command_call(
    client = client,
    kind = "study.custodians.transfer-primary",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Custodian link",
    .status_and_purpose = "Transfer primary custodianship.",
    .function_name = "study_custodians_transfer"
  )
}

study_delete <- function(client, name = NULL, reason = NULL, actor = NULL, cascade = NULL, force = NULL, archive = NULL, dry_run = NULL, yes = NULL, format = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
    "name" = name,
    "reason" = reason,
    "actor" = actor,
    "cascade" = cascade,
    "force" = force,
    "archive" = archive,
    "dry-run" = dry_run,
    "yes" = yes,
    "format" = format
  )
  tre_command_call(
    client = client,
    kind = "study.delete",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Archive/delete plan or result",
    .status_and_purpose = "Archive by default into the special?Archive?study, then delete the source study with mandatory lake cleanup.",
    .function_name = "study_delete"
  )
}

study_duo_list <- function(client, study = NULL, format = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
    "study" = study,
    "format" = format
  )
  tre_command_call(
    client = client,
    kind = "study.duo.list",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "DUO restriction list",
    .status_and_purpose = "List study DUO restrictions.",
    .function_name = "study_duo_list"
  )
}

study_duo_replace <- function(client, study = NULL, restrictions = NULL, format = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
    "study" = study,
    "restrictions" = restrictions,
    "format" = format
  )
  tre_command_call(
    client = client,
    kind = "study.duo.replace",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "DUO replacement result",
    .status_and_purpose = "Replace the study DUO restriction set.",
    .function_name = "study_duo_replace"
  )
}

study_get <- function(client, name = NULL, format = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
    "name" = name,
    "format" = format
  )
  tre_command_call(
    client = client,
    kind = "study.get",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Study registration",
    .status_and_purpose = "Fetch a study by name.",
    .function_name = "study_get"
  )
}

study_list <- function(client, format = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
    "format" = format
  )
  tre_command_call(
    client = client,
    kind = "study.list",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Study list",
    .status_and_purpose = "List studies and linked domains.",
    .function_name = "study_list"
  )
}

study_search <- function(client, cursor = NULL, limit = NULL, width = NULL, format = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
    "cursor" = cursor,
    "limit" = limit,
    "width" = width,
    "format" = format
  )
  tre_command_call(
    client = client,
    kind = "study.search",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Study search results",
    .status_and_purpose = "Search bounded governed study summaries.",
    .function_name = "study_search"
  )
}

study_use <- function(client, name = NULL, study = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
    "name" = name,
    "study" = study
  )
  tre_command_call(
    client = client,
    kind = "study.use",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Text status",
    .status_and_purpose = "Set the current study for the active session.",
    .function_name = "study_use"
  )
}


