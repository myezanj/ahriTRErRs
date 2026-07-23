test_that("closing a client twice is safe", {
  withr::local_envvar(c(AHRI_TRE_RUNTIME_ROOT = "/workspaces/ahriTRErRs/.runtime/ahri-tre-runtime"))
  client <- AhriTreClient(check_compatibility = FALSE)

  expect_invisible(close(client))
  expect_invisible(close(client))
})

test_that("execute_json on a closed client raises package error", {
  withr::local_envvar(c(AHRI_TRE_RUNTIME_ROOT = "/workspaces/ahriTRErRs/.runtime/ahri-tre-runtime"))
  client <- AhriTreClient(check_compatibility = FALSE)
  close(client)

  expect_error(
    execute_json(
      client,
      list(protocol_version = TRE_PROTOCOL_VERSION, kind = "study.list", body = list())
    ),
    class = "ahri_tre_client_state_error"
  )
})

test_that("AhriTreClient fails fast when bridge returns a null client pointer", {
  withr::local_envvar(c(AHRI_TRE_RUNTIME_ROOT = "/workspaces/ahriTRErRs/.runtime/ahri-tre-runtime"))
  api <- CApi()

  expect_error(
    testthat::with_mocked_bindings(
      ahri_tre_client_create_bridge = function(path, endpoint, binary, timeout, never_start) {
        list(status = 0L, client = new("externalptr"))
      },
      AhriTreClient(api = api, check_compatibility = FALSE)
    ),
    class = "ahri_tre_client_create_error"
  )
})

test_that("runtime bridge calls prepend the runtime lib directory to LD_LIBRARY_PATH", {
  withr::local_envvar(c(
    AHRI_TRE_RUNTIME_ROOT = "/workspaces/ahriTRErRs/.runtime/ahri-tre-runtime",
    LD_LIBRARY_PATH = "/tmp/existing-runtime-lib"
  ))
  api <- CApi()

  observed <- testthat::with_mocked_bindings(
    ahri_tre_runtime_call_bridge = function(path, action, endpoint, binary, timeout, never_start) {
      list(
        status = 0L,
        result = Sys.getenv("LD_LIBRARY_PATH", unset = "")
      )
    },
    check_abi_status = function(...) invisible(NULL),
    result_free = function(...) invisible(NULL),
    result_json = function(api, handle) handle,
    runtime_status(api = api)
  )

  expected_prefix <- dirname(normalizePath(api$library_path, mustWork = FALSE))
  expect_true(startsWith(observed, expected_prefix))
  expect_match(observed, "/tmp/existing-runtime-lib", fixed = TRUE)
})

test_that("AhriTreClient bridge creation prepends the runtime lib directory to LD_LIBRARY_PATH", {
  withr::local_envvar(c(
    AHRI_TRE_RUNTIME_ROOT = "/workspaces/ahriTRErRs/.runtime/ahri-tre-runtime",
    LD_LIBRARY_PATH = "/tmp/existing-runtime-lib"
  ))
  api <- CApi()
  observed_ld_path <- NULL

  client <- testthat::with_mocked_bindings(
    ahri_tre_client_create_bridge = function(path, endpoint, binary, timeout, never_start) {
      observed_ld_path <<- Sys.getenv("LD_LIBRARY_PATH", unset = "")
      list(
        status = 0L,
        client = new("externalptr")
      )
    },
    check_abi_status = function(...) invisible(NULL),
    tre_client_handle_is_valid = function(handle) TRUE,
    AhriTreClient(api = api, check_compatibility = FALSE)
  )

  expected_prefix <- dirname(normalizePath(api$library_path, mustWork = FALSE))
  expect_true(startsWith(observed_ld_path, expected_prefix))
  expect_match(observed_ld_path, "/tmp/existing-runtime-lib", fixed = TRUE)
  close(client)
})
