#!/usr/bin/env Rscript
#
# Quick test of a few generated wrappers.
# Requires AHRI_TRE_RUNTIME_ROOT to be set.

suppressPackageStartupMessages(library(ahriTRErRs))

# Ensure runtime is set
if (file.exists(".env")) readRenviron(".env")
runtime_root <- Sys.getenv("AHRI_TRE_RUNTIME_ROOT", unset = "")
if (!nzchar(runtime_root)) {
  stop("Set AHRI_TRE_RUNTIME_ROOT to the runtime artifact path.")
}

cat("[INFO] Using runtime:", runtime_root, "\n")

# Create client
client <- AhriTreClient()
on.exit(close(client), add = TRUE)

# Test 1: study_list
cat("\n[TEST] study_list()\n")
studies <- try(study_list(client, format = "json")$data, silent = TRUE)
if (inherits(studies, "try-error")) {
  cat("[ERROR] study_list failed:", conditionMessage(studies), "\n")
} else {
  if (is.data.frame(studies)) {
    cat("[OK] study_list returned a data frame with", nrow(studies), "rows.\n")
  } else {
    cat("[OK] study_list returned an object of class", class(studies)[1], "\n")
  }
}

# Test 2: dataset_list (if a study is available)
studies_df <- studies
if (is.data.frame(studies_df) && nrow(studies_df) > 0) {
  first_study <- studies_df$name[1] %||% studies_df$study_name[1] %||% studies_df$study[1]
  if (!is.null(first_study) && nzchar(first_study)) {
    cat("\n[TEST] dataset_list(study =", first_study, ")\n")
    datasets <- try(dataset_list(client, study = first_study, include_versions = TRUE, format = "json")$data, silent = TRUE)
    if (inherits(datasets, "try-error")) {
      cat("[ERROR] dataset_list failed:", conditionMessage(datasets), "\n")
    } else {
      if (is.data.frame(datasets)) {
        cat("[OK] dataset_list returned a data frame with", nrow(datasets), "rows.\n")
      } else {
        cat("[OK] dataset_list returned an object of class", class(datasets)[1], "\n")
      }
    }
  } else {
    cat("[WARN] No study name found to test dataset_list.\n")
  }
} else {
  cat("[WARN] No studies available; skipping dataset_list test.\n")
}

# Test 3: auth_status (if supported)
cat("\n[TEST] auth_status()\n")
status <- try(auth_status(client, format = "json"), silent = TRUE)
if (inherits(status, "try-error")) {
  cat("[INFO] auth_status not supported or failed:", conditionMessage(status), "\n")
} else {
  cat("[OK] auth_status returned", if (is.list(status)) "a list" else "a", class(status)[1], "\n")
}

cat("\n[INFO] Wrapper tests completed.\n")