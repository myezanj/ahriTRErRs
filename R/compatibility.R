SUPPORTED_PROTOCOL_MIN <- "1.0.0"
SUPPORTED_PROTOCOL_MAX <- "1.0.999"

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

protocol_ranges_overlap <- function(binding_min, binding_max, runtime_min, runtime_max) {
  package_version(runtime_min) <= package_version(binding_max) &&
    package_version(runtime_max) >= package_version(binding_min)
}
