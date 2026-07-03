test_that("protocol ranges overlap only when compatible", {
  expect_true(ahritre:::protocol_ranges_overlap("0.1.0", "0.1.999", "0.1.0", "0.1.0"))
  expect_true(ahritre:::protocol_ranges_overlap("0.1.0", "0.1.999", "0.1.5", "0.2.0"))
  expect_false(ahritre:::protocol_ranges_overlap("0.1.0", "0.1.999", "0.2.0", "0.2.999"))
})

test_that("artifact discovery requires an explicit runtime root", {
  withr::local_envvar(AHRI_TRE_RUNTIME_ROOT = NA)
  expect_error(discover_runtime_artifact(), class = "ahri_tre_artifact_error")
})
