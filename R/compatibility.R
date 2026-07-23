#' Protocol Compatibility Checking
#'
#' Functions to verify that the runtime and R binding support overlapping
#' protocol versions, ensuring safe communication.
#'
#' @name compatibility
NULL

#' Supported protocol version range for this R package
SUPPORTED_PROTOCOL_MIN <- "1.0.0"
SUPPORTED_PROTOCOL_MAX <- "1.0.999"

#' Retrieve compatibility information from the runtime
#'
#' Calls the ABI to get version strings for the library, protocol, and
#' compatibility rules.
#'
#' @param api An `ahri_tre_c_api` object (optional). Defaults to `CApi()`.
#' @return An object of class `ahri_tre_compatibility_info` containing:
#'   \item{abi_version}{ABI version string.}
#'   \item{library_version}{Runtime library version.}
#'   \item{protocol_version}{Active protocol version.}
#'   \item{protocol_minimum}{Minimum supported protocol version.}
#'   \item{protocol_maximum}{Maximum supported protocol version.}
#'   \item{protocol_rule}{Compatibility rule (e.g., "semver").}
#' @export
#' @examples
#' \dontrun{
#' info <- CompatibilityInfo()
#' print(info$protocol_version)
#' }
CompatibilityInfo <- function(api = CApi()) {
  info <- list(
    abi_version = owned_string(api, "ahri_tre_abi_version"),
    library_version = owned_string(api, "ahri_tre_library_version"),
    protocol_version = owned_string(api, "ahri_tre_protocol_version"),
    protocol_minimum = owned_string(api, "ahri_tre_protocol_compatibility_minimum"),
    protocol_maximum = owned_string(api, "ahri_tre_protocol_compatibility_maximum"),
    protocol_rule = owned_string(api, "ahri_tre_protocol_compatibility_rule")
  )
  class(info) <- "ahri_tre_compatibility_info"
  info
}

#' Check protocol compatibility between the runtime and this R package
#'
#' Compares the runtime's supported protocol range with the package's
#' `SUPPORTED_PROTOCOL_MIN` and `SUPPORTED_PROTOCOL_MAX`.
#' Aborts with an error if the ranges do not overlap.
#'
#' @param api An `ahri_tre_c_api` object (optional).
#' @return The `ahri_tre_compatibility_info` object if compatible.
#' @export
#' @examples
#' \dontrun{
#' check_protocol_compatibility()
#' }
check_protocol_compatibility <- function(api = CApi()) {
  info <- CompatibilityInfo(api)

  if (!protocol_ranges_overlap(
    SUPPORTED_PROTOCOL_MIN,
    SUPPORTED_PROTOCOL_MAX,
    info$protocol_minimum,
    info$protocol_maximum
  )) {
    abort_ahri_tre(
      sprintf(
        "AHRI TRE runtime protocol range %s..%s is not supported by this R binding range %s..%s",
        info$protocol_minimum,
        info$protocol_maximum,
        SUPPORTED_PROTOCOL_MIN,
        SUPPORTED_PROTOCOL_MAX
      ),
      class = "ahri_tre_compatibility_error"
    )
  }
  info
}

#' Determine if two version ranges overlap
#'
#' Uses `package_version` for semantic comparison.
#'
#' @param binding_min Character. Minimum version supported by the binding.
#' @param binding_max Character. Maximum version supported by the binding.
#' @param runtime_min Character. Minimum version supported by the runtime.
#' @param runtime_max Character. Maximum version supported by the runtime.
#' @return Logical indicating overlap.
#' @noRd
protocol_ranges_overlap <- function(binding_min, binding_max, runtime_min, runtime_max) {
  package_version(runtime_min) <= package_version(binding_max) &&
    package_version(runtime_max) >= package_version(binding_min)
}