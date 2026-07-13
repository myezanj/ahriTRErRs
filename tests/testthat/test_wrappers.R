wrapper_names_from_namespace <- function() {
  exports <- getNamespaceExports("ahritre")
  wrappers <- exports[vapply(exports, function(name) {
    fn <- get(name, envir = asNamespace("ahritre"), mode = "function")
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
