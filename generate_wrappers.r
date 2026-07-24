#!/usr/bin/env Rscript

if (file.exists(".env")) readRenviron(".env")

# Install required packages if missing
for (pkg in c("jsonlite", "roxygen2")) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
}
library(jsonlite)
library(roxygen2)

# ----------------------------------------------------------------------------
# Generate wrappers from schema (if present)
# ----------------------------------------------------------------------------
generate_wrappers <- function(schema = "docs/tre_schema_map.json") {
  if (!file.exists(schema)) {
    cat("[INFO] Schema not found, skipping wrapper generation.\n")
    return(invisible(FALSE))
  }
  cat("[INFO] Generating wrappers from", schema, "\n")
  json <- jsonlite::read_json(schema, simplifyVector = FALSE)

  norm <- function(x) {
    x <- trimws(tolower(x))
    x <- gsub("^[-\\s]+|[^a-z0-9]+", "_", x)
    x <- gsub("^_+|_+$", "", x)
    if (x == "") return(NULL)
    if (grepl("^[0-9]", x)) x <- paste0("x_", x)
    gsub("_{2,}", "_", x)
  }

  parse_cmd <- function(cmd) {
    if (is.null(cmd) || cmd == "") return(list())
    m <- gregexpr("<[^>]+>|\\[[^\\]]+\\]", cmd)
    if (m[[1]][1] == -1) return(list())
    parts <- regmatches(cmd, m)[[1]]
    params <- list()
    for (p in parts) {
      raw <- gsub("^[<\\[]|[>\\]]$", "", p)
      n <- norm(raw)
      if (!is.null(n)) params[[n]] <- list(param = n, key = n)
    }
    params
  }

  parse_imp <- function(inp) {
    if (is.null(inp) || inp == "") return(list())
    # Split by comma first - this is the primary format in importantInputs
    params <- list()
    split_items <- strsplit(inp, ",")[[1]]
    for (item in split_items) {
      # Replace non-breaking spaces (c2a0 in UTF-8, U+00A0) with regular spaces
      item <- gsub("\u00A0", " ", item)
      item <- trimws(item)
      if (item == "") next
      # Remove "optional" prefix and trim again
      item <- trimws(gsub("^optional\\s+", "", item, ignore.case=TRUE))
      if (item == "") next
      # Extract --flagname, convert to param name
      if (grepl("^--", item)) {
        key <- trimws(gsub("^--", "", item))
        n <- norm(key)
        if (!is.null(n)) params[[n]] <- list(param = n, key = key)
      }
    }
    res <- list(); seen <- c()
    for (p in params) {
      if (!(p$param %in% seen) && !(p$param %in% c("client","...",".body",".protocol_version"))) {
        seen <- c(seen, p$param)
        res[[length(res)+1]] <- p
      }
    }
    res
  }

  kind_from <- function(cmd, fun) {
    if (is.null(cmd) || cmd == "") return(gsub("_", ".", fun))
    without <- gsub("<[^>]+>|\\[[^\\]]+\\]", "", cmd)
    parts <- trimws(strsplit(without, "\\s+")[[1]])
    parts <- parts[nzchar(parts)]
    if (length(parts) == 0) return(gsub("_", ".", fun))
    fun_tokens <- strsplit(tolower(fun), "_")[[1]]
    resolved <- c()
    for (p in parts) {
      if (grepl("\\|", p)) {
        choices <- trimws(strsplit(p, "\\|")[[1]])
        chosen <- choices[1]
        for (ch in choices) {
          if (gsub("-", "_", ch) %in% fun_tokens) {
            chosen <- ch
            break
          }
        }
        p <- chosen
      }
      resolved <- c(resolved, p)
    }
    paste(resolved, collapse = ".")
  }

  rows <- list()
  for (cat in names(json$categories)) {
    cat_data <- json$categories[[cat]]
    # Handle both data frame and list formats
    if (is.data.frame(cat_data)) {
      for (i in seq_len(nrow(cat_data))) {
        item <- as.list(cat_data[i, ])
        # CRITICAL: closing parenthesis is present
        fun <- trimws(item[["function"]])
        status <- trimws(item$statusAndPurpose)
        if (fun != "" && status != "" && cat != "Runtime") {
          rows <- c(rows, list(list(
            Function = fun,
            Command = trimws(item$command),
            Category = cat,
            StudyContext = trimws(item$studyContext),
            ImportantInputs = trimws(item$importantInputs),
            Output = trimws(item$output),
            StatusAndPurpose = status
          )))
        }
      }
    } else {
      for (item in cat_data) {
        # CRITICAL: closing parenthesis is present
        fun <- trimws(item[["function"]])
        status <- trimws(item$statusAndPurpose)
        if (fun != "" && status != "" && cat != "Runtime") {
          rows <- c(rows, list(list(
            Function = fun,
            Command = trimws(item$command),
            Category = cat,
            StudyContext = trimws(item$studyContext),
            ImportantInputs = trimws(item$importantInputs),
            Output = trimws(item$output),
            StatusAndPurpose = status
          )))
        }
      }
    }
  }
  rows <- rows[!duplicated(sapply(rows, function(x) x$Function))]

  kind_rows <- list()
  for (row in rows) kind_rows[[row$Function]] <- kind_from(row$Command, row$Function)

  # Write core.R
  core <- c(
    "TRE_PROTOCOL_VERSION <- \"1.0.0\"",
    "TRE_COMMAND_KIND_MAP <- list(",
    paste0("  \"", names(kind_rows), "\" = \"", unlist(kind_rows), "\"", collapse = ",\n"),
    ")",
    "compact_null_fields <- function(x) x[!vapply(x, is.null, logical(1))]",
    "tre_normalize_body_key <- function(key) {",
    "  if (is.null(key) || !nzchar(key)) return(key)",
    "  normalized <- sub(\"^-+\", \"\", key)",
    "  gsub(\"-\", \"_\", normalized)",
    "}",
    "tre_normalize_body_fields <- function(fields) {",
    "  if (length(fields) == 0) return(fields)",
    "  nms <- names(fields)",
    "  if (is.null(nms)) return(fields)",
    "",
    "  out <- list()",
    "  for (i in seq_along(fields)) {",
    "    key <- nms[[i]]",
    "    val <- fields[[i]]",
    "    if (is.null(key) || !nzchar(key)) {",
    "      out[[length(out) + 1L]] <- val",
    "      next",
    "    }",
    "    out[[tre_normalize_body_key(key)]] <- val",
    "  }",
    "  out",
    "}",
    "merge_request_body <- function(auto_fields=list(), dot_fields=list(), explicit_body=NULL) {",
    "  if (!is.null(explicit_body)) return(tre_normalize_body_fields(explicit_body))",
    "  body <- tre_normalize_body_fields(compact_null_fields(auto_fields)); dots <- tre_normalize_body_fields(compact_null_fields(dot_fields))",
    "  if (length(dots)==0) return(body)",
    "  named <- names(dots); if (is.null(named)) return(c(body, dots))",
    "  for (i in seq_along(dots)) { key <- names(dots)[[i]]; if (!is.null(key) && nzchar(key)) body[[key]] <- dots[[i]] }",
    "  body",
    "}",
    "new_tre_protocol_request <- function(kind, body=list(), protocol_version=TRE_PROTOCOL_VERSION) {",
    "  list(protocol_version=protocol_version, kind=kind, body=body%||%list())",
    "}",
    "tre_result_ok <- function(envelope) { ok <- envelope$ok; if (is.logical(ok) && length(ok)==1) return(isTRUE(ok)); is.null(envelope$error) && is.null(envelope$failure) }",
    "tre_extract_data <- function(envelope) { for (key in c(\"data\",\"result\",\"output\",\"body\")) if (!is.null(envelope[[key]])) return(envelope[[key]]); envelope }",
    "tre_coerce_r_object <- function(value) { if (is.null(value) || is.data.frame(value)) return(value); if (is.character(value) && length(value)==1 && nzchar(value)) { parsed <- try(jsonlite::fromJSON(value, simplifyDataFrame=TRUE), silent=TRUE); if (!inherits(parsed,\"try-error\")) return(parsed) }; value }",
    "tre_coerce_data_frame <- function(value) { value <- tre_coerce_r_object(value); if (is.null(value) || is.data.frame(value)) return(value); if (is.list(value)) { for (cand in c(\"items\",\"rows\",\"data\",\"result\",\"output\",\"body\",\"studies\",\"datasets\",\"datafiles\",\"entities\",\"domains\",\"variables\")) { if (!is.null(value[[cand]])) { df <- tre_coerce_data_frame(value[[cand]]); if (!is.null(df)) return(df) } }; as_df <- try(jsonlite::fromJSON(jsonlite::toJSON(value, auto_unbox=TRUE), simplifyDataFrame=TRUE), silent=TRUE); if (!inherits(as_df,\"try-error\") && is.data.frame(as_df)) return(as_df) }; NULL }",
    "tre_is_invalid_request_envelope <- function(envelope) { if (is.null(envelope) || !is.list(envelope)) return(FALSE); msg <- envelope$error$message %||% envelope$message %||% \"\"; (identical(envelope$kind%||%\"\",\"protocol.invalid_request\") && grepl(\"request envelope is invalid\", msg, fixed=TRUE)) || grepl(\"protocol request kind is not supported\", msg, fixed=TRUE) }",
    "tre_is_no_live_session_envelope <- function(envelope) { if (is.null(envelope) || !is.list(envelope)) return(FALSE); grepl(\"no live session is selected\", envelope$error$message %||% envelope$message %||% \"\", fixed=TRUE) }",
    "tre_is_no_live_session_message <- function(msg) is.character(msg) && length(msg)>=1 && grepl(\"no live session is selected\", msg[[1]], fixed=TRUE)",
    "tre_is_no_live_session_error <- function(err) inherits(err,\"error\") && tre_is_no_live_session_message(conditionMessage(err))",
    "tre_is_daemon_connection_envelope <- function(envelope) { if (is.null(envelope) || !is.list(envelope)) return(FALSE); msg <- envelope$error$message %||% envelope$message %||% \"\"; any(vapply(c(\"daemon closed the protocol connection\",\"daemon socket\",\"stale\"), function(p) grepl(p, msg, fixed=TRUE), logical(1))) }",
    "tre_is_daemon_connection_message <- function(msg) is.character(msg) && length(msg)>=1 && any(vapply(c(\"daemon closed the protocol connection\",\"daemon socket\",\"stale\"), function(p) grepl(p, msg[[1]], fixed=TRUE), logical(1)))",
    "tre_is_daemon_connection_error <- function(err) inherits(err,\"error\") && tre_is_daemon_connection_message(conditionMessage(err))",
    "tre_auto_session_enabled <- function() !(tolower(Sys.getenv(\"AHRI_TRE_AUTO_SESSION_USE\",\"true\")) %in% c(\"0\",\"false\",\"no\",\"off\"))",
    "tre_is_read_like_kind <- function(kind) is.character(kind) && length(kind)==1 && nzchar(kind) && grepl(\"(\\\\\\\\.list$|\\\\\\\\.get$|\\\\\\\\.search$|\\\\\\\\.preview$|\\\\\\\\.metadata$|\\\\\\\\.status$|^version$|\\\\\\\\.current$)\", kind)",
    "tre_soft_no_live_session_enabled <- function(kind) { flag <- tolower(trimws(as.character(getOption(\"ahriTRErRs.soft_no_live_session\", Sys.getenv(\"AHRI_TRE_SOFT_NO_LIVE_SESSION\",\"true\"))))); if (flag %in% c(\"0\",\"false\",\"no\",\"off\")) return(FALSE); tre_is_read_like_kind(kind) }",
    "tre_cli_binary <- function() { root <- Sys.getenv(\"AHRI_TRE_RUNTIME_ROOT\",\"/opt/ahri-tre-runtime\"); path <- file.path(normalizePath(path.expand(root), mustWork=FALSE), \"bin\", \"ahri-tre\"); if (file.exists(path)) path else NULL }",
    "tre_parse_first_json_object <- function(lines) { if (length(lines)==0) return(NULL); text <- paste(lines, collapse=\"\\n\"); start <- regexpr(\"\\\\{\", text); if (start[[1]] < 1) return(NULL); parsed <- try(jsonlite::fromJSON(substr(text, start[[1]], nchar(text)), simplifyVector=FALSE), silent=TRUE); if (inherits(parsed,\"try-error\")) NULL else parsed }",
    "tre_cli_args_from_body <- function(kind, body) { tokens <- strsplit(kind, \"\\\\\\\\.\" , fixed=FALSE)[[1]]; args <- as.list(tokens); if (length(body)==0) return(unlist(args)); for (key in names(body)) { value <- body[[key]]; if (is.null(value)) next; cli_key <- gsub(\"_\", \"-\", tre_normalize_body_key(key)); flag <- paste0(\"--\", cli_key); if (is.logical(value) && length(value)==1) { if (isTRUE(value)) args <- c(args, flag); next }; if (length(value)==0 || is.list(value)) next; for (item in as.character(value)) args <- c(args, flag, item) }; unlist(args) }",
    "tre_execute_via_cli <- function(kind, body) { bin <- tre_cli_binary(); if (is.null(bin)) return(NULL); root <- Sys.getenv(\"AHRI_TRE_RUNTIME_ROOT\",\"/opt/ahri-tre-runtime\"); lib <- file.path(normalizePath(path.expand(root), mustWork=FALSE), \"lib\"); env <- c(paste0(\"LD_LIBRARY_PATH=\", paste(c(lib, Sys.getenv(\"LD_LIBRARY_PATH\")), collapse=\":\"))); args <- tre_cli_args_from_body(kind, body); out <- suppressWarnings(system2(bin, args=args, stdout=TRUE, stderr=TRUE, env=env)); parsed <- tre_parse_first_json_object(out); if (is.null(parsed)) return(NULL); if (isTRUE(parsed$ok)) envelope <- list(ok=TRUE, kind=parsed$command%||%kind, data=parsed$data%||%list()) else envelope <- list(ok=FALSE, kind=parsed$command%||%kind, error=list(code=parsed$code%||%\"cli_error\", message=parsed$error$message%||%parsed$message%||%\"CLI command failed\")); list(envelope=envelope, payloads=list()) }",
    "tre_cli_try_activate_live_session <- function() { bin <- tre_cli_binary(); if (is.null(bin)) return(FALSE); root <- Sys.getenv(\"AHRI_TRE_RUNTIME_ROOT\",\"/opt/ahri-tre-runtime\"); lib <- file.path(normalizePath(path.expand(root), mustWork=FALSE), \"lib\"); env <- c(paste0(\"LD_LIBRARY_PATH=\", paste(c(lib, Sys.getenv(\"LD_LIBRARY_PATH\")), collapse=\":\"))); out <- suppressWarnings(system2(bin, args=c(\"session\",\"list\",\"--format\",\"json\"), stdout=TRUE, stderr=TRUE, env=env)); j <- tre_parse_first_json_object(out); if (is.null(j) || !isTRUE(j$ok)) return(FALSE); sessions <- j$data$sessions; if (is.null(sessions) || length(sessions)==0) return(FALSE); name <- NULL; for (s in sessions) if (identical(s$availability%||%\"\",\"live\")) { name <- s$session$name%||%NULL; if (is.character(name) && nzchar(name)) break; name <- NULL }; if (is.null(name)) { for (s in sessions) { n <- s$session$name%||%NULL; if (!is.character(n) || !nzchar(n)) next; if (!identical(s$availability%||%\"\",\"live\") && grepl(\"oauth\", s$auth_mode%||%\"\", ignore.case=TRUE)) { ro <- suppressWarnings(system2(bin, args=c(\"session\",\"reopen\",n,\"--format\",\"json\"), stdout=TRUE, stderr=TRUE, env=env)); rj <- tre_parse_first_json_object(ro); if (isTRUE(rj$ok)) { name <- n; break } } } }; if (is.null(name)) return(FALSE); use <- suppressWarnings(system2(bin, args=c(\"session\",\"use\",name,\"--format\",\"json\"), stdout=TRUE, stderr=TRUE, env=env)); uj <- tre_parse_first_json_object(use); isTRUE(uj$ok) }",
    "tre_cli_try_restart_daemon <- function() { bin <- tre_cli_binary(); if (is.null(bin)) return(FALSE); root <- Sys.getenv(\"AHRI_TRE_RUNTIME_ROOT\",\"/opt/ahri-tre-runtime\"); lib <- file.path(normalizePath(path.expand(root), mustWork=FALSE), \"lib\"); env <- c(paste0(\"LD_LIBRARY_PATH=\", paste(c(lib, Sys.getenv(\"LD_LIBRARY_PATH\")), collapse=\":\"))); out <- suppressWarnings(system2(bin, args=c(\"daemon\",\"start\",\"--format\",\"json\"), stdout=TRUE, stderr=TRUE, env=env)); j <- tre_parse_first_json_object(out); isTRUE(j$ok) }",
    "tre_wrapper_return_mode <- function() { mode <- getOption(\"ahriTRErRs.return_mode\", Sys.getenv(\"AHRI_TRE_R_RETURN_MODE\",\"data.frame\")); mode <- tolower(trimws(as.character(mode[[1]]%||%\"data.frame\"))); if (mode %in% c(\"data.frame\",\"dataframe\",\"df\")) return(\"data.frame\"); if (mode %in% c(\"object\",\"raw\")) return(\"object\"); if (mode %in% c(\"json\",\"string\")) return(\"json\"); \"data.frame\" }",
    "tre_coerce_json <- function(raw, obj) { if (is.character(raw) && length(raw)==1 && nzchar(raw)) return(raw); jsonlite::toJSON(obj, auto_unbox=TRUE, null=\"null\") }",
    "tre_normalize_output <- function(result, output_label=NULL, status_and_purpose=NULL, function_name=NULL) { envelope <- result$envelope%||%list(); if (!tre_result_ok(envelope)) { failure <- protocol_failure_summary(envelope); abort_ahri_tre(sprintf(\"%s failed: %s\", function_name%||%\"TRE command\", failure$message), class=\"ahri_tre_protocol_error\") }; raw <- tre_extract_data(envelope); obj <- tre_coerce_r_object(raw); df <- tre_coerce_data_frame(obj); mode <- tre_wrapper_return_mode(); data <- switch(mode, json=tre_coerce_json(raw,obj), object=obj, if (!is.null(df)) df else obj); structure(list(function_name=function_name, output_label=output_label, status_and_purpose=status_and_purpose, data=data, object=obj, data_frame=df, envelope=envelope, payloads=result$payloads%||%list()), class=\"ahri_tre_wrapper_result\") }",
    "tre_command_call <- function(client, kind, ..., .auto_fields=list(), .body=NULL, .protocol_version=TRE_PROTOCOL_VERSION, .output_label=NULL, .status_and_purpose=NULL, .function_name=NULL) { body <- merge_request_body(auto_fields=.auto_fields, dot_fields=list(...), explicit_body=.body); request <- new_tre_protocol_request(kind=kind, body=body, protocol_version=.protocol_version); result <- tryCatch(execute_json(client=client, request=request), error=function(err) err); used_cli <- FALSE; if (inherits(result,\"error\")) { if (tre_auto_session_enabled() && tre_is_no_live_session_error(result)) { if (tre_cli_try_activate_live_session()) result <- tryCatch(execute_json(client=client, request=request), error=function(err) err) }; if (inherits(result,\"error\") && tre_is_no_live_session_error(result)) { cli <- tre_execute_via_cli(kind=kind, body=body); if (!is.null(cli)) { result <- cli; used_cli <- TRUE } }; if (inherits(result,\"error\") && tre_auto_session_enabled() && tre_is_daemon_connection_error(result)) { if (tre_cli_try_restart_daemon()) result <- tryCatch(execute_json(client=client, request=request), error=function(err) err) }; if (inherits(result,\"error\")) stop(result) }; if (tre_is_invalid_request_envelope(result$envelope%||%list())) { cli <- tre_execute_via_cli(kind=kind, body=body); if (!is.null(cli)) { result <- cli; used_cli <- TRUE } }; if (tre_auto_session_enabled() && tre_is_no_live_session_envelope(result$envelope%||%list())) { if (tre_cli_try_activate_live_session()) { if (used_cli) { cli <- tre_execute_via_cli(kind=kind, body=body); if (!is.null(cli)) result <- cli } else { result <- execute_json(client=client, request=request); if (tre_is_invalid_request_envelope(result$envelope%||%list())) { cli <- tre_execute_via_cli(kind=kind, body=body); if (!is.null(cli)) result <- cli } } } }; if (tre_is_no_live_session_envelope(result$envelope%||%list())) { cli <- tre_execute_via_cli(kind=kind, body=body); if (!is.null(cli)) { result <- cli; used_cli <- TRUE } }; if (tre_auto_session_enabled() && tre_is_daemon_connection_envelope(result$envelope%||%list())) { if (tre_cli_try_restart_daemon()) { if (used_cli) { cli <- tre_execute_via_cli(kind=kind, body=body); if (!is.null(cli)) result <- cli } else { result <- execute_json(client=client, request=request); if (tre_is_invalid_request_envelope(result$envelope%||%list())) { cli <- tre_execute_via_cli(kind=kind, body=body); if (!is.null(cli)) result <- cli } } } }; if (tre_is_no_live_session_envelope(result$envelope%||%list()) && tre_soft_no_live_session_enabled(kind)) { warning(sprintf(\"%s: no live session selected; returning empty result\", .function_name%||%kind), call.=FALSE); result$envelope <- list(ok=TRUE, kind=kind, data=list()) }; tre_normalize_output(result=result, output_label=.output_label, status_and_purpose=.status_and_purpose, function_name=.function_name) }"
  )
  writeLines(core, "R/core.R")

  cat_map <- list(
    "Assets, Datafiles, Datasets" = "assets.R",
    "Authentication, Daemon, Sessions" = "auth_session.R",
    "Datastore, Semantic Catalog" = "datastore.R",
    "Entities, Relations, Transformations, Ingest" = "entities.R",
    "Local Commands" = "local.R",
    "Study, Governance" = "study.R"
  )
  for (cat in names(cat_map)) {
    cat_rows <- rows[sapply(rows, function(x) x$Category == cat)]
    if (length(cat_rows) == 0) next
    fname <- file.path("R", cat_map[[cat]])
    lines <- c(paste0("# Auto-generated wrappers for ", cat), "")
    for (row in cat_rows) {
      fun <- row$Function
      kind <- kind_rows[[fun]]
      params <- parse_cmd(row$Command)
      if (row$StudyContext == "single-study") {
        params$study <- list(param = "study", key = "study")
      }
      imp <- parse_imp(row$ImportantInputs)
      for (p in imp) params[[p$param]] <- p
      reserved <- c("client","...",".body",".protocol_version")
      uniq <- list()
      seen <- c()
      for (p in params) {
        if (!(p$param %in% seen) && !(p$param %in% reserved)) {
          seen <- c(seen, p$param)
          uniq[[length(uniq)+1]] <- p
        }
      }
      sig <- paste0(fun, " <- function(", paste(c("client", sapply(uniq, function(p) paste0(p$param, " = NULL")), "...", ".body = NULL", ".protocol_version = TRE_PROTOCOL_VERSION"), collapse=", "), ") {")
      lines <- c(lines, sig)
      fld <- c()
      for (p in uniq) {
        # Key is already clean from parse_imp/parse_cmd, just format as flag
        fld <- c(fld, paste0("    \"", p$key, "\" = ", p$param))
      }
      lines <- c(lines, if (length(fld)) c("  auto_fields <- list(", paste(fld, collapse=",\n"), "  )") else "  auto_fields <- list()")
      out <- gsub('"', '\\\\"', row$Output)
      st <- gsub('"', '\\\\"', row$StatusAndPurpose)
      call <- c(
        "  tre_command_call(",
        paste0("    client = client,"),
        paste0("    kind = \"", kind, "\","),
        "    ...,",
        "    .auto_fields = auto_fields,",
        "    .body = .body,",
        "    .protocol_version = .protocol_version,",
        paste0("    .output_label = \"", out, "\","),
        paste0("    .status_and_purpose = \"", st, "\","),
        paste0("    .function_name = \"", fun, "\""),
        "  )",
        "}"
      )
      lines <- c(lines, call, "")
    }
    writeLines(lines, fname)
  }

  ns <- c("useDynLib(ahriTRErRs, .registration = TRUE)", paste0("export(", sapply(rows, function(x) x$Function), ")"))
  writeLines(ns, "NAMESPACE")

  rd <- c(
    "\\name{tre-command-wrappers}",
    sapply(rows, function(x) paste0("\\alias{", x$Function, "}")),
    "\\title{Generated TRE Command Wrapper Functions}",
    "\\description{Auto-generated wrappers for TRE protocol commands.}",
    "\\details{See package documentation.}",
    "\\keyword{package}"
  )
  dir.create("man", showWarnings = FALSE, recursive = TRUE)
  writeLines(rd, "man/tre_command_wrappers.Rd")

  cat("[INFO] Wrappers generated.\n")
  invisible(TRUE)
}

generate_wrappers()
roxygen2::roxygenise(".")
cat("[INFO] Done. You can now build the package.\n")