#!/usr/bin/env Rscript
#
# Simple runtime and study list check.

suppressPackageStartupMessages(library(ahriTRErRs))
if (file.exists(".env")) readRenviron(".env")

resolve_runtime_root <- function() { ... } # same as above

runtime_root <- resolve_runtime_root()
Sys.setenv(AHRI_TRE_RUNTIME_ROOT = runtime_root)
manifest <- file.path(runtime_root, "share", "ahri-tre", "manifest.json")
if (!file.exists(manifest)) {
  cat("[INFO] Runtime manifest not found. Skipping.\n")
  quit(save = "no", status = 0L)
}

client <- AhriTreClient()
on.exit(close(client), add = TRUE)

cat("[INFO] Runtime status\n")
print(runtime_status())

status <- tryCatch(auth_status(client, format = "json"), error = function(e) NULL)
if (is.null(status)) {
  cat("[INFO] auth_status is not supported by this runtime. Continuing.\n")
} else {
  cat(sprintf("[INFO] auth_status: %s\n", status$status))
}

studies <- study_list(client, format = "json")$data
if (is.data.frame(studies)) {
  cat(sprintf("[INFO] Studies found: %d\n", nrow(studies)))
  print(utils::head(studies, 5L))
} else {
  print(studies)
}