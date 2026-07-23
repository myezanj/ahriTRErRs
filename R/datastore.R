# Auto-generated wrappers for Datastore, Semantic Catalog

datastore_adopt <- function(client, uper_user = NULL, uper_password_env = NULL, yes = NULL, format = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
    "--super-user" = uper_user,
    "--super-password-env" = uper_password_env,
    "--yes" = yes,
    "--format" = format
  )
  tre_command_call(
    client = client,
    kind = "datastore.adopt",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Text or JSON adoption report",
    .status_and_purpose = "Verify a legacy datastore and write a ready identity binding with managed lake catalog credentials.",
    .function_name = "datastore_adopt"
  )
}

datastore_create <- function(client, datastore_or_tre_datastore = NULL, lake_base_path = NULL, uper_user = NULL, uper_password_env = NULL, force = NULL, yes = NULL, port = NULL, format = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
    "--datastore or TRE_DATASTORE" = datastore_or_tre_datastore,
    "--lake-base-path" = lake_base_path,
    "--super-user" = uper_user,
    "--super-password-env" = uper_password_env,
    "--force" = force,
    "--yes" = yes,
    "--port" = port,
    "--format" = format
  )
  tre_command_call(
    client = client,
    kind = "datastore.create",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Text or JSON creation report",
    .status_and_purpose = "Provision datastore metadata, roles, lake catalog state, managed catalog credentials, and the datastore-local identity binding.",
    .function_name = "datastore_create"
  )
}

datastore_info <- function(client, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list()
  tre_command_call(
    client = client,
    kind = "datastore.info",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Text or JSON runtime summary",
    .status_and_purpose = "Summarize datastore identity, safe binding status, connection metadata, lake state, and content counts.",
    .function_name = "datastore_info"
  )
}

datastore_list <- function(client, uper_user = NULL, uper_password_env_optional_server_port_ssl_bootstrap_overrides_format_text_json = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
    "--super-user" = uper_user,
    "--super-password-env; optional server/port/SSL/bootstrap overrides; --format text|json" = uper_password_env_optional_server_port_ssl_bootstrap_overrides_format_text_json
  )
  tre_command_call(
    client = client,
    kind = "datastore.list",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Text table or JSON discovery response",
    .status_and_purpose = "Discover AHRI TRE datastores on the current PostgreSQL server using metadata-only inspection.",
    .function_name = "datastore_list"
  )
}

datastore_ping <- function(client, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list()
  tre_command_call(
    client = client,
    kind = "datastore.ping",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Text or JSON connectivity result",
    .status_and_purpose = "Check datastore reachability and identity-binding verification.",
    .function_name = "datastore_ping"
  )
}

datastore_rotate <- function(client, uper_user = NULL, uper_password_env = NULL, yes = NULL, format = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
    "--super-user" = uper_user,
    "--super-password-env" = uper_password_env,
    "--yes" = yes,
    "--format" = format
  )
  tre_command_call(
    client = client,
    kind = "datastore.rotate-lake-credential",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Text or JSON rotation report",
    .status_and_purpose = "Rotate the managed DuckLake catalog role password without changing ordinary open profiles.",
    .function_name = "datastore_rotate"
  )
}

datastore_schema <- function(client, uper_user = NULL, uper_password_env = NULL, port = NULL, format = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
    "--super-user" = uper_user,
    "--super-password-env" = uper_password_env,
    "--port" = port,
    "--format" = format
  )
  tre_command_call(
    client = client,
    kind = "datastore.schema-status",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Text or JSON schema compatibility status",
    .status_and_purpose = "Inspect metadata schema version, migration history, missing tables, and DuckLake catalog migration ownership. Report pending/adoptable/blocked migration steps without applying them. Apply supported datastore metadata schema migrations and report before/after status.",
    .function_name = "datastore_schema"
  )
}

domain_add <- function(client, name = NULL, uri = NULL, description = NULL, format = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
    "--name" = name,
    "--uri" = uri,
    "--description" = description,
    "--format" = format
  )
  tre_command_call(
    client = client,
    kind = "domain.add",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Domain record",
    .status_and_purpose = "Add or validate a semantic domain.",
    .function_name = "domain_add"
  )
}

domain_delete <- function(client, name = NULL, reason = NULL, actor = NULL, dry_run = NULL, yes = NULL, format = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
    "--name" = name,
    "--reason" = reason,
    "--actor" = actor,
    "--dry-run" = dry_run,
    "--yes" = yes,
    "--format" = format
  )
  tre_command_call(
    client = client,
    kind = "domain.delete",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Semantic delete plan or result",
    .status_and_purpose = "Physically delete an unused domain or block with dependency summary; no archive/retirement semantics.",
    .function_name = "domain_delete"
  )
}

domain_get <- function(client, name = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
    "--name" = name
  )
  tre_command_call(
    client = client,
    kind = "domain.get",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Domain record",
    .status_and_purpose = "Fetch one domain.",
    .function_name = "domain_get"
  )
}

domain_list <- function(client, format = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
    format = format
  )
  tre_command_call(
    client = client,
    kind = "domain.list",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Domain list",
    .status_and_purpose = "List semantic domains.",
    .function_name = "domain_list"
  )
}

