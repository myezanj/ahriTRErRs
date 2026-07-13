TRE_PROTOCOL_VERSION <- "1.0.0"
TRE_COMMAND_KIND_MAP <- list(
  "asset_delete" = "asset.delete",
  "asset_duo_clear" = "asset.duo.clear",
  "asset_duo_list" = "asset.duo.list",
  "asset_duo_replace" = "asset.duo.replace",
  "asset_get" = "asset.get",
  "asset_list" = "asset.list",
  "asset_versions" = "asset.versions",
  "auth_login" = "auth.login",
  "auth_logout" = "auth.logout",
  "auth_status" = "auth.status",
  "completion" = "completion",
  "daemon_doctor" = "daemon.doctor",
  "daemon_start" = "daemon.start",
  "daemon_status" = "daemon.status",
  "daemon_stop" = "daemon.stop",
  "daemon_version" = "daemon.version",
  "datafile_delete" = "datafile.delete",
  "datafile_export" = "datafile.export",
  "datafile_list" = "datafile.list",
  "datafile_metadata" = "datafile.metadata",
  "datafile_search" = "datafile.search",
  "dataset_data" = "dataset.data",
  "dataset_delete" = "dataset.delete",
  "dataset_export" = "dataset.export",
  "dataset_list" = "dataset.list",
  "dataset_metadata" = "dataset.metadata",
  "dataset_preview" = "dataset.preview",
  "dataset_search" = "dataset.search",
  "dataset_withdraw" = "dataset.withdraw",
  "datastore_adopt" = "datastore.adopt",
  "datastore_create" = "datastore.create",
  "datastore_info" = "datastore.info",
  "datastore_list" = "datastore.list",
  "datastore_ping" = "datastore.ping",
  "datastore_rotate" = "datastore.rotate-lake-credential",
  "datastore_schema" = "datastore.schema-status",
  "doctor" = "doctor",
  "domain_add" = "domain.add",
  "domain_delete" = "domain.delete",
  "domain_get" = "domain.get",
  "domain_list" = "domain.list",
  "entity_add" = "entity.add",
  "entity_delete" = "entity.delete",
  "entity_get" = "entity.get",
  "entity_instance_add" = "entity.instance.add",
  "entity_instance_asset_link_add" = "entity.instance.asset-link.add",
  "entity_instance_asset_link_list" = "entity.instance.asset-link.list",
  "entity_instance_dataset_link_add" = "entity.instance.dataset-link.add",
  "entity_instance_dataset_link_get" = "entity.instance.dataset-link.get",
  "entity_instance_dataset_link_list" = "entity.instance.dataset-link.list",
  "entity_instance_datasets" = "entity.instance.datasets",
  "entity_instance_ensure" = "entity.instance.ensure-from-dataset",
  "entity_instance_get" = "entity.instance.get",
  "entity_instance_list" = "entity.instance.list",
  "entity_instance_map_add" = "entity.instance.map.add",
  "entity_instance_map_get" = "entity.instance.map.get",
  "entity_instance_map_list" = "entity.instance.map.list",
  "entity_list" = "entity.list",
  "entity_relation_add" = "entity-relation.add",
  "entity_relation_delete" = "entity-relation.delete",
  "entity_relation_get" = "entity-relation.get",
  "entity_relation_instance_add" = "entity-relation.instance.add",
  "entity_relation_instance_asset_link_add" = "entity-relation.instance.asset-link.add",
  "entity_relation_instance_asset_link_list" = "entity-relation.instance.asset-link.list",
  "entity_relation_instance_dataset_link_add" = "entity-relation.instance.dataset-link.add",
  "entity_relation_instance_dataset_link_get" = "entity-relation.instance.dataset-link.get",
  "entity_relation_instance_dataset_link_list" = "entity-relation.instance.dataset-link.list",
  "entity_relation_instance_ensure" = "entity-relation.instance.ensure-from-dataset",
  "entity_relation_instance_get" = "entity-relation.instance.get",
  "entity_relation_instance_list" = "entity-relation.instance.list",
  "entity_relation_instance_map_add" = "entity-relation.instance.map.add",
  "entity_relation_instance_map_get" = "entity-relation.instance.map.get",
  "entity_relation_instance_map_list" = "entity-relation.instance.map.list",
  "entity_relation_list" = "entity-relation.list",
  "entity_relation_search" = "entity-relation.search",
  "entity_search" = "entity.search",
  "ingest_datafile" = "ingest.datafile",
  "ingest_dataset_datafile" = "ingest.dataset.from-datafile",
  "ingest_dataset_sql" = "ingest.dataset.from-sql",
  "ingest_dataset_table" = "ingest.dataset.table",
  "ingest_redcap_project" = "ingest.redcap.project",
  "schema_get" = "schema.get",
  "schema_list" = "schema.list",
  "session_close" = "session.close",
  "session_list" = "session.list",
  "session_open" = "session.open-oauth",
  "session_reopen" = "session.reopen",
  "session_status" = "session.status",
  "session_use" = "session.use",
  "study_access_grant" = "study.access.grant",
  "study_access_list" = "study.access.list",
  "study_access_revoke" = "study.access.revoke",
  "study_add" = "study.add",
  "study_add_domain" = "study.add-domain",
  "study_clear_current" = "study.clear-current",
  "study_context_list" = "study.context.list",
  "study_current" = "study.current",
  "study_custodians_add" = "study.custodians.add-delegate",
  "study_custodians_list" = "study.custodians.list",
  "study_custodians_remove" = "study.custodians.remove-delegate",
  "study_custodians_transfer" = "study.custodians.transfer-primary",
  "study_delete" = "study.delete",
  "study_duo_list" = "study.duo.list",
  "study_duo_replace" = "study.duo.replace",
  "study_get" = "study.get",
  "study_list" = "study.list",
  "study_search" = "study.search",
  "study_use" = "study.use",
  "tag_get" = "tag.get",
  "tag_list" = "tag.list",
  "tag_set" = "tag.set",
  "transformation_list" = "transformation.list",
  "variable_add" = "variable.add",
  "variable_delete" = "variable.delete",
  "variable_get" = "variable.get",
  "variable_list" = "variable.list",
  "variable_search" = "variable.search",
  "variable_update" = "variable.update",
  "version" = "version",
  "vocabulary_add" = "vocabulary.add",
  "vocabulary_delete" = "vocabulary.delete",
  "vocabulary_get" = "vocabulary.get",
  "vocabulary_list" = "vocabulary.list"
)

