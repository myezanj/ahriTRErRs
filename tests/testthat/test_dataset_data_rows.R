test_that("dataset_data exposes rows from JSON response data", {
  result <- testthat::with_mocked_bindings(
    execute_json = function(client, request) {
      list(
        envelope = list(ok = TRUE, kind = request$kind, data = list(rows = list(list(id = 1L, value = "ok")))),
        payloads = list()
      )
    },
    dataset_data(list(client = "ok"), study = "Study", dataset = "Dataset")
  )

  expect_true(inherits(result, "ahri_tre_wrapper_result"))
  expect_true(is.data.frame(result$rows))
  expect_identical(nrow(result$rows), 1L)
  expect_identical(result$rows$id[[1]], 1L)
  expect_identical(result$rows$value[[1]], "ok")
})

test_that("dataset_data prefers Arrow IPC payload when conversion succeeds", {
  result <- testthat::with_mocked_bindings(
    execute_json = function(client, request) {
      list(
        envelope = list(ok = TRUE, kind = request$kind, data = list(rows = list(list(id = 999L)))),
        payloads = list(list(kind = "arrow_ipc", data = as.raw(c(1, 2, 3))))
      )
    },
    arrow_ipc_to_table = function(payload) {
      data.frame(id = 42L, source = "arrow", stringsAsFactors = FALSE)
    },
    dataset_data(list(client = "ok"), study = "Study", dataset = "Dataset")
  )

  expect_identical(nrow(result$rows), 1L)
  expect_identical(result$rows$id[[1]], 42L)
  expect_identical(result$rows$source[[1]], "arrow")
})

test_that("dataset_data falls back to JSON rows when Arrow conversion fails", {
  result <- testthat::with_mocked_bindings(
    execute_json = function(client, request) {
      list(
        envelope = list(ok = TRUE, kind = request$kind, data = list(rows = list(list(id = 7L, source = "json")))),
        payloads = list(list(kind = "arrow_ipc", data = as.raw(c(1, 2, 3))))
      )
    },
    arrow_ipc_to_table = function(payload) {
      stop("arrow conversion failed")
    },
    dataset_data(list(client = "ok"), study = "Study", dataset = "Dataset")
  )

  expect_identical(nrow(result$rows), 1L)
  expect_identical(result$rows$id[[1]], 7L)
  expect_identical(result$rows$source[[1]], "json")
})
