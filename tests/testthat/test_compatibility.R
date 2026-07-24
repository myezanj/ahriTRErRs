test_that("protocol ranges overlap only when compatible", {
  expect_true(ahriTRErRs:::protocol_ranges_overlap("1.0.0", "1.0.999", "1.0.0", "1.0.0"))
  expect_true(ahriTRErRs:::protocol_ranges_overlap("1.0.0", "1.0.999", "1.0.5", "1.1.0"))
  expect_false(ahriTRErRs:::protocol_ranges_overlap("1.0.0", "1.0.999", "2.0.0", "2.0.999"))
})

test_that("artifact discovery requires an explicit runtime root", {
  withr::local_envvar(AHRI_TRE_RUNTIME_ROOT = NA)
  expect_error(discover_runtime_artifact(), class = "ahri_tre_artifact_error")
})

test_that("runtime_ensure_root uses a valid environment root", {
  root <- withr::local_tempdir()
  manifest <- file.path(root, "share", "ahri-tre", "manifest.json")
  dir.create(dirname(manifest), recursive = TRUE, showWarnings = FALSE)
  writeLines("{}", manifest, useBytes = TRUE)

  withr::local_envvar(AHRI_TRE_RUNTIME_ROOT = root)
  resolved <- runtime_ensure_root()

  expect_identical(resolved, normalizePath(root, mustWork = FALSE))
  expect_identical(
    Sys.getenv("AHRI_TRE_RUNTIME_ROOT"),
    normalizePath(root, mustWork = FALSE)
  )
})

test_that("runtime_ensure_root falls back to candidate roots", {
  invalid <- withr::local_tempdir()
  valid <- withr::local_tempdir()
  manifest <- file.path(valid, "share", "ahri-tre", "manifest.json")
  dir.create(dirname(manifest), recursive = TRUE, showWarnings = FALSE)
  writeLines("{}", manifest, useBytes = TRUE)

  withr::local_envvar(AHRI_TRE_RUNTIME_ROOT = invalid)
  resolved <- runtime_ensure_root(candidates = c(invalid, valid))

  expect_identical(resolved, normalizePath(valid, mustWork = FALSE))
  expect_identical(
    Sys.getenv("AHRI_TRE_RUNTIME_ROOT"),
    normalizePath(valid, mustWork = FALSE)
  )
})

test_that("runtime_ensure_root errors when no runtime manifest is found", {
  withr::local_envvar(AHRI_TRE_RUNTIME_ROOT = NA)
  expect_error(
    runtime_ensure_root(candidates = c(withr::local_tempdir(), withr::local_tempdir())),
    class = "ahri_tre_artifact_error"
  )
})
