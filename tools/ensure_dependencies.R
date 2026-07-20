# Ensure R package dependencies are installed for this repository.

repos <- "https://cloud.r-project.org"

install_if_missing <- function(pkg) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = repos)
  }
}

# Ensure a writable user library is available.
r_libs_user <- Sys.getenv("R_LIBS_USER")
if (nzchar(r_libs_user)) {
  dir.create(r_libs_user, recursive = TRUE, showWarnings = FALSE)
  .libPaths(unique(c(r_libs_user, .libPaths())))
}

install_if_missing("remotes")
install_if_missing("languageserver")
install_if_missing("roxygen2")
install_if_missing("testthat")

# Install package dependencies listed in DESCRIPTION.
remotes::install_deps(".", dependencies = TRUE, upgrade = "never")

# Keep generated documentation in sync during container bootstrap.
roxygen2::roxygenise()

# Run tests only when the packaged runtime is available in this image.
runtime_ready <- file.exists("/opt/ahri-tre-runtime/bin/ahri-tre") &&
  file.exists("/opt/ahri-tre-runtime/bin/ahri-tred")

if (runtime_ready) {
  testthat::test_dir("tests/testthat")
} else {
  message("AHRI TRE runtime not installed in this container build; skipping tests that require runtime.")
}
