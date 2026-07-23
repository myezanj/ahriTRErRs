#' Package initialization
#'
#' @param libname Library name
#' @param pkgname Package name
#' @noRd
.onLoad <- function(libname, pkgname) {
  # Set default options
  op <- options()
  op_ahriTRErRs <- list(
    ahriTRErRs.return_mode = "data.frame",
    ahriTRErRs.soft_no_live_session = TRUE,
    ahriTRErRs.auto_session_use = TRUE
  )

  toset <- !(names(op_ahriTRErRs) %in% names(op))
  if (any(toset)) {
    options(op_ahriTRErRs[toset])
  }

  invisible()
}

#' Package attachment
#'
#' @param libname Library name
#' @param pkgname Package name
#' @noRd
.onAttach <- function(libname, pkgname) {
  packageStartupMessage(
    "ahriTRErRs ",
    utils::packageVersion(pkgname),
    " loaded.\n",
    "Set AHRI_TRE_RUNTIME_ROOT to use runtime operations."
  )
}

#' Package detach
#'
#' @param libpath Library path
#' @noRd
.onDetach <- function(libpath) {
  # Clean up any remaining resources
  invisible()
}