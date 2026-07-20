test_that("protocol failure envelopes produce safe summaries", {
  envelope <- list(
    status = "failure",
    error = list(code = "unsupported_operation", message = "request could not be handled")
  )

  summary <- protocol_failure_summary(envelope)

  expect_identical(summary$status, "failure")
  expect_identical(summary$code, "unsupported_operation")
  expect_identical(summary$message, "request could not be handled")
})

test_that("request JSON is serialized as UTF-8 raw bytes", {
  bytes <- ahriTRErRs:::request_bytes(list(kind = "runtime.status", body = list()))
  expect_type(bytes, "raw")
  expect_match(rawToChar(bytes), '"kind":"runtime.status"', fixed = TRUE)
})
