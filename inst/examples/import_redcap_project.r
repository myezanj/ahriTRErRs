bootstrap_helper_candidates <- c(file.path("inst", "examples", "bootstrap_helpers.r"), "bootstrap_helpers.r")
bootstrap_helper_path <- bootstrap_helper_candidates[file.exists(bootstrap_helper_candidates)][1]
if (is.na(bootstrap_helper_path) || !nzchar(bootstrap_helper_path)) {
  stop("Could not locate inst/examples/bootstrap_helpers.r")
}
source(bootstrap_helper_path, local = TRUE)
ensure_ahriTRErRs_available()

truthy <- function(x) tolower(trimws(as.character(x))) %in% c("1", "true", "yes", "on")

bootstrap <- bootstrap_example_session()
if (is.null(bootstrap)) {
  invisible(FALSE)
  quit(save = "no", status = 0L)
}

runtime <- bootstrap$runtime
datastore <- bootstrap$datastore

redcap_api_url <- Sys.getenv("REDCAP_API_URL", "")
redcap_api_token <- Sys.getenv("REDCAP_API_TOKEN", "")
domain_name <- Sys.getenv("TRE_DOMAIN", "Basic Science")
study_name <- Sys.getenv("TRE_STUDY", "The Biology of Subclinical Asymptomic TB")

forms <- trimws(strsplit(Sys.getenv("REDCAP_FORMS", ""), ",", fixed = TRUE)[[1]])
forms <- forms[nzchar(forms)]
fields <- trimws(strsplit(Sys.getenv("REDCAP_FIELDS", ""), ",", fixed = TRUE)[[1]])
fields <- fields[nzchar(fields)]
force_reingest <- truthy(Sys.getenv("REDCAP_FORCE_REINGEST", "false"))
preferred_asset <- Sys.getenv("REDCAP_DATAFILE_ASSET", "")
force_transform <- truthy(Sys.getenv("REDCAP_FORCE_TRANSFORM", "false"))
ducklake_column_limit <- 1600L
ducklake_safety_margin <- suppressWarnings(as.integer(Sys.getenv("REDCAP_DUCKLAKE_SAFETY_MARGIN", "8")))
if (is.na(ducklake_safety_margin) || ducklake_safety_margin < 1L) {
  ducklake_safety_margin <- 8L
}
projected_column_budget <- ducklake_column_limit - ducklake_safety_margin
if (projected_column_budget < 1L) {
  stop(
    "REDCAP_DUCKLAKE_SAFETY_MARGIN is too large; projected column budget became < 1."
  )
}

required <- c("REDCAP_API_URL", "REDCAP_API_TOKEN")
missing <- required[!nzchar(c(redcap_api_url, redcap_api_token))]
if (length(missing) > 0) stop("Missing required environment variables: ", paste(missing, collapse = ", "))

cat(format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "| [INFO] Opening datastore\n")
on.exit(closedatastore(datastore), add = TRUE)

bootstrap <- ahriTRErRs::example_ensure_domain_study(
  datastore,
  domain_name,
  study_name,
  study_description = paste0("REDCap import for ", study_name),
  study_external_id = study_name
)
domain <- bootstrap$domain
study <- bootstrap$study

cat(format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "| [INFO] Domain:", domain$name, " Study:", study$name, "\n")

if (length(forms) > 0) cat("[INFO] REDCAP_FORMS:", paste(forms, collapse = ", "), "\n")
if (length(fields) > 0) cat("[INFO] REDCAP_FIELDS:", paste(fields, collapse = ", "), "\n")

if (force_reingest) {
  cat("[INFO] Ingesting full REDCap project\n")
  datafile <- ingest_redcap_project(
    datastore,
    redcap_api_url,
    redcap_api_token,
    study,
    domain,
    forms = forms,
    fields = fields,
    vocabulary_prefix = "REDCap"
    )
} else {
  assets <- list_study_assets_df(datastore, study)
  files <- assets[assets$asset_type %in% "file", , drop = FALSE]
  redcap_files <- files[grepl("^redcap_[0-9]+_eav$", files$name), , drop = FALSE]
  if (nzchar(preferred_asset)) redcap_files <- redcap_files[redcap_files$name %in% preferred_asset, , drop = FALSE]
  if (nrow(redcap_files) == 0) stop("No REDCap datafile available. Set REDCAP_FORCE_REINGEST=true or REDCAP_DATAFILE_ASSET.")

  project_ids <- suppressWarnings(as.integer(sub("^redcap_([0-9]+)_eav$", "\\1", redcap_files$name)))
  chosen_name <- as.character(redcap_files$name[[if (all(is.na(project_ids))) 1 else which.max(project_ids)]])
  asset <- get_asset(datastore, study, chosen_name, asset_type = "file", include_versions = TRUE)
  if (is.null(asset)) {
    stop("Expected REDCap datafile asset not found: ", chosen_name)
  }
  datafile <- get_datafile_meta(datastore, get_latest_version(datastore, asset))
  cat("[INFO] Reusing datafile asset:", chosen_name, "\n")
}