compact_null_fields <- function(x) {
  if (length(x) == 0L) {
    return(list())
  }
  x[!vapply(x, is.null, logical(1))]
}

merge_request_body <- function(auto_fields = list(), dot_fields = list(), explicit_body = NULL) {
  if (!is.null(explicit_body)) {
    return(explicit_body)
  }

  body <- compact_null_fields(auto_fields)
  dots <- compact_null_fields(dot_fields)
  if (length(dots) == 0L) {
    return(body)
  }

  named <- names(dots)
  if (is.null(named)) {
    return(c(body, dots))
  }

  for (i in seq_along(dots)) {
    key <- names(dots)[[i]]
    if (is.null(key) || !nzchar(key)) {
      next
    }
    body[[key]] <- dots[[i]]
  }
  body
}

new_tre_protocol_request <- function(kind, body = list(), protocol_version = TRE_PROTOCOL_VERSION) {
  list(
    protocol_version = protocol_version,
    kind = kind,
    body = body %||% list()
  )
}

tre_result_ok <- function(envelope) {
  ok <- envelope$ok
  if (is.logical(ok) && length(ok) == 1L) {
    return(isTRUE(ok))
  }
  is.null(envelope$error) && is.null(envelope$failure)
}

tre_extract_data <- function(envelope) {
  for (key in c("data", "result", "output", "body")) {
    if (!is.null(envelope[[key]])) {
      return(envelope[[key]])
    }
  }
  envelope
}

tre_normalize_output <- function(result, output_label = NULL, status_and_purpose = NULL, function_name = NULL) {
  envelope <- result$envelope %||% list()
  if (!tre_result_ok(envelope)) {
    failure <- protocol_failure_summary(envelope)
    abort_ahri_tre(
      sprintf("%s failed: %s", function_name %||% "TRE command", failure$message),
      class = "ahri_tre_protocol_error"
    )
  }

  structure(
    list(
      function_name = function_name,
      output_label = output_label,
      status_and_purpose = status_and_purpose,
      data = tre_extract_data(envelope),
      envelope = envelope,
      payloads = result$payloads %||% list()
    ),
    class = "ahri_tre_wrapper_result"
  )
}

tre_command_call <- function(
  client,
  kind,
  ...,
  .auto_fields = list(),
  .body = NULL,
  .protocol_version = TRE_PROTOCOL_VERSION,
  .output_label = NULL,
  .status_and_purpose = NULL,
  .function_name = NULL
) {
  body <- merge_request_body(
    auto_fields = .auto_fields,
    dot_fields = list(...),
    explicit_body = .body
  )

  result <- execute_json(
    client = client,
    request = new_tre_protocol_request(
      kind = kind,
      body = body,
      protocol_version = .protocol_version
    )
  )

  tre_normalize_output(
    result = result,
    output_label = .output_label,
    status_and_purpose = .status_and_purpose,
    function_name = .function_name
  )
}


