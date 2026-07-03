test_that("Arrow IPC conversion rejects non-Arrow payloads", {
  payload <- ahritre:::Payload(kind = "parquet", data = charToRaw("not-arrow"))
  expect_error(arrow_ipc_to_table(payload), class = "ahri_tre_payload_error")
})

test_that("payload kind names mirror the C ABI constants", {
  expect_identical(ahritre:::payload_kind_name(0L), "none")
  expect_identical(ahritre:::payload_kind_name(1L), "arrow_ipc")
  expect_identical(ahritre:::payload_kind_name(2L), "parquet")
  expect_identical(ahritre:::payload_kind_name(3L), "artifact")
})
