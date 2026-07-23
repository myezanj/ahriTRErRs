TRE_PROTOCOL_VERSION <- "1.0.0"
TRE_COMMAND_KIND_MAP <- list(
  "asset_delete" = "asset.delete",
  "asset_duo_clear" = "asset.duo.clear",
  "asset_duo_list" = "asset.duo.list",
  "asset_duo_replace" = "asset.duo.replace",
  "asset_get" = "asset.get",
  "asset_list" = "asset.list",
  "asset_versions" = "asset.versions",
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
  "auth_login" = "auth.login",
  "auth_logout" = "auth.logout",
  "auth_status" = "auth.status",
  "daemon_doctor" = "daemon.doctor",
  "daemon_start" = "daemon.start",
  "daemon_status" = "daemon.status",
  "daemon_stop" = "daemon.stop",
  "daemon_version" = "daemon.version",
  "session_close" = "session.close.[name]",
  "session_list" = "session.list",
  "session_open" = "session.open-oauth",
  "session_reopen" = "session.reopen",
  "session_status" = "session.status.[name]",
  "session_use" = "session.use",
  "datastore_adopt" = "datastore.adopt",
  "datastore_create" = "datastore.create",
  "datastore_info" = "datastore.info",
  "datastore_list" = "datastore.list",
  "datastore_ping" = "datastore.ping",
  "datastore_rotate" = "datastore.rotate-lake-credential",
  "datastore_schema" = "datastore.schema-status",
  "domain_add" = "domain.add",
  "domain_delete" = "domain.delete",
  "domain_get" = "domain.get",
  "domain_list" = "domain.list",
  "tag_get" = "tag.get",
  "tag_list" = "tag.list",
  "tag_set" = "tag.set",
  "variable_add" = "variable.add",
  "variable_delete" = "variable.delete",
  "variable_get" = "variable.get",
  "variable_list" = "variable.list",
  "variable_search" = "variable.search",
  "variable_update" = "variable.update",
  "vocabulary_add" = "vocabulary.add",
  "vocabulary_delete" = "vocabulary.delete",
  "vocabulary_get" = "vocabulary.get",
  "vocabulary_list" = "vocabulary.list",
  "entity_delete" = "entity.delete",
  "entity_instance_asset_link_add" = "entity.instance.asset-link.add",
  "entity_instance_asset_link_list" = "entity.instance.asset-link.list",
  "entity_instance_dataset_link_add" = "entity.instance.dataset-link.add",
  "entity_instance_dataset_link_get" = "entity.instance.dataset-link.get",
  "entity_instance_dataset_link_list" = "entity.instance.dataset-link.list",
  "entity_instance_datasets" = "entity.instance.datasets",
  "entity_instance_ensure" = "entity.instance.ensure-from-dataset",
  "entity_instance_add" = "entity.instance.add",
  "entity_instance_get" = "entity.instance.get",
  "entity_instance_list" = "entity.instance.list",
  "entity_instance_map_add" = "entity.instance.map.add",
  "entity_instance_map_get" = "entity.instance.map.get",
  "entity_instance_map_list" = "entity.instance.map.list",
  "entity_add" = "entity.add",
  "entity_get" = "entity.get",
  "entity_list" = "entity.list",
  "entity_search" = "entity.search",
  "entity_relation_delete" = "entity-relation.delete",
  "entity_relation_instance_asset_link_add" = "entity-relation.instance.asset-link.add",
  "entity_relation_instance_asset_link_list" = "entity-relation.instance.asset-link.list",
  "entity_relation_instance_dataset_link_add" = "entity-relation.instance.dataset-link.add",
  "entity_relation_instance_dataset_link_get" = "entity-relation.instance.dataset-link.get",
  "entity_relation_instance_dataset_link_list" = "entity-relation.instance.dataset-link.list",
  "entity_relation_instance_ensure" = "entity-relation.instance.ensure-from-dataset",
  "entity_relation_instance_add" = "entity-relation.instance.add",
  "entity_relation_instance_get" = "entity-relation.instance.get",
  "entity_relation_instance_list" = "entity-relation.instance.list",
  "entity_relation_instance_map_add" = "entity-relation.instance.map.add",
  "entity_relation_instance_map_get" = "entity-relation.instance.map.get",
  "entity_relation_instance_map_list" = "entity-relation.instance.map.list",
  "entity_relation_add" = "entity-relation.add",
  "entity_relation_get" = "entity-relation.get",
  "entity_relation_list" = "entity-relation.list",
  "entity_relation_search" = "entity-relation.search",
  "ingest_datafile" = "ingest.datafile",
  "ingest_dataset_datafile" = "ingest.dataset.from-datafile",
  "ingest_dataset_sql" = "ingest.dataset.from-sql",
  "ingest_dataset_table" = "ingest.dataset.table",
  "ingest_redcap_project" = "ingest.redcap.project",
  "transformation_list" = "transformation.list",
  "completion" = "completion",
  "doctor" = "doctor",
  "schema_get" = "schema.get",
  "schema_list" = "schema.list",
  "version" = "version",
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
  "study_use" = "study.use"
)
compact_null_fields <- function(x) x[!vapply(x, is.null, logical(1))]
merge_request_body <- function(auto_fields=list(), dot_fields=list(), explicit_body=NULL) {
  if (!is.null(explicit_body)) return(explicit_body)
  body <- compact_null_fields(auto_fields); dots <- compact_null_fields(dot_fields)
  if (length(dots)==0) return(body)
  named <- names(dots); if (is.null(named)) return(c(body, dots))
  for (i in seq_along(dots)) { key <- names(dots)[[i]]; if (!is.null(key) && nzchar(key)) body[[key]] <- dots[[i]] }
  body
}
new_tre_protocol_request <- function(kind, body=list(), protocol_version=TRE_PROTOCOL_VERSION) {
  list(protocol_version=protocol_version, kind=kind, body=body%||%list())
}
tre_result_ok <- function(envelope) { ok <- envelope$ok; if (is.logical(ok) && length(ok)==1) return(isTRUE(ok)); is.null(envelope$error) && is.null(envelope$failure) }
tre_extract_data <- function(envelope) { for (key in c("data","result","output","body")) if (!is.null(envelope[[key]])) return(envelope[[key]]); envelope }
tre_coerce_r_object <- function(value) { if (is.null(value) || is.data.frame(value)) return(value); if (is.character(value) && length(value)==1 && nzchar(value)) { parsed <- try(jsonlite::fromJSON(value, simplifyDataFrame=TRUE), silent=TRUE); if (!inherits(parsed,"try-error")) return(parsed) }; value }
tre_coerce_data_frame <- function(value) { value <- tre_coerce_r_object(value); if (is.null(value) || is.data.frame(value)) return(value); if (is.list(value)) { for (cand in c("items","rows","data","result","output","body","studies","datasets","datafiles","entities","domains","variables")) { if (!is.null(value[[cand]])) { df <- tre_coerce_data_frame(value[[cand]]); if (!is.null(df)) return(df) } }; as_df <- try(jsonlite::fromJSON(jsonlite::toJSON(value, auto_unbox=TRUE), simplifyDataFrame=TRUE), silent=TRUE); if (!inherits(as_df,"try-error") && is.data.frame(as_df)) return(as_df) }; NULL }
tre_is_invalid_request_envelope <- function(envelope) { if (is.null(envelope) || !is.list(envelope)) return(FALSE); msg <- envelope$error$message %||% envelope$message %||% ""; (identical(envelope$kind%||%"","protocol.invalid_request") && grepl("request envelope is invalid", msg, fixed=TRUE)) || grepl("protocol request kind is not supported", msg, fixed=TRUE) }
tre_is_no_live_session_envelope <- function(envelope) { if (is.null(envelope) || !is.list(envelope)) return(FALSE); grepl("no live session is selected", envelope$error$message %||% envelope$message %||% "", fixed=TRUE) }
tre_is_no_live_session_message <- function(msg) is.character(msg) && length(msg)>=1 && grepl("no live session is selected", msg[[1]], fixed=TRUE)
tre_is_no_live_session_error <- function(err) inherits(err,"error") && tre_is_no_live_session_message(conditionMessage(err))
tre_is_daemon_connection_envelope <- function(envelope) { if (is.null(envelope) || !is.list(envelope)) return(FALSE); msg <- envelope$error$message %||% envelope$message %||% ""; any(vapply(c("daemon closed the protocol connection","daemon socket","stale"), function(p) grepl(p, msg, fixed=TRUE), logical(1))) }
tre_is_daemon_connection_message <- function(msg) is.character(msg) && length(msg)>=1 && any(vapply(c("daemon closed the protocol connection","daemon socket","stale"), function(p) grepl(p, msg[[1]], fixed=TRUE), logical(1)))
tre_is_daemon_connection_error <- function(err) inherits(err,"error") && tre_is_daemon_connection_message(conditionMessage(err))
tre_auto_session_enabled <- function() !(tolower(Sys.getenv("AHRI_TRE_AUTO_SESSION_USE","true")) %in% c("0","false","no","off"))
tre_is_read_like_kind <- function(kind) is.character(kind) && length(kind)==1 && nzchar(kind) && grepl("(\\.list$|\\.get$|\\.search$|\\.preview$|\\.metadata$|\\.status$|^version$|\\.current$)", kind)
tre_soft_no_live_session_enabled <- function(kind) { flag <- tolower(trimws(as.character(getOption("ahriTRErRs.soft_no_live_session", Sys.getenv("AHRI_TRE_SOFT_NO_LIVE_SESSION","true"))))); if (flag %in% c("0","false","no","off")) return(FALSE); tre_is_read_like_kind(kind) }
tre_cli_binary <- function() { root <- Sys.getenv("AHRI_TRE_RUNTIME_ROOT","/opt/ahri-tre-runtime"); path <- file.path(normalizePath(path.expand(root), mustWork=FALSE), "bin", "ahri-tre"); if (file.exists(path)) path else NULL }
tre_parse_first_json_object <- function(lines) { if (length(lines)==0) return(NULL); text <- paste(lines, collapse="\n"); start <- regexpr("\\{", text); if (start[[1]] < 1) return(NULL); parsed <- try(jsonlite::fromJSON(substr(text, start[[1]], nchar(text)), simplifyVector=FALSE), silent=TRUE); if (inherits(parsed,"try-error")) NULL else parsed }
tre_cli_args_from_body <- function(kind, body) { tokens <- strsplit(kind, ".", fixed=TRUE)[[1]]; args <- as.list(tokens); if (length(body)==0) return(unlist(args)); for (key in names(body)) { value <- body[[key]]; if (is.null(value)) next; cli_key <- gsub("_", "-", key); flag <- paste0("--", cli_key); if (is.logical(value) && length(value)==1) { if (isTRUE(value)) args <- c(args, flag); next }; if (length(value)==0 || is.list(value)) next; for (item in as.character(value)) args <- c(args, flag, shQuote(item, type="sh")) }; unlist(args) }
tre_execute_via_cli <- function(kind, body) { bin <- tre_cli_binary(); if (is.null(bin)) return(NULL); root <- Sys.getenv("AHRI_TRE_RUNTIME_ROOT","/opt/ahri-tre-runtime"); lib <- file.path(normalizePath(path.expand(root), mustWork=FALSE), "lib"); env <- c(paste0("LD_LIBRARY_PATH=", paste(c(lib, Sys.getenv("LD_LIBRARY_PATH")), collapse=":"))); args <- tre_cli_args_from_body(kind, body); out <- suppressWarnings(system2(bin, args=args, stdout=TRUE, stderr=TRUE, env=env)); parsed <- tre_parse_first_json_object(out); if (is.null(parsed)) return(NULL); if (isTRUE(parsed$ok)) envelope <- list(ok=TRUE, kind=parsed$command%||%kind, data=parsed$data%||%list()) else envelope <- list(ok=FALSE, kind=parsed$command%||%kind, error=list(code=parsed$code%||%"cli_error", message=parsed$error$message%||%parsed$message%||%"CLI command failed")); list(envelope=envelope, payloads=list()) }
tre_cli_try_activate_live_session <- function() { bin <- tre_cli_binary(); if (is.null(bin)) return(FALSE); root <- Sys.getenv("AHRI_TRE_RUNTIME_ROOT","/opt/ahri-tre-runtime"); lib <- file.path(normalizePath(path.expand(root), mustWork=FALSE), "lib"); env <- c(paste0("LD_LIBRARY_PATH=", paste(c(lib, Sys.getenv("LD_LIBRARY_PATH")), collapse=":"))); out <- suppressWarnings(system2(bin, args=c("session","list","--format","json"), stdout=TRUE, stderr=TRUE, env=env)); j <- tre_parse_first_json_object(out); if (is.null(j) || !isTRUE(j$ok)) return(FALSE); sessions <- j$data$sessions; if (is.null(sessions) || length(sessions)==0) return(FALSE); name <- NULL; for (s in sessions) if (identical(s$availability%||%"","live")) { name <- s$session$name%||%NULL; if (is.character(name) && nzchar(name)) break; name <- NULL }; if (is.null(name)) { for (s in sessions) { n <- s$session$name%||%NULL; if (!is.character(n) || !nzchar(n)) next; if (!identical(s$availability%||%"","live") && grepl("oauth", s$auth_mode%||%"", ignore.case=TRUE)) { ro <- suppressWarnings(system2(bin, args=c("session","reopen",n,"--format","json"), stdout=TRUE, stderr=TRUE, env=env)); rj <- tre_parse_first_json_object(ro); if (isTRUE(rj$ok)) { name <- n; break } } } }; if (is.null(name)) return(FALSE); use <- suppressWarnings(system2(bin, args=c("session","use",name,"--format","json"), stdout=TRUE, stderr=TRUE, env=env)); uj <- tre_parse_first_json_object(use); isTRUE(uj$ok) }
tre_cli_try_restart_daemon <- function() { bin <- tre_cli_binary(); if (is.null(bin)) return(FALSE); root <- Sys.getenv("AHRI_TRE_RUNTIME_ROOT","/opt/ahri-tre-runtime"); lib <- file.path(normalizePath(path.expand(root), mustWork=FALSE), "lib"); env <- c(paste0("LD_LIBRARY_PATH=", paste(c(lib, Sys.getenv("LD_LIBRARY_PATH")), collapse=":"))); out <- suppressWarnings(system2(bin, args=c("daemon","start","--format","json"), stdout=TRUE, stderr=TRUE, env=env)); j <- tre_parse_first_json_object(out); isTRUE(j$ok) }
tre_wrapper_return_mode <- function() { mode <- getOption("ahriTRErRs.return_mode", Sys.getenv("AHRI_TRE_R_RETURN_MODE","data.frame")); mode <- tolower(trimws(as.character(mode[[1]]%||%"data.frame"))); if (mode %in% c("data.frame","dataframe","df")) return("data.frame"); if (mode %in% c("object","raw")) return("object"); if (mode %in% c("json","string")) return("json"); "data.frame" }
tre_coerce_json <- function(raw, obj) { if (is.character(raw) && length(raw)==1 && nzchar(raw)) return(raw); jsonlite::toJSON(obj, auto_unbox=TRUE, null="null") }
tre_normalize_output <- function(result, output_label=NULL, status_and_purpose=NULL, function_name=NULL) { envelope <- result$envelope%||%list(); if (!tre_result_ok(envelope)) { failure <- protocol_failure_summary(envelope); abort_ahri_tre(sprintf("%s failed: %s", function_name%||%"TRE command", failure$message), class="ahri_tre_protocol_error") }; raw <- tre_extract_data(envelope); obj <- tre_coerce_r_object(raw); df <- tre_coerce_data_frame(obj); mode <- tre_wrapper_return_mode(); data <- switch(mode, json=tre_coerce_json(raw,obj), object=obj, if (!is.null(df)) df else obj); structure(list(function_name=function_name, output_label=output_label, status_and_purpose=status_and_purpose, data=data, object=obj, data_frame=df, envelope=envelope, payloads=result$payloads%||%list()), class="ahri_tre_wrapper_result") }
tre_command_call <- function(client, kind, ..., .auto_fields=list(), .body=NULL, .protocol_version=TRE_PROTOCOL_VERSION, .output_label=NULL, .status_and_purpose=NULL, .function_name=NULL) { body <- merge_request_body(auto_fields=.auto_fields, dot_fields=list(...), explicit_body=.body); request <- new_tre_protocol_request(kind=kind, body=body, protocol_version=.protocol_version); result <- tryCatch(execute_json(client=client, request=request), error=function(err) err); used_cli <- FALSE; if (inherits(result,"error")) { if (tre_auto_session_enabled() && tre_is_no_live_session_error(result)) { if (tre_cli_try_activate_live_session()) result <- tryCatch(execute_json(client=client, request=request), error=function(err) err) }; if (inherits(result,"error") && tre_is_no_live_session_error(result)) { cli <- tre_execute_via_cli(kind=kind, body=body); if (!is.null(cli)) { result <- cli; used_cli <- TRUE } }; if (inherits(result,"error") && tre_auto_session_enabled() && tre_is_daemon_connection_error(result)) { if (tre_cli_try_restart_daemon()) result <- tryCatch(execute_json(client=client, request=request), error=function(err) err) }; if (inherits(result,"error")) stop(result) }; if (tre_is_invalid_request_envelope(result$envelope%||%list())) { cli <- tre_execute_via_cli(kind=kind, body=body); if (!is.null(cli)) { result <- cli; used_cli <- TRUE } }; if (tre_auto_session_enabled() && tre_is_no_live_session_envelope(result$envelope%||%list())) { if (tre_cli_try_activate_live_session()) { if (used_cli) { cli <- tre_execute_via_cli(kind=kind, body=body); if (!is.null(cli)) result <- cli } else { result <- execute_json(client=client, request=request); if (tre_is_invalid_request_envelope(result$envelope%||%list())) { cli <- tre_execute_via_cli(kind=kind, body=body); if (!is.null(cli)) result <- cli } } } }; if (tre_is_no_live_session_envelope(result$envelope%||%list())) { cli <- tre_execute_via_cli(kind=kind, body=body); if (!is.null(cli)) { result <- cli; used_cli <- TRUE } }; if (tre_auto_session_enabled() && tre_is_daemon_connection_envelope(result$envelope%||%list())) { if (tre_cli_try_restart_daemon()) { if (used_cli) { cli <- tre_execute_via_cli(kind=kind, body=body); if (!is.null(cli)) result <- cli } else { result <- execute_json(client=client, request=request); if (tre_is_invalid_request_envelope(result$envelope%||%list())) { cli <- tre_execute_via_cli(kind=kind, body=body); if (!is.null(cli)) result <- cli } } } }; if (tre_is_no_live_session_envelope(result$envelope%||%list()) && tre_soft_no_live_session_enabled(kind)) { warning(sprintf("%s: no live session selected; returning empty result", .function_name%||%kind), call.=FALSE); result$envelope <- list(ok=TRUE, kind=kind, data=list()) }; tre_normalize_output(result=result, output_label=.output_label, status_and_purpose=.status_and_purpose, function_name=.function_name) }
