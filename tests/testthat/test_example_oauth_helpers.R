test_that("write_oauth_profile helper writes stable workspace profile fields", {
  script_path <- "/workspaces/ahriTRErRs/inst/examples/write_oauth_profile.r"
  temp_root <- withr::local_tempdir()
  withr::local_dir(temp_root)
  withr::local_envvar(c(
    TRE_SERVER = "example.ahri.org",
    TRE_TEST_DBNAME = "pilot_tre",
    TRE_PORT = "5544",
    TRE_TEST_LAKE_PATH = "/tmp/lake-data",
    TRE_TEST_LAKE_DB = "pilot_catalog",
    LAKE_USER = "lake_user",
    LAKE_PASSWORD = "lake_password",
    ORCID_TOKEN_CACHE_FILE = "~/.cache/tre_pilot/token.json",
    ORCID_CLIENT_ID = "client-id",
    ORCID_CLIENT_SECRET = "client-secret",
    ORCID_ISSUER = "https://orcid.example.org",
    ORCID_REDIRECT_URI = "http://127.0.0.1:8890/callback",
    ORCID_SCOPE = "openid"
  ))

  helper_env <- new.env(parent = globalenv())
  sys.source(script_path, envir = helper_env)
  result <- helper_env$main()

  expect_identical(result$profile_path, file.path(temp_root, ".runtime", "ahri-tre-open-oauth.env"))
  expect_identical(result$datastore, "pilot_tre")
  expect_true(file.exists(result$profile_path))

  profile_lines <- readLines(result$profile_path, warn = FALSE)
  expect_true(any(grepl("^TRE_DBNAME='pilot_tre'$", profile_lines)))
  expect_true(any(grepl("^TRE_DATASTORE='pilot_tre'$", profile_lines)))
  expect_true(any(grepl("^TRE_SERVER='example.ahri.org'$", profile_lines)))
  expect_true(any(grepl("^ORCID_CACHE_FILE='", profile_lines)))
  expect_true(any(grepl("token.json'$", profile_lines)))
})

test_that("open_oauth_session dry-run prints stable command", {
  script_path <- "/workspaces/ahriTRErRs/inst/examples/open_oauth_session.r"
  temp_root <- withr::local_tempdir()
  runtime_root <- file.path(temp_root, ".runtime", "ahri-tre-runtime")
  cli_bin <- file.path(runtime_root, "bin", "ahri-tre")
  manifest <- file.path(runtime_root, "share", "ahri-tre", "manifest.json")
  dir.create(dirname(cli_bin), recursive = TRUE, showWarnings = FALSE)
  dir.create(dirname(manifest), recursive = TRUE, showWarnings = FALSE)
  dir.create(file.path(runtime_root, "lib"), recursive = TRUE, showWarnings = FALSE)
  writeLines("#!/bin/sh\nexit 0\n", cli_bin, useBytes = TRUE)
  Sys.chmod(cli_bin, mode = "0755")
  writeLines("{}", manifest, useBytes = TRUE)

  withr::local_dir(temp_root)
  withr::local_envvar(c(
    AHRI_TRE_OPEN_OAUTH_DRY_RUN = "true",
    TRE_SERVER = "example.ahri.org",
    TRE_TEST_DBNAME = "pilot_tre",
    TRE_PORT = "5544",
    ORCID_TOKEN_CACHE_FILE = "~/.cache/tre_pilot/token.json",
    AHRI_TRE_RUNTIME_ROOT = runtime_root
  ))

  output <- capture.output({
    helper_env <- new.env(parent = globalenv())
    sys.source(script_path, envir = helper_env)
    helper_env$main()
  })

  output_text <- paste(output, collapse = "\n")
  expect_match(output_text, paste0("OAuth profile: ", file.path(temp_root, ".runtime", "ahri-tre-open-oauth.env")), fixed = TRUE)
  expect_match(output_text, "Dry-run mode enabled via AHRI_TRE_OPEN_OAUTH_DRY_RUN.", fixed = TRUE)
  expect_match(output_text, paste0(cli_bin, " 'session' 'open-oauth' 'pilot_tre' '--profile' '", file.path(temp_root, ".runtime", "ahri-tre-open-oauth.env"), "'"), fixed = TRUE)
})

test_that("read_rfam fails with actionable error when no live session exists", {
  script_path <- "/workspaces/ahriTRErRs/inst/examples/read_rfam.r"
  temp_root <- withr::local_tempdir()
  runtime_root <- file.path(temp_root, ".runtime", "ahri-tre-runtime")
  manifest <- file.path(runtime_root, "share", "ahri-tre", "manifest.json")
  dir.create(dirname(manifest), recursive = TRUE, showWarnings = FALSE)
  writeLines("{}", manifest, useBytes = TRUE)

  withr::local_dir(temp_root)
  withr::local_envvar(c(AHRI_TRE_RUNTIME_ROOT = runtime_root))

  helper_env <- new.env(parent = globalenv())
  sys.source(script_path, envir = helper_env)
  helper_env$fail_on_missing_session <- TRUE
  helper_env$AhriTreClient <- function(...) list()
  helper_env$close <- function(...) invisible(NULL)
  helper_env$session_status <- function(...) {
    list(object = list(session = list(active = FALSE, availability = "missing", unavailable_reason = "no active session is selected")))
  }
  helper_env$session_list <- function(...) list(object = list(sessions = list()))

  error <- tryCatch(
    {
      capture.output(helper_env$main())
      NULL
    },
    error = function(err) err
  )

  expect_s3_class(error, "error")
  expect_match(conditionMessage(error), "No active live TRE session is available", fixed = TRUE)
  expect_match(conditionMessage(error), "AHRI_TRE_FAIL_ON_MISSING_SESSION=false", fixed = TRUE)
})

test_that("read_rfam diagnostics-only mode keeps no-session guidance", {
  script_path <- "/workspaces/ahriTRErRs/inst/examples/read_rfam.r"
  temp_root <- withr::local_tempdir()
  runtime_root <- file.path(temp_root, ".runtime", "ahri-tre-runtime")
  manifest <- file.path(runtime_root, "share", "ahri-tre", "manifest.json")
  dir.create(dirname(manifest), recursive = TRUE, showWarnings = FALSE)
  writeLines("{}", manifest, useBytes = TRUE)

  withr::local_dir(temp_root)
  withr::local_envvar(c(AHRI_TRE_RUNTIME_ROOT = runtime_root))

  output <- capture.output({
    helper_env <- new.env(parent = globalenv())
    sys.source(script_path, envir = helper_env)
    helper_env$fail_on_missing_session <- FALSE
    helper_env$AhriTreClient <- function(...) list()
    helper_env$close <- function(...) invisible(NULL)
    helper_env$session_status <- function(...) {
      list(object = list(session = list(active = FALSE, availability = "missing", unavailable_reason = "no active session is selected")))
    }
    helper_env$session_list <- function(...) list(object = list(sessions = list()))

    helper_env$main()
  })

  output_text <- paste(output, collapse = "\n")
  expect_match(output_text, "[WARN] No local TRE sessions are saved in this environment.", fixed = TRUE)
  expect_match(output_text, "Preferred path: Rscript inst/examples/open_oauth_session.r", fixed = TRUE)
  expect_match(output_text, "AHRI_TRE_RUNTIME_ROOT=", fixed = TRUE)
})