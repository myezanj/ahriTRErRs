suppressPackageStartupMessages(library(ahriTRErRs))
if (file.exists(".env")) readRenviron(".env")

target <- Sys.getenv("AHRI_TRE_TARGET_STUDY", unset = "Copilot_Row_Probe_20260720")
Sys.setenv(
  AHRI_TRE_TARGET_STUDY = target,
  AHRI_TRE_ENFORCE_ROW_READ = "true",
  AHRI_TRE_ROW_PREFLIGHT_FAIL_FAST = "true"
)

cat("[INFO] Running strict row-read validation\n")
cat("[INFO] AHRI_TRE_TARGET_STUDY=", target, "\n", sep = "")
cat("[INFO] AHRI_TRE_ENFORCE_ROW_READ=true\n")
cat("[INFO] AHRI_TRE_ROW_PREFLIGHT_FAIL_FAST=true\n")

source("inst/examples/read_rfam.r", local = FALSE)
