#' AHRI TRE Runtime Artifact Management
#'
#' Functions to locate, validate, and load the AHRI TRE runtime artifact.
#' The runtime artifact is a directory containing the C ABI library, daemon binary,
#' headers, and a manifest file.
#'
#' @name artifact
NULL

#' Environment variable used to specify the runtime root path
RUNTIME_ROOT_ENV <- "AHRI_TRE_RUNTIME_ROOT"

#' Create a RuntimeArtifact object from a root directory
#'
#' Reads the `share/ahri-tre/manifest.json` file and validates its structure.
#'
#' @param root Character. Path to the runtime artifact root directory.
#' @return An object of class `ahri_tre_runtime_artifact`.
#' @export
#' @examples
#' \dontrun{
#' art <- RuntimeArtifact("/opt/ahri-tre-runtime")
#' }
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

#' Discover runtime artifact from environment or explicit path
#'
#' Uses `AHRI_TRE_RUNTIME_ROOT` environment variable if `root` is not provided.
#' Validates that all required runtime files are present.
#'
#' @param root Character. Optional explicit path to the runtime artifact.
#' @return A validated `ahri_tre_runtime_artifact` object.
#' @export
#' @examples
#' \dontrun{
#' art <- discover_runtime_artifact()
#' }
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

#' Resolve and set AHRI TRE runtime root
#'
#' Ensures `AHRI_TRE_RUNTIME_ROOT` points to a runtime artifact containing
#' `share/ahri-tre/manifest.json`. If `root` is not provided or invalid, the
#' function searches candidate directories and sets the environment variable to
#' the first valid match.
#'
#' @param root Character. Optional explicit runtime root.
#' @param candidates Character vector of fallback root candidates.
#' @return Character scalar with resolved runtime root path.
#' @export
runtime_ensure_root <- function(root = NULL, candidates = NULL) {
  manifest_exists <- function(path) {
    is.character(path) && length(path) == 1L && nzchar(path) &&
      file.exists(file.path(path, "share", "ahri-tre", "manifest.json"))
  }

  env_root <- Sys.getenv(RUNTIME_ROOT_ENV, unset = "")
  chosen <- root %||% env_root
  if (manifest_exists(chosen)) {
    resolved <- normalizePath(path.expand(chosen), mustWork = FALSE)
    Sys.setenv(AHRI_TRE_RUNTIME_ROOT = resolved)
    return(resolved)
  }

  fallback <- candidates %||% c(
    file.path(getwd(), ".runtime", "ahri-tre-runtime"),
    "/opt/ahri-tre-runtime"
  )

  for (cand in fallback) {
    if (manifest_exists(cand)) {
      resolved <- normalizePath(path.expand(cand), mustWork = FALSE)
      Sys.setenv(AHRI_TRE_RUNTIME_ROOT = resolved)
      return(resolved)
    }
  }

  abort_ahri_tre(
    sprintf("%s is unset or invalid, and no local runtime artifact was found.", RUNTIME_ROOT_ENV),
    class = "ahri_tre_artifact_error"
  )
}

#' Get path to the C header file
#'
#' @param artifact An `ahri_tre_runtime_artifact` object.
#' @return Character path to `ahri_tre_ffi_c.h`.
#' @export
runtime_c_header <- function(artifact) {
  file.path(artifact$root, "include", "ahri_tre_ffi_c.h")
}

#' Get path to the daemon binary
#'
#' Adds `.exe` suffix on Windows.
#'
#' @param artifact An `ahri_tre_runtime_artifact` object.
#' @return Character path to the daemon executable.
#' @export
runtime_daemon_binary <- function(artifact) {
  suffix <- if (.Platform$OS.type == "windows") ".exe" else ""
  file.path(artifact$root, "bin", paste0("ahri-tred", suffix))
}

#' Get path to the C ABI shared library
#'
#' Determines the correct library name and extension based on the OS.
#' Override can be specified in the manifest under `artifacts.c_abi_library`.
#'
#' @param artifact An `ahri_tre_runtime_artifact` object.
#' @return Character path to the shared library.
#' @export
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

#' Ensure all required runtime files exist
#'
#' Checks for the C header, daemon binary, and C ABI library.
#' Aborts with an error if any are missing.
#'
#' @param artifact An `ahri_tre_runtime_artifact` object.
#' @return Invisibly returns the artifact.
#' @export
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

#' Extract artifact path from manifest
#'
#' @param manifest List. The parsed manifest.
#' @param key Character. The artifact key (e.g., "c_abi_library").
#' @return Character path or `NULL` if not defined.
#' @noRd
manifest_artifact_path <- function(manifest, key) {
  artifacts <- manifest$artifacts
  if (is.list(artifacts) && is.character(artifacts[[key]]) && length(artifacts[[key]]) == 1L) {
    return(artifacts[[key]])
  }
  NULL
}

#' Null coalescing operator
#'
#' Returns `lhs` if not `NULL`, otherwise `rhs`.
#'
#' @param lhs Any R object.
#' @param rhs Any R object.
#' @return Either `lhs` or `rhs`.
#' @noRd
`%||%` <- function(lhs, rhs) {
  if (!is.null(lhs)) lhs else rhs
}