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
