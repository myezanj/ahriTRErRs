wrapper_names_from_namespace <- function() {
  exports <- getNamespaceExports("ahriTRErRs")
  wrappers <- exports[vapply(exports, function(name) {
    fn <- get(name, envir = asNamespace("ahriTRErRs"), mode = "function")
    fml <- names(formals(fn))
    length(fml) >= 4L &&
      identical(fml[[1]], "client") &&
      any(fml == "...") &&
      any(fml == ".body") &&
      any(fml == ".protocol_version")
  }, logical(1))]
  sort(unique(wrappers))
}

test_that("all generated wrappers are present", {
  wrappers <- wrapper_names_from_namespace()

  expect_gt(length(wrappers), 0L)
  expect_equal(length(wrappers), 123L)
})

test_that("generated wrappers map to command-derived protocol kinds", {
  wrappers <- wrapper_names_from_namespace()

  for (fn in wrappers) {
    wrapper <- get(fn, mode = "function")
    expected_kind <- TRE_COMMAND_KIND_MAP[[fn]]
    if (is.null(expected_kind) || !nzchar(expected_kind)) {
      expected_kind <- gsub("_", ".", fn, fixed = TRUE)
    }

    captured <- testthat::with_mocked_bindings(
      execute_json = function(client, request) {
        list(
          envelope = list(ok = TRUE, kind = request$kind, data = request$body),
          payloads = list()
        )
      },
      wrapper(list(client = "ok"), token = "abc")
    )

    expect_equal(captured$envelope$kind, expected_kind, info = fn)
    expect_equal(captured$data$token, "abc", info = fn)
    expect_equal(captured$function_name, fn, info = fn)
    expect_true(inherits(captured, "ahri_tre_wrapper_result"), info = fn)
  }
})

test_that("explicit body overrides variadic body fields", {
  captured <- testthat::with_mocked_bindings(
    execute_json = function(client, request) {
      list(
        envelope = list(ok = TRUE, kind = request$kind, data = request$body),
        payloads = list()
      )
    },
    asset_list(
      list(client = "ok"),
      study = "ignored",
      ignored = TRUE,
      .body = list(study = "demo"),
      .protocol_version = "9.9.9"
    )
  )

  expect_equal(captured$envelope$kind, "asset.list")
  expect_equal(captured$data, list(study = "demo"))
})

test_that("protocol failures are converted to ahri_tre_protocol_error", {
  expect_error(
    testthat::with_mocked_bindings(
      execute_json = function(client, request) {
        list(
          envelope = list(ok = FALSE, error = list(message = "nope")),
          payloads = list()
        )
      },
      datastore_ping(list(client = "ok"))
    ),
    class = "ahri_tre_protocol_error"
  )
})

test_that("unsupported protocol kinds fall back to CLI", {
  captured <- testthat::with_mocked_bindings(
    execute_json = function(client, request) {
      list(
        envelope = list(
          ok = FALSE,
          kind = "protocol.unsupported",
          error = list(message = "protocol request kind is not supported")
        ),
        payloads = list()
      )
    },
    tre_execute_via_cli = function(kind, body) {
      list(
        envelope = list(ok = TRUE, kind = kind, data = list(rows = list(list(id = 7L, label = "zeta")))),
        payloads = list()
      )
    },
    dataset_list(list(client = "ok"), format = "json")
  )

  expect_true(is.data.frame(captured$data))
  expect_identical(captured$data$id[[1]], 7L)
  expect_identical(captured$data$label[[1]], "zeta")
})

test_that("CLI fallback quotes shell-sensitive argument values", {
  args <- ahriTRErRs:::tre_cli_args_from_body(
    "ingest.dataset.from-sql",
    list(sql = "select * from Rfam.family", description = "mysql select all family")
  )

  expect_identical(args[[5]], "'select * from Rfam.family'")
  expect_identical(args[[7]], "'mysql select all family'")
})

test_that("wrapper output coerces JSON string data to R objects", {
  captured <- testthat::with_mocked_bindings(
    execute_json = function(client, request) {
      list(
        envelope = list(
          ok = TRUE,
          kind = request$kind,
          data = '{"rows":[{"id":1,"label":"alpha"}]}'
        ),
        payloads = list()
      )
    },
    dataset_list(list(client = "ok"), format = "json")
  )

  expect_true(is.list(captured$object))
  expect_true(is.data.frame(captured$data_frame))
  expect_identical(captured$data_frame$id[[1]], 1L)
  expect_identical(captured$data_frame$label[[1]], "alpha")
})

test_that("wrapper output exposes data.frame when payload is tabular list", {
  captured <- testthat::with_mocked_bindings(
    execute_json = function(client, request) {
      list(
        envelope = list(
          ok = TRUE,
          kind = request$kind,
          data = list(rows = list(list(id = 2L, label = "beta")))
        ),
        payloads = list()
      )
    },
    dataset_search(list(client = "ok"), format = "json")
  )

  expect_true(is.data.frame(captured$data_frame))
  expect_identical(captured$data_frame$id[[1]], 2L)
  expect_identical(captured$data_frame$label[[1]], "beta")
})

test_that("wrapper data defaults to data.frame when coercion is possible", {
  captured <- testthat::with_mocked_bindings(
    execute_json = function(client, request) {
      list(
        envelope = list(
          ok = TRUE,
          kind = request$kind,
          data = list(rows = list(list(id = 3L, label = "gamma")))
        ),
        payloads = list()
      )
    },
    dataset_list(list(client = "ok"), format = "json")
  )

  expect_true(is.data.frame(captured$data))
  expect_identical(captured$data$id[[1]], 3L)
  expect_identical(captured$data$label[[1]], "gamma")
})

test_that("wrapper data can be forced to object mode", {
  withr::local_options(list(ahriTRErRs.return_mode = "object"))

  captured <- testthat::with_mocked_bindings(
    execute_json = function(client, request) {
      list(
        envelope = list(
          ok = TRUE,
          kind = request$kind,
          data = list(rows = list(list(id = 4L, label = "delta")))
        ),
        payloads = list()
      )
    },
    dataset_list(list(client = "ok"), format = "json")
  )

  expect_true(is.list(captured$data))
  expect_true(is.data.frame(captured$data_frame))
  expect_identical(captured$data$rows[[1]]$id[[1]], 4L)
})

test_that("wrapper data can be forced to json mode", {
  withr::local_options(list(ahriTRErRs.return_mode = "json"))

  captured <- testthat::with_mocked_bindings(
    execute_json = function(client, request) {
      list(
        envelope = list(
          ok = TRUE,
          kind = request$kind,
          data = list(rows = list(list(id = 5L, label = "epsilon")))
        ),
        payloads = list()
      )
    },
    dataset_list(list(client = "ok"), format = "json")
  )

  expect_true(is.character(captured$data))
  expect_length(captured$data, 1L)
  expect_match(captured$data, '"rows"', fixed = TRUE)
  expect_true(is.list(captured$object))
  expect_true(is.data.frame(captured$data_frame))
})
