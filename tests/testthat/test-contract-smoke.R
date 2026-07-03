test_that("contract smoke success request uses stable session list protocol", {
  request <- smoke_success_request()

  expect_identical(request$protocol_version, "1.0.0")
  expect_identical(request$kind, "session.list")
  expect_true(request$body$include_unavailable)
})

test_that("contract smoke failure request uses generic protocol execution shape", {
  request <- smoke_failure_request()

  expect_identical(request$protocol_version, "1.0.0")
  expect_identical(request$kind, "binding.contract_smoke.unsupported")
})

test_that("contract smoke failure summary keeps safe protocol fields", {
  summary <- protocol_failure_summary(list(
    ok = FALSE,
    kind = "protocol.invalid_request",
    error = list(code = "protocol.invalid_request", message = "invalid request")
  ))

  expect_identical(summary$code, "protocol.invalid_request")
  expect_identical(summary$message, "invalid request")
  expect_false(grepl("password", tolower(jsonlite::toJSON(summary, auto_unbox = TRUE))))
})

test_that("contract smoke payload summary stubs Arrow IPC when no payloads are returned", {
  result <- structure(list(envelope = list(ok = TRUE), payloads = list()), class = "ahri_tre_protocol_result")

  summary <- payload_smoke_summary(result)

  expect_identical(summary$count, 0L)
  expect_match(summary$dataframe_conversion, "external binding tests")
})

test_that("contract smoke diagnostics redact paths credentials and raw requests", {
  redacted <- redact_diagnostics(list(
    path = "/home/alice/runtime",
    message = "ok",
    connection_string = "postgres://user:pass@example/db",
    request = list(token = "abc")
  ))
  rendered <- jsonlite::toJSON(redacted, auto_unbox = TRUE)

  expect_match(rendered, "ok")
  expect_false(grepl("/home/alice", rendered, fixed = TRUE))
  expect_false(grepl("postgres://", rendered, fixed = TRUE))
  expect_false(grepl("abc", rendered, fixed = TRUE))
})
