# Auto-generated wrappers for Entities, Relations, Transformations, Ingest

entity_delete <- function(client, domain = NULL, name = NULL, reason = NULL, actor = NULL, dry_run = NULL, yes = NULL, format = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
    "domain" = domain,
    "name" = name,
    "reason" = reason,
    "actor" = actor,
    "dry-run" = dry_run,
    "yes" = yes,
    "format" = format
  )
  tre_command_call(
    client = client,
    kind = "entity.delete",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Semantic delete plan or result",
    .status_and_purpose = "Physically delete an unused entity definition or block on relation, instance, mapping, and link dependencies.",
    .function_name = "entity_delete"
  )
}

entity_instance_asset_link_add <- function(client, study = NULL, width = NULL, format = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
    "study" = study,
    "width" = width,
    "format" = format
  )
  tre_command_call(
    client = client,
    kind = "entity.instance.asset-link.add",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Asset-link record or empty asset-link list",
    .status_and_purpose = "Manage and audit links between entity instances and asset versions.",
    .function_name = "entity_instance_asset_link_add"
  )
}

entity_instance_asset_link_list <- function(client, study = NULL, width = NULL, format = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
    "study" = study,
    "width" = width,
    "format" = format
  )
  tre_command_call(
    client = client,
    kind = "entity.instance.asset-link.list",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Asset-link record or empty asset-link list",
    .status_and_purpose = "Manage and audit links between entity instances and asset versions.",
    .function_name = "entity_instance_asset_link_list"
  )
}

entity_instance_dataset_link_add <- function(client, study = NULL, width = NULL, format = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
    "study" = study,
    "width" = width,
    "format" = format
  )
  tre_command_call(
    client = client,
    kind = "entity.instance.dataset-link.add",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Dataset-link record or empty dataset-link readback",
    .status_and_purpose = "Manage and audit links between entity instances and dataset variables.",
    .function_name = "entity_instance_dataset_link_add"
  )
}

entity_instance_dataset_link_get <- function(client, study = NULL, width = NULL, format = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
    "study" = study,
    "width" = width,
    "format" = format
  )
  tre_command_call(
    client = client,
    kind = "entity.instance.dataset-link.get",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Dataset-link record or empty dataset-link readback",
    .status_and_purpose = "Manage and audit links between entity instances and dataset variables.",
    .function_name = "entity_instance_dataset_link_get"
  )
}

entity_instance_dataset_link_list <- function(client, study = NULL, width = NULL, format = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
    "study" = study,
    "width" = width,
    "format" = format
  )
  tre_command_call(
    client = client,
    kind = "entity.instance.dataset-link.list",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Dataset-link record or empty dataset-link readback",
    .status_and_purpose = "Manage and audit links between entity instances and dataset variables.",
    .function_name = "entity_instance_dataset_link_list"
  )
}

entity_instance_datasets <- function(client, study = NULL, instance_id = NULL, width = NULL, format = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
    "study" = study,
    "instance-id" = instance_id,
    "width" = width,
    "format" = format
  )
  tre_command_call(
    client = client,
    kind = "entity.instance.datasets",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Dataset readback list",
    .status_and_purpose = "List dataset versions linked to an entity instance.",
    .function_name = "entity_instance_datasets"
  )
}

entity_instance_ensure <- function(client, study = NULL, dry_run = NULL, format = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
    "study" = study,
    "dry-run" = dry_run,
    "format" = format
  )
  tre_command_call(
    client = client,
    kind = "entity.instance.ensure-from-dataset",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Instance plan or result",
    .status_and_purpose = "Ensure entity instances from dataset rows.",
    .function_name = "entity_instance_ensure"
  )
}

entity_instance_add <- function(client, format = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
    "format" = format
  )
  tre_command_call(
    client = client,
    kind = "entity.instance.add",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Entity instance records",
    .status_and_purpose = "Inspect or register entity instances.",
    .function_name = "entity_instance_add"
  )
}

