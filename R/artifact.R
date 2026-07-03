RUNTIME_ROOT_ENV <- "AHRI_TRE_RUNTIME_ROOT"

RuntimeArtifact <- function(root) {
  root <- normalizePath(path.expand(root), mustWork = FALSE)
  manifest_path <- file.path(root, "share", "ahri-tre", "manifest.json")
  if (!file.exists(manifest_path)) {
    abort_ahri_tre(
      "AHRI TRE runtime manifest was not found under the artifact root",
      class = "ahri_tre_artifact_error"
    )
  }
  manifest <- tryCatch(
    jsonlite::fromJSON(manifest_path, simplifyVector = FALSE),
    error = function(err) {
      abort_ahri_tre(
        "AHRI TRE runtime manifest is not valid JSON",
        class = "ahri_tre_artifact_error"
      )
    }
  )
  artifact <- list(root = root, manifest = manifest)
  class(artifact) <- "ahri_tre_runtime_artifact"
  artifact
}

discover_runtime_artifact <- function(root = NULL) {
  selected <- root %||% Sys.getenv(RUNTIME_ROOT_ENV, unset = NA_character_)
  if (is.na(selected) || !nzchar(selected)) {
    abort_ahri_tre(
      sprintf("set %s to an unpacked AHRI TRE runtime artifact", RUNTIME_ROOT_ENV),
      class = "ahri_tre_artifact_error"
    )
  }
  artifact <- RuntimeArtifact(selected)
  require_runtime_files(artifact)
  artifact
}

runtime_c_header <- function(artifact) {
  file.path(artifact$root, "include", "ahri_tre_ffi_c.h")
}

runtime_daemon_binary <- function(artifact) {
  suffix <- if (.Platform$OS.type == "windows") ".exe" else ""
  file.path(artifact$root, "bin", paste0("ahri-tred", suffix))
}

runtime_c_abi_library <- function(artifact) {
  override <- manifest_artifact_path(artifact$manifest, "c_abi_library")
  if (!is.null(override)) {
    return(file.path(artifact$root, override))
  }
  name <- switch(
    Sys.info()[["sysname"]],
    Darwin = "libahri_tre_ffi_c.dylib",
    Windows = "ahri_tre_ffi_c.dll",
    "libahri_tre_ffi_c.so"
  )
  file.path(artifact$root, "lib", name)
}

require_runtime_files <- function(artifact) {
  required <- c(
    runtime_c_header(artifact),
    runtime_daemon_binary(artifact),
    runtime_c_abi_library(artifact)
  )
  missing <- required[!file.exists(required)]
  if (length(missing) > 0L) {
    rel <- sub(paste0("^", normalizePath(artifact$root, mustWork = FALSE), "/?"), "", missing)
    abort_ahri_tre(
      paste("AHRI TRE runtime artifact is missing required files:", paste(rel, collapse = ", ")),
      class = "ahri_tre_artifact_error"
    )
  }
  invisible(artifact)
}

manifest_artifact_path <- function(manifest, key) {
  artifacts <- manifest$artifacts
  if (is.list(artifacts) && is.character(artifacts[[key]]) && length(artifacts[[key]]) == 1L) {
    return(artifacts[[key]])
  }
  NULL
}

`%||%` <- function(lhs, rhs) {
  if (!is.null(lhs)) lhs else rhs
}
