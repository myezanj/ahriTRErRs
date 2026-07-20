mock_client_for_read_dataset <- function() {
  structure(
    list(api = list(library_path = ""), handle = new.env(parent = emptyenv())),
    class = "ahri_tre_client"
  )
}

test_that("read_dataset validates user-facing arguments", {
  client <- mock_client_for_read_dataset()

  expect_error(
    read_dataset(ds = list(), study_name = "Study", dataset_name = "Dataset"),
    class = "ahri_tre_argument_error"
  )
  expect_error(
    read_dataset(ds = client, study_name = "", dataset_name = "Dataset"),
    class = "ahri_tre_argument_error"
  )
  expect_error(
    read_dataset(ds = client, study_name = "Study", dataset_name = ""),
    class = "ahri_tre_argument_error"
  )
  expect_error(
    read_dataset(ds = client, study_name = "Study", dataset_name = "Dataset", include_versions = NA),
    class = "ahri_tre_argument_error"
  )
  expect_error(
    read_dataset(ds = client, study_name = "Study", dataset_name = "Dataset", version = c("1", "2")),
    class = "ahri_tre_argument_error"
  )
})

test_that("read_dataset returns rows from JSON body for latest dataset", {
  client <- mock_client_for_read_dataset()
  calls <- character()

  rows <- testthat::with_mocked_bindings(
    dataset_list = function(...) stop("dataset_list should not be called"),
    dataset_data = function(client, study = NULL, dataset = NULL, limit = NULL, format = NULL, ...) {
      calls <<- c(calls, dataset)
      list(
        data = list(rows = list(list(id = 1L, value = "ok"))),
        payloads = list()
      )
    },
    read_dataset(ds = client, study_name = "Study", dataset_name = "Dataset")
  )

  expect_identical(calls, "Dataset")
  expect_identical(nrow(rows), 1L)
  expect_identical(rows$id[[1]], 1L)
  expect_identical(rows$value[[1]], "ok")
  expect_identical(attr(rows, "dataset_reference"), "Dataset")
})

test_that("read_dataset prefers requested version when available", {
  client <- mock_client_for_read_dataset()
  calls <- character()

  rows <- testthat::with_mocked_bindings(
    dataset_list = function(client, study = NULL, include_versions = NULL, format = NULL, ...) {
      list(data = data.frame(name = "Dataset", version = "1.2.3", stringsAsFactors = FALSE))
    },
    dataset_data = function(client, study = NULL, dataset = NULL, limit = NULL, format = NULL, ...) {
      calls <<- c(calls, dataset)
      list(data = list(rows = list(list(id = 5L))), payloads = list())
    },
    read_dataset(
      ds = client,
      study_name = "Study",
      dataset_name = "Dataset",
      include_versions = TRUE,
      version = "1.2.3"
    )
  )

  expect_identical(calls[[1]], "Dataset@1.2.3")
  expect_identical(attr(rows, "dataset_reference"), "Dataset@1.2.3")
})

test_that("read_dataset falls back to latest when requested version is unavailable", {
  client <- mock_client_for_read_dataset()
  calls <- character()

  rows <- testthat::with_mocked_bindings(
    dataset_list = function(client, study = NULL, include_versions = NULL, format = NULL, ...) {
      list(data = data.frame(name = "Dataset", version = "9.9.9", stringsAsFactors = FALSE))
    },
    dataset_data = function(client, study = NULL, dataset = NULL, limit = NULL, format = NULL, ...) {
      calls <<- c(calls, dataset)
      list(data = list(rows = list(list(id = 8L))), payloads = list())
    },
    read_dataset(
      ds = client,
      study_name = "Study",
      dataset_name = "Dataset",
      include_versions = TRUE,
      version = "1.2.3"
    )
  )

  expect_identical(calls, "Dataset")
  expect_identical(attr(rows, "dataset_reference"), "Dataset")
})

test_that("read_dataset retries latest when version-qualified read fails", {
  client <- mock_client_for_read_dataset()
  calls <- character()

  rows <- testthat::with_mocked_bindings(
    dataset_list = function(client, study = NULL, include_versions = NULL, format = NULL, ...) {
      list(data = data.frame(name = "Dataset", version = "1.2.3", stringsAsFactors = FALSE))
    },
    dataset_data = function(client, study = NULL, dataset = NULL, limit = NULL, format = NULL, ...) {
      calls <<- c(calls, dataset)
      if (identical(dataset, "Dataset@1.2.3")) {
        stop("not found")
      }
      list(data = list(rows = list(list(id = 3L))), payloads = list())
    },
    read_dataset(
      ds = client,
      study_name = "Study",
      dataset_name = "Dataset",
      include_versions = TRUE,
      version = "1.2.3"
    )
  )

  expect_identical(calls, c("Dataset@1.2.3", "Dataset"))
  expect_identical(attr(rows, "dataset_reference"), "Dataset")
})

test_that("read_dataset prefers Arrow IPC payload conversion when available", {
  client <- mock_client_for_read_dataset()

  rows <- testthat::with_mocked_bindings(
    dataset_data = function(client, study = NULL, dataset = NULL, limit = NULL, format = NULL, ...) {
      list(
        data = list(rows = list(list(id = 99L))),
        payloads = list(list(kind = "arrow_ipc", data = as.raw(c(1, 2, 3))))
      )
    },
    arrow_ipc_to_table = function(payload) {
      data.frame(id = 42L, converted = TRUE)
    },
    read_dataset(ds = client, study_name = "Study", dataset_name = "Dataset")
  )

  expect_identical(nrow(rows), 1L)
  expect_identical(rows$id[[1]], 42L)
  expect_true(rows$converted[[1]])
})