entity_instance_get <- function(client, format = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
    "format" = format
  )
  tre_command_call(
    client = client,
    kind = "entity.instance.get",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Entity instance records",
    .status_and_purpose = "Inspect or register entity instances.",
    .function_name = "entity_instance_get"
  )
}

entity_instance_list <- function(client, format = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
    "format" = format
  )
  tre_command_call(
    client = client,
    kind = "entity.instance.list",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Entity instance records",
    .status_and_purpose = "Inspect or register entity instances.",
    .function_name = "entity_instance_list"
  )
}

entity_instance_map_add <- function(client, width = NULL, format = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
    "width" = width,
    "format" = format
  )
  tre_command_call(
    client = client,
    kind = "entity.instance.map.add",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Mapping records or empty mapping list",
    .status_and_purpose = "Manage and audit study-scoped entity external-ID mappings.",
    .function_name = "entity_instance_map_add"
  )
}

entity_instance_map_get <- function(client, width = NULL, format = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
    "width" = width,
    "format" = format
  )
  tre_command_call(
    client = client,
    kind = "entity.instance.map.get",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Mapping records or empty mapping list",
    .status_and_purpose = "Manage and audit study-scoped entity external-ID mappings.",
    .function_name = "entity_instance_map_get"
  )
}

entity_instance_map_list <- function(client, width = NULL, format = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
    "width" = width,
    "format" = format
  )
  tre_command_call(
    client = client,
    kind = "entity.instance.map.list",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Mapping records or empty mapping list",
    .status_and_purpose = "Manage and audit study-scoped entity external-ID mappings.",
    .function_name = "entity_instance_map_list"
  )
}

entity_add <- function(client, format = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
    "format" = format
  )
  tre_command_call(
    client = client,
    kind = "entity.add",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Entity records",
    .status_and_purpose = "Manage semantic entity definitions.",
    .function_name = "entity_add"
  )
}

entity_get <- function(client, format = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
    "format" = format
  )
  tre_command_call(
    client = client,
    kind = "entity.get",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Entity records",
    .status_and_purpose = "Manage semantic entity definitions.",
    .function_name = "entity_get"
  )
}

entity_list <- function(client, format = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
    "format" = format
  )
  tre_command_call(
    client = client,
    kind = "entity.list",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Entity records",
    .status_and_purpose = "Manage semantic entity definitions.",
    .function_name = "entity_list"
  )
}

entity_search <- function(client, limit = NULL, width = NULL, format = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
    "limit" = limit,
    "width" = width,
    "format" = format
  )
  tre_command_call(
    client = client,
    kind = "entity.search",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Entity search results",
    .status_and_purpose = "Search bounded semantic entity definition summaries.",
    .function_name = "entity_search"
  )
}

entity_relation_delete <- function(client, domain = NULL, name = NULL, reason = NULL, actor = NULL, dry_run = NULL, yes = NULL, format = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
    "domain" = domain,
    "name" = name,
    "reason" = reason,
    "actor" = actor,
    "dry-run" = dry_run,
    "yes" = yes,
    "format" = format
  )
  tre_command_call(
    client = client,
    kind = "entity-relation.delete",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Semantic delete plan or result",
    .status_and_purpose = "Physically delete an unused relation definition or block on relation-instance, mapping, link, and history dependencies.",
    .function_name = "entity_relation_delete"
  )
}

entity_relation_instance_asset_link_add <- function(client, study = NULL, width = NULL, format = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
    "study" = study,
    "width" = width,
    "format" = format
  )
  tre_command_call(
    client = client,
    kind = "entity-relation.instance.asset-link.add",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Asset-link record or empty asset-link list",
    .status_and_purpose = "Manage and audit links between relation instances and asset versions.",
    .function_name = "entity_relation_instance_asset_link_add"
  )
}

entity_relation_instance_asset_link_list <- function(client, study = NULL, width = NULL, format = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
    "study" = study,
    "width" = width,
    "format" = format
  )
  tre_command_call(
    client = client,
    kind = "entity-relation.instance.asset-link.list",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Asset-link record or empty asset-link list",
    .status_and_purpose = "Manage and audit links between relation instances and asset versions.",
    .function_name = "entity_relation_instance_asset_link_list"
  )
}

entity_relation_instance_dataset_link_add <- function(client, study = NULL, width = NULL, format = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
    "study" = study,
    "width" = width,
    "format" = format
  )
  tre_command_call(
    client = client,
    kind = "entity-relation.instance.dataset-link.add",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Dataset-link record or empty dataset-link readback",
    .status_and_purpose = "Manage and audit links between relation instances and dataset variables, including endpoint and validity context.",
    .function_name = "entity_relation_instance_dataset_link_add"
  )
}

entity_relation_instance_dataset_link_get <- function(client, study = NULL, width = NULL, format = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
    "study" = study,
    "width" = width,
    "format" = format
  )
  tre_command_call(
    client = client,
    kind = "entity-relation.instance.dataset-link.get",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Dataset-link record or empty dataset-link readback",
    .status_and_purpose = "Manage and audit links between relation instances and dataset variables, including endpoint and validity context.",
    .function_name = "entity_relation_instance_dataset_link_get"
  )
}

entity_relation_instance_dataset_link_list <- function(client, study = NULL, width = NULL, format = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
    "study" = study,
    "width" = width,
    "format" = format
  )
  tre_command_call(
    client = client,
    kind = "entity-relation.instance.dataset-link.list",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Dataset-link record or empty dataset-link readback",
    .status_and_purpose = "Manage and audit links between relation instances and dataset variables, including endpoint and validity context.",
    .function_name = "entity_relation_instance_dataset_link_list"
  )
}

entity_relation_instance_ensure <- function(client, study = NULL, dry_run = NULL, format = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
    "study" = study,
    "dry-run" = dry_run,
    "format" = format
  )
  tre_command_call(
    client = client,
    kind = "entity-relation.instance.ensure-from-dataset",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Relation-instance plan or result",
    .status_and_purpose = "Ensure relation instances from dataset rows.",
    .function_name = "entity_relation_instance_ensure"
  )
}

entity_relation_instance_add <- function(client, format = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
    "format" = format
  )
  tre_command_call(
    client = client,
    kind = "entity-relation.instance.add",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Relation instance records",
    .status_and_purpose = "Inspect or register relation instances.",
    .function_name = "entity_relation_instance_add"
  )
}

entity_relation_instance_get <- function(client, format = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
    "format" = format
  )
  tre_command_call(
    client = client,
    kind = "entity-relation.instance.get",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Relation instance records",
    .status_and_purpose = "Inspect or register relation instances.",
    .function_name = "entity_relation_instance_get"
  )
}

entity_relation_instance_list <- function(client, format = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
    "format" = format
  )
  tre_command_call(
    client = client,
    kind = "entity-relation.instance.list",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Relation instance records",
    .status_and_purpose = "Inspect or register relation instances.",
    .function_name = "entity_relation_instance_list"
  )
}

entity_relation_instance_map_add <- function(client, width = NULL, format = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
    "width" = width,
    "format" = format
  )
  tre_command_call(
    client = client,
    kind = "entity-relation.instance.map.add",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Mapping records or empty mapping list",
    .status_and_purpose = "Manage and audit study-scoped relation external-ID mappings, including endpoint context.",
    .function_name = "entity_relation_instance_map_add"
  )
}

entity_relation_instance_map_get <- function(client, width = NULL, format = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
    "width" = width,
    "format" = format
  )
  tre_command_call(
    client = client,
    kind = "entity-relation.instance.map.get",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Mapping records or empty mapping list",
    .status_and_purpose = "Manage and audit study-scoped relation external-ID mappings, including endpoint context.",
    .function_name = "entity_relation_instance_map_get"
  )
}

