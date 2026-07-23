#!/usr/bin/env Rscript

if (file.exists(".env")) readRenviron(".env")
CRAN <- "https://cloud.r-project.org"

# Discover and verify AHRI TRE runtime
discover_runtime_root <- function() {
  candidates <- unique(c(
    Sys.getenv("AHRI_TRE_RUNTIME_ROOT", ""),
    file.path(getwd(), ".runtime", "ahri-tre-runtime"),
    file.path(getwd(), "release", "ahri-tre-runtime"),
    "/opt/ahri-tre-runtime",
    "/workspaces/ahriTRErRs/.runtime/ahri-tre-runtime",
    "/workspaces/ahriTRErRs/release/ahri-tre-runtime"
  ))
  candidates <- candidates[nzchar(candidates)]
  roots <- normalizePath(path.expand(candidates), mustWork = FALSE)
  manifests <- file.path(roots, "share", "ahri-tre", "manifest.json")
  hits <- roots[file.exists(manifests)]
  if (length(hits) > 0L) hits[[1]] else NULL
}

verify_runtime_artifacts <- function(runtime_root) {
  artifacts <- c(
    "bin/ahri-tre",
    "lib/libahri_tre_ffi_c.so",
    "share/ahri-tre/manifest.json"
  )
  missing <- character()
  for (artifact in artifacts) {
    path <- file.path(runtime_root, artifact)
    if (!file.exists(path)) {
      missing <- c(missing, artifact)
    }
  }
  missing
}

runtime_root <- discover_runtime_root()
if (is.null(runtime_root)) {
  cat("[WARN] AHRI TRE runtime manifest not found.\n")
  cat("[INFO] Set AHRI_TRE_RUNTIME_ROOT or ensure runtime is installed at:\n")
  cat("      - .runtime/ahri-tre-runtime/ (local)\n")
  cat("      - release/ahri-tre-runtime/ (release)\n")
  cat("      - /opt/ahri-tre-runtime (system)\n")
  cat("[INFO] Continuing with build...\n")
} else {
  cat("[INFO] Found AHRI TRE runtime at:", runtime_root, "\n")
  Sys.setenv(AHRI_TRE_RUNTIME_ROOT = runtime_root)
  
  # Verify runtime artifacts
  missing <- verify_runtime_artifacts(runtime_root)
  if (length(missing) > 0L) {
    cat("[WARN] Missing runtime artifacts:\n")
    for (artifact in missing) {
      cat("      -", artifact, "\n")
    }
  } else {
    cat("[INFO] All runtime artifacts verified.\n")
  }
}

# Install required packages if missing
for (pkg in c("devtools", "roxygen2", "remotes")) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = CRAN)
  }
}
library(devtools)
library(roxygen2)
library(remotes)

# Install package dependencies from DESCRIPTION
remotes::install_deps(".", dependencies = TRUE, upgrade = "never")

# Generate documentation
roxygen2::roxygenise(".")

# Build source tarball
cat("[INFO] Building source tarball...\n")
devtools::build()

# Optionally install
if (tolower(Sys.getenv("AHRI_TRE_AUTO_INSTALL_RELEASE", "true")) != "false") {
  cat("[INFO] Installing package...\n")
  devtools::install()
} else {
  cat("[INFO] Skipping install (AHRI_TRE_AUTO_INSTALL_RELEASE=false).\n")
}

# Verify runtime setup after build
if (!is.null(runtime_root)) {
  lib_path <- file.path(runtime_root, "lib")
  bin_path <- file.path(runtime_root, "bin")
  
  cat("\n[INFO] === Runtime Setup Complete ===\n")
  cat("[INFO] Runtime root:", runtime_root, "\n")
  
  if (dir.exists(lib_path)) {
    cat("[INFO] Library path:", lib_path, "\n")
    cat("[INFO] Export LD_LIBRARY_PATH:\n")
    cat("      export LD_LIBRARY_PATH=", lib_path, ":$LD_LIBRARY_PATH\n")
  }
  
  if (dir.exists(bin_path)) {
    ahri_tre_bin <- file.path(bin_path, "ahri-tre")
    if (file.exists(ahri_tre_bin)) {
      cat("[INFO] CLI binary available at:", ahri_tre_bin, "\n")
      cat("[INFO] Export PATH:\n")
      cat("      export PATH=", bin_path, ":$PATH\n")
    }
  }
  
  cat("[INFO] To use the package in R:\n")
  cat("      library(ahriTRErRs)\n")
  cat("      client <- AhriTreClient()\n")
  cat("[INFO] === Setup Complete ===\n\n")
} else {
  cat("\n[WARN] === Runtime Setup Incomplete ===\n")
  cat("[WARN] AHRI TRE runtime not found. The package can still be used but will require:\n")
  cat("      1. A running daemon via CLI (install runtime separately)\n")
  cat("      2. LD_LIBRARY_PATH to include libahri_tre_ffi_c.so\n")
  cat("[INFO] === Continuing without runtime ===\n\n")
}

cat("[INFO] Done.\n")