cat("[INFO] Datafile path:", file_uri_to_path(datafile$storage_uri), "\n")
dataset_name <- sub("_eav$", "", as.character(datafile$version$asset$name))
dataset <- get_dataset(datastore, as.character(study$name), dataset_name, include_versions = TRUE)

if (!force_transform && nrow(dataset) == 1) {
  cat("[INFO] Reusing existing wide dataset:", as.character(dataset$name[[1]]), " Version:", as.character(dataset$version[[1]]), "\n")
  dataset_result <- dataset
} else {
  prune_target <- 152L
  prune_focus_suffix <- "_desc"
  domain_variables <- get_domain_variables(datastore, domain)
  category_raw_columns <- sum(as.integer(domain_variables$value_type_id) == 7L, na.rm = TRUE)
  projected_columns <- 1L + nrow(domain_variables) + category_raw_columns
  cat(
    "[INFO] Domain variable count:", nrow(domain_variables),
    " Categorical *_raw columns:", category_raw_columns,
    " Projected dataset columns:", projected_columns,
    " Safety margin:", ducklake_safety_margin,
    " Safety budget:", projected_column_budget,
    "\n"
  )

  if (projected_columns > projected_column_budget) {
    variable_names <- as.character(domain_variables$name)
    variable_names <- variable_names[nzchar(variable_names)]

    exact_desc <- unique(variable_names[grepl(paste0(prune_focus_suffix, "$"), variable_names)])
    desc_base <- sub(paste0(prune_focus_suffix, "$"), "", exact_desc)
    desc_with_base <- exact_desc[desc_base %in% variable_names]
    desc_without_base <- setdiff(exact_desc, desc_with_base)

    companion_suffixes <- c("_other$", "_oth$", "_comment$", "_detail$", "_reason$")
    companion_any <- unique(variable_names[grepl("desc|comment|detail|reason|specify|_oth$|_other$", variable_names, ignore.case = TRUE)])

    with_base_companion <- character(0)
    for (suffix_pat in companion_suffixes) {
      vars_suffix <- unique(variable_names[grepl(suffix_pat, variable_names, ignore.case = TRUE)])
      if (length(vars_suffix) == 0) next
      base_names <- gsub(suffix_pat, "", vars_suffix, ignore.case = TRUE)
      with_base_companion <- c(with_base_companion, vars_suffix[base_names %in% variable_names])
    }
    with_base_companion <- unique(with_base_companion)
    loose_companion <- setdiff(companion_any, c(desc_with_base, desc_without_base, with_base_companion))

    prune_candidates <- unique(c(
      sort(desc_with_base),
      sort(desc_without_base),
      sort(with_base_companion),
      sort(loose_companion)
    ))
    to_remove_count <- min(prune_target, length(prune_candidates))
    to_remove <- head(prune_candidates, to_remove_count)
    if (length(to_remove) == 0L) {
      cat("[INFO] No *_desc/similar text-companion variables remain; falling back to categorical pruning\n")
    }

    # If still above limit after text-companion pruning, remove additional categorical
    # variables because each category also generates a *_raw column at transform time.
    current_savings <- function(var_names, variable_df) {
      idx <- match(var_names, variable_df$name)
      value_types <- as.integer(variable_df$value_type_id[idx])
      sum(ifelse(value_types == 7L, 2L, 1L), na.rm = TRUE)
    }

    savings_after_text <- current_savings(to_remove, domain_variables)
    projected_after_text <- projected_columns - savings_after_text
    if (projected_after_text > projected_column_budget) {
      remaining_variables <- domain_variables[!(domain_variables$name %in% to_remove), , drop = FALSE]
      remaining_names <- as.character(remaining_variables$name)
      remaining_types <- as.integer(remaining_variables$value_type_id)

      category_priority_patterns <- c(
        "_class$", "_result$", "_type$", "_yn$", "_outcome$", "_quality$",
        "_normal$", "_refer$", "_diagnosed$", "_trt$", "_visit$",
        "_completed$", "_completed_by$", "_review_outcome$", "_qc_outcome$",
        "_reviewer$", "_qc_by$"
      )
      category_priority <- unique(unlist(lapply(category_priority_patterns, function(pat) {
        remaining_names[remaining_types == 7L & grepl(pat, remaining_names, ignore.case = TRUE)]
      })))
      remaining_categories <- remaining_names[remaining_types == 7L]
      additional_candidates <- unique(c(sort(category_priority), sort(setdiff(remaining_categories, category_priority))))

      extra_to_remove <- character(0)
      extra_saved <- 0L
      for (var_name in additional_candidates) {
        extra_to_remove <- c(extra_to_remove, var_name)
        extra_saved <- extra_saved + 2L
        if ((projected_after_text - extra_saved) <= projected_column_budget) break
      }

      to_remove <- unique(c(to_remove, extra_to_remove))
    }

    if (length(to_remove) == 0L) {
      stop(
        paste0(
          "Projected wide dataset exceeds 1600 columns and no pruning candidates remain. ",
          "Use TRE_DOMAIN/REDCAP_FORMS/REDCAP_FIELDS to narrow the transform scope."
        )
      )
    }

    cat("[INFO] Removing", length(to_remove), "variables before transform\n")
    if (length(to_remove) < prune_target) {
      cat("[INFO] Requested prune target", prune_target, "not fully available on this run; proceeding with", length(to_remove), "candidates\n")
    }
    remove_failures <- character(0)
    for (var_name in to_remove) {
      tryCatch(
        delete_variable(datastore, var_name, force = TRUE, domain_name = as.character(domain$name)),
        error = function(e) {
          remove_failures <<- c(remove_failures, paste0(var_name, ": ", conditionMessage(e)))
        }
      )
    }

    if (length(remove_failures) > 0) {
      stop(
        paste0(
          "Failed to remove one or more variables: ",
          paste(remove_failures, collapse = " | ")
        )
      )
    }

    dir.create("logs", recursive = TRUE, showWarnings = FALSE)
    prune_log <- file.path(
      "logs",
      paste0("import_redcap_pruned_variables_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".log")
    )
    writeLines(to_remove, con = prune_log, useBytes = TRUE)
    cat("[INFO] Variable prune log written to:", prune_log, "\n")

    domain_variables <- get_domain_variables(datastore, domain)
    category_raw_columns <- sum(as.integer(domain_variables$value_type_id) == 7L, na.rm = TRUE)
    projected_columns <- 1L + nrow(domain_variables) + category_raw_columns
    cat(
      "[INFO] Updated domain variable count:", nrow(domain_variables),
      " Categorical *_raw columns:", category_raw_columns,
      " Projected dataset columns:", projected_columns,
      " Safety margin:", ducklake_safety_margin,
      " Safety budget:", projected_column_budget,
      "\n"
    )
  }

  if (projected_columns > projected_column_budget) {
    stop(
      paste0(
        "Projected wide dataset has ", projected_columns,
        " columns (safety budget: ", projected_column_budget,
        ", safety margin: ", ducklake_safety_margin,
        ", hard limit: ", ducklake_column_limit, "). ",
        "DuckLake/PostgreSQL can fail around the hard column limit during commit. ",
        "Use a narrower domain (TRE_DOMAIN), reduce registered REDCap fields/forms, ",
        "or split this REDCap project into smaller transforms."
      )
    )
  }

  cat("[INFO] Transforming EAV to wide dataset\n")
  dataset_result <- tryCatch(
    transform_eav_to_dataset(datastore, datafile = datafile, replace = TRUE, domain = domain),
    error = function(e) {
      err_msg <- conditionMessage(e)
      options(width = max(1000L, getOption("width", 80L)))
      dir.create("logs", recursive = TRUE, showWarnings = FALSE)
      diag_path <- file.path(
        "logs",
        paste0("import_redcap_transform_error_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".log")
      )

      diagnostic_lines <- c(
        paste0("timestamp=", format(Sys.time(), "%Y-%m-%d %H:%M:%S")),
        paste0("runtime=", runtime),
        paste0("study_name=", as.character(study$name)),
        paste0("domain_name=", as.character(domain$name)),
        paste0("datafile_asset=", as.character(datafile$version$asset$name)),
        paste0("datafile_version=", paste(datafile$version$major, datafile$version$minor, datafile$version$patch, sep = ".")),
        paste0("datafile_storage_uri=", as.character(datafile$storage_uri)),
        paste0("target_dataset_name=", dataset_name),
        "",
        "error_message_begin",
        err_msg,
        "error_message_end"
      )

      writeLines(diagnostic_lines, con = diag_path, useBytes = TRUE)
      cat("[ERROR] transform_eav_to_dataset failed; diagnostics written to:", diag_path, "\n")
      cat("[ERROR] Full transform error follows:\n")
      cat(err_msg, "\n")
      stop(e)
    }
  )
}

rows <- dataset_to_dataframe(datastore, dataset_result, limit = 100L, on_missing = "empty")
if (inherits(dataset_result, "DataSet")) {
  dataset_label <- dataset_result$version$asset$name
  dataset_version <- paste(dataset_result$version$major, dataset_result$version$minor, dataset_result$version$patch, sep = ".")
} else {
  dataset_label <- as.character(dataset_result$name[[1]])
  dataset_version <- as.character(dataset_result$version[[1]])
}
cat("[INFO] Dataset:", dataset_label, " Version:", dataset_version, "\n")
cat("[INFO] Rows:", nrow(rows), " Columns:", ncol(rows), "\n")
print(utils::head(rows, 10))

print(list_study_assets_df(datastore, study))