tag_get <- function(client, target = NULL, name = NULL, domain = NULL, version = NULL, asset_type = NULL, format = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
    "--target" = target,
    "--name" = name,
    "--domain" = domain,
    "--version" = version,
    "--asset-type" = asset_type,
    "--format" = format
  )
  tre_command_call(
    client = client,
    kind = "tag.get",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Tags for target",
    .status_and_purpose = "Inspect tags on domains, studies, variables, entities, relations, assets, datafiles, datasets, and versions.",
    .function_name = "tag_get"
  )
}

tag_list <- function(client, format = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
    "--format" = format
  )
  tre_command_call(
    client = client,
    kind = "tag.list",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Tag registry",
    .status_and_purpose = "List normalized tag labels through the stable protocol.",
    .function_name = "tag_list"
  )
}

tag_set <- function(client, target = NULL, name = NULL, domain = NULL, version = NULL, asset_type = NULL, format = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
    "--target" = target,
    "--name" = name,
    "--domain" = domain,
    "--version" = version,
    "--asset-type" = asset_type,
    "--format" = format
  )
  tre_command_call(
    client = client,
    kind = "tag.set",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Updated tags for target",
    .status_and_purpose = "Replace the complete tag set for a supported target or clear all tags.",
    .function_name = "tag_set"
  )
}

variable_add <- function(client, format = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
    "--format" = format
  )
  tre_command_call(
    client = client,
    kind = "variable.add",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Variable record",
    .status_and_purpose = "Add a variable definition.",
    .function_name = "variable_add"
  )
}

variable_delete <- function(client, domain = NULL, name = NULL, reason = NULL, actor = NULL, dry_run = NULL, yes = NULL, format = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
    "--domain" = domain,
    "--name" = name,
    "--reason" = reason,
    "--actor" = actor,
    "--dry-run" = dry_run,
    "--yes" = yes,
    "--format" = format
  )
  tre_command_call(
    client = client,
    kind = "variable.delete",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Semantic delete plan or result",
    .status_and_purpose = "Physically delete an unused variable definition or block while preserving dataset/provenance meaning.",
    .function_name = "variable_delete"
  )
}

variable_get <- function(client, domain = NULL, name = NULL, format = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
    "--domain" = domain,
    "--name" = name,
    "--format" = format
  )
  tre_command_call(
    client = client,
    kind = "variable.get",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Variable record",
    .status_and_purpose = "Fetch one variable.",
    .function_name = "variable_get"
  )
}

variable_list <- function(client, domain_format = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
    "--domain; --format" = domain_format
  )
  tre_command_call(
    client = client,
    kind = "variable.list",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Variable list",
    .status_and_purpose = "List semantic variables by domain, or by resolved study when no domain is provided.",
    .function_name = "variable_list"
  )
}

variable_search <- function(client, limit = NULL, width = NULL, format = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
    "--limit" = limit,
    "--width" = width,
    "--format" = format
  )
  tre_command_call(
    client = client,
    kind = "variable.search",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Variable search results",
    .status_and_purpose = "Search bounded dictionary variable summaries without reading dataset rows.",
    .function_name = "variable_search"
  )
}

variable_update <- function(client, format = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
    "--format" = format
  )
  tre_command_call(
    client = client,
    kind = "variable.update",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Variable record",
    .status_and_purpose = "Update variable metadata.",
    .function_name = "variable_update"
  )
}

vocabulary_add <- function(client, domain = NULL, name = NULL, items = NULL, format = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
    "--domain" = domain,
    "--name" = name,
    "--items" = items,
    "--format" = format
  )
  tre_command_call(
    client = client,
    kind = "vocabulary.add",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Vocabulary record",
    .status_and_purpose = "Add a vocabulary and items.",
    .function_name = "vocabulary_add"
  )
}

vocabulary_delete <- function(client, domain = NULL, name = NULL, reason = NULL, actor = NULL, dry_run = NULL, yes = NULL, format = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
    "--domain" = domain,
    "--name" = name,
    "--reason" = reason,
    "--actor" = actor,
    "--dry-run" = dry_run,
    "--yes" = yes,
    "--format" = format
  )
  tre_command_call(
    client = client,
    kind = "vocabulary.delete",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Semantic delete plan or result",
    .status_and_purpose = "Physically delete an unused vocabulary definition or block on variables, items, mappings, and history.",
    .function_name = "vocabulary_delete"
  )
}

vocabulary_get <- function(client, domain = NULL, name = NULL, format = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
    "--domain" = domain,
    "--name" = name,
    "--format" = format
  )
  tre_command_call(
    client = client,
    kind = "vocabulary.get",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Vocabulary detail",
    .status_and_purpose = "Fetch one vocabulary and its items; JSON protocol output exposes items at .data.vocabulary.items.",
    .function_name = "vocabulary_get"
  )
}

vocabulary_list <- function(client, domain_format = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
    "--domain; --format" = domain_format
  )
  tre_command_call(
    client = client,
    kind = "vocabulary.list",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Vocabulary list",
    .status_and_purpose = "List vocabularies by domain, or by resolved study when no domain is provided.",
    .function_name = "vocabulary_list"
  )
}