entity_relation_instance_map_list <- function(client, width = NULL, format = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
    "width" = width,
    "format" = format
  )
  tre_command_call(
    client = client,
    kind = "entity-relation.instance.map.list",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Mapping records or empty mapping list",
    .status_and_purpose = "Manage and audit study-scoped relation external-ID mappings, including endpoint context.",
    .function_name = "entity_relation_instance_map_list"
  )
}

entity_relation_add <- function(client, format = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
    "format" = format
  )
  tre_command_call(
    client = client,
    kind = "entity-relation.add",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Relation records",
    .status_and_purpose = "Manage semantic relation definitions.",
    .function_name = "entity_relation_add"
  )
}

entity_relation_get <- function(client, format = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
    "format" = format
  )
  tre_command_call(
    client = client,
    kind = "entity-relation.get",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Relation records",
    .status_and_purpose = "Manage semantic relation definitions.",
    .function_name = "entity_relation_get"
  )
}

entity_relation_list <- function(client, format = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
    "format" = format
  )
  tre_command_call(
    client = client,
    kind = "entity-relation.list",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Relation records",
    .status_and_purpose = "Manage semantic relation definitions.",
    .function_name = "entity_relation_list"
  )
}

entity_relation_search <- function(client, limit = NULL, width = NULL, format = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
    "limit" = limit,
    "width" = width,
    "format" = format
  )
  tre_command_call(
    client = client,
    kind = "entity-relation.search",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Relation search results",
    .status_and_purpose = "Search bounded semantic relation definition summaries with source/target endpoint context.",
    .function_name = "entity_relation_search"
  )
}

ingest_datafile <- function(client, study = NULL, asset = NULL, path_or_uri = NULL, output_format = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
    "study" = study,
    "asset" = asset,
    "path or --uri" = path_or_uri,
    "output-format" = output_format
  )
  tre_command_call(
    client = client,
    kind = "ingest.datafile",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Ingest result",
    .status_and_purpose = "Register and copy or reference a managed datafile.",
    .function_name = "ingest_datafile"
  )
}

ingest_dataset_datafile <- function(client, study = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
    "study" = study
  )
  tre_command_call(
    client = client,
    kind = "ingest.dataset.from-datafile",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Materialization result",
    .status_and_purpose = "Materialize a dataset asset from a managed datafile.",
    .function_name = "ingest_dataset_datafile"
  )
}

ingest_dataset_sql <- function(client, study = NULL, format = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
    "study" = study,
    "format" = format
  )
  tre_command_call(
    client = client,
    kind = "ingest.dataset.from-sql",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Dataset ingest result",
    .status_and_purpose = "Materialize a dataset from SQL source data.",
    .function_name = "ingest_dataset_sql"
  )
}

ingest_dataset_table <- function(client, study = NULL, path_or_uri = NULL, output_format = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
    "study" = study,
    "path or --uri" = path_or_uri,
    "output-format" = output_format
  )
  tre_command_call(
    client = client,
    kind = "ingest.dataset.table",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Dataset ingest result",
    .status_and_purpose = "Ingest an external table source directly as a dataset asset.",
    .function_name = "ingest_dataset_table"
  )
}

ingest_redcap_project <- function(client, study = NULL, domain = NULL, format = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
    "study" = study,
    "domain" = domain,
    "format" = format
  )
  tre_command_call(
    client = client,
    kind = "ingest.redcap.project",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "REDCap ingest result",
    .status_and_purpose = "Ingest REDCap project artifacts and materialized form datasets.",
    .function_name = "ingest_redcap_project"
  )
}

transformation_list <- function(client, study = NULL, format = NULL, ..., .body = NULL, .protocol_version = TRE_PROTOCOL_VERSION) {
  auto_fields <- list(
    "study" = study,
    "format" = format
  )
  tre_command_call(
    client = client,
    kind = "transformation.list",
    ...,
    .auto_fields = auto_fields,
    .body = .body,
    .protocol_version = .protocol_version,
    .output_label = "Transformation summary list",
    .status_and_purpose = "List transformations that produced versions in the resolved study.",
    .function_name = "transformation_list"
  )
}

