#!/usr/bin/env Rscript

# Minimal ahriTRErRs build/release script
# Ensures both .tar.gz and .zip release artifacts are created in ./release folder

if (file.exists(".env")) readRenviron(".env")

env_get_first <- function(keys, default = "") {
    for (key in keys) {
        value <- Sys.getenv(key, "")
        if (nzchar(value)) {
            return(value)
        }
    }
    default
}

initialize_release_env <- function() {
    # Avoid configure-time duckdb source builds during release unless explicitly requested.
    skip_auto_duckdb <- env_get_first(c("AHRI_TRE_SKIP_AUTO_DUCKDB_INSTALL"), default = "")
    if (!nzchar(skip_auto_duckdb)) {
        Sys.setenv(AHRI_TRE_SKIP_AUTO_DUCKDB_INSTALL = "1")
        cat("[INFO] Defaulting AHRI_TRE_SKIP_AUTO_DUCKDB_INSTALL=1 for release build stability.\n")
    } else {
        cat("[INFO] Respecting AHRI_TRE_SKIP_AUTO_DUCKDB_INSTALL=", skip_auto_duckdb, "\n", sep = "")
    }
}

ensure_user_library_precedence <- function() {
    user_lib <- Sys.getenv("R_LIBS_USER", "")
    if (!nzchar(user_lib)) {
        minor_parts <- strsplit(R.version$minor, ".", fixed = TRUE)[[1]]
        user_lib <- file.path(
            path.expand("~"),
            "R",
            paste0(R.version$platform, "-library"),
            paste0(R.version$major, ".", minor_parts[[1]])
        )
        Sys.setenv(R_LIBS_USER = user_lib)
    }

    user_lib <- normalizePath(path.expand(user_lib), winslash = "/", mustWork = FALSE)
    dir.create(user_lib, recursive = TRUE, showWarnings = FALSE)
    .libPaths(unique(c(user_lib, .libPaths())))

    invisible(user_lib)
}

ensure_languageserver_package <- function() {
    user_lib <- ensure_user_library_precedence()

    if (requireNamespace("languageserver", quietly = TRUE)) {
        cat("[INFO] languageserver already installed (lib: ", user_lib, ")\n", sep = "")
        return(invisible(TRUE))
    }

    cat("[INFO] Installing languageserver (lib: ", user_lib, ")\n", sep = "")
    install_ok <- tryCatch({
        install.packages("languageserver", repos = "https://cloud.r-project.org")
        requireNamespace("languageserver", quietly = TRUE)
    }, error = function(e) {
        warning("languageserver installation failed: ", conditionMessage(e), call. = FALSE)
        FALSE
    })

    if (isTRUE(install_ok)) {
        cat("[INFO] languageserver installed successfully.\n")
    } else {
        warning("languageserver is still unavailable after install attempt.", call. = FALSE)
    }

    invisible(install_ok)
}

ensure_roxygen_package <- function() {
    suppressMessages({
        library(roxygen2)
    })
}

ensure_devtools_package <- function() {
    suppressMessages({
        library(devtools)
    })
}

run_in_clean_rscript <- function(expr, context_label) {
    rscript <- Sys.which("Rscript")
    if (!nzchar(rscript)) {
        stop("Rscript was not found on PATH; cannot run ", context_label, " in clean session.")
    }
    script_path <- tempfile(pattern = "ahriTRErRs-clean-", fileext = ".R")
    on.exit(unlink(script_path, force = TRUE), add = TRUE)
    writeLines(c(
        "if (file.exists('.env')) readRenviron('.env')",
        "user_lib <- Sys.getenv('R_LIBS_USER', '')",
        "if (!nzchar(user_lib)) {",
        "  minor_parts <- strsplit(R.version$minor, '.', fixed = TRUE)[[1]]",
        "  user_lib <- file.path(path.expand('~'), 'R', paste0(R.version$platform, '-library'), paste0(R.version$major, '.', minor_parts[[1]]))",
        "  Sys.setenv(R_LIBS_USER = user_lib)",
        "}",
        "user_lib <- normalizePath(path.expand(user_lib), winslash = '/', mustWork = FALSE)",
        "dir.create(user_lib, recursive = TRUE, showWarnings = FALSE)",
        ".libPaths(unique(c(user_lib, .libPaths())))",
        "if (!requireNamespace('languageserver', quietly = TRUE)) install.packages('languageserver', repos = 'https://cloud.r-project.org')",
        expr
    ), con = script_path)
    status <- system2(rscript, c(script_path))
    if (!identical(status, 0L)) {
        stop(context_label, " failed in clean R subprocess.")
    }
}

cli_args <- unique(commandArgs(trailingOnly = TRUE))
supported_cli_args <- c(
    "--document",
    "--test",
    "--check",
    "--build",
    "--install",
    "--site",
    "--check-oauth",
    "--strict-check",
    "--help"
)

print_usage <- function() {
    cat("Usage: Rscript build_release.R [options]\n\n")
    cat("Options:\n")
    cat("  --document      Generate roxygen documentation and exit\n")
    cat("  --test          Run the test suite and exit\n")
    cat("  --check         Run devtools::check() and exit\n")
    cat("  --build         Build release artifacts into ./release\n")
    cat("  --install       Install the package source tree, or the built release artifact when combined with --build\n")
    cat("  --site          Build the pkgdown site and exit\n")
    cat("  --check-oauth   Validate OAuth-related environment and helper prerequisites\n")
    cat("  --strict-check  Treat R CMD check warnings as errors (used with --check)\n")
    cat("  --help          Show this help text\n")
}

# Print header
print_header <- function(title) {
    cat("\n", paste(rep("=", 80), collapse = ""), "\n", sep = "")
    cat(title, "\n")
    cat(paste(rep("=", 80), collapse = ""), "\n", sep = "")
}

print_step <- function(step) {
    cat("\n[", format(Sys.time(), "%H:%M:%S"), "] ", step, "\n", sep = "")
}

has_path_file <- function(x) {
    is.character(x) && length(x) == 1 && !is.na(x) && nzchar(x) && file.exists(x)
}

cleanup_src_artifacts <- function() {
    unlink(list.files("src", pattern = "\\.(o|so|dll)$", full.names = TRUE), force = TRUE)
}

run_document_task <- function() {
    print_header("Documenting ahriTRErRs")
    print_step("Generating documentation")
    run_in_clean_rscript(
        "if (!requireNamespace('roxygen2', quietly = TRUE)) stop('roxygen2 is required for --document'); roxygen2::roxygenise(package.dir='.')",
        "Documentation generation"
    )
    cat("  ✓ Documentation generated\n")
    print_step("Cleaning compiled artifacts left by devtools::document()")
    cleanup_src_artifacts()
    cat("  ✓ Cleaned src/*.{o,so,dll}\n")
}

run_test_task <- function() {
    print_header("Testing ahriTRErRs")
    print_step("Running test suite")
    run_in_clean_rscript(
        "if (!requireNamespace('devtools', quietly = TRUE)) stop('devtools is required for --test'); devtools::test()",
        "Test suite"
    )
}

run_check_task <- function(strict = FALSE) {
    print_header("Checking ahriTRErRs")
    print_step("Running R CMD check")
    run_in_clean_rscript(
        sprintf(
            paste(
                "if (!requireNamespace('devtools', quietly = TRUE)) stop('devtools is required for --check');",
                "devtools::check(document = FALSE, manual = FALSE, error_on = '%s')"
            ),
            if (isTRUE(strict)) "warning" else "never"
        ),
        "R CMD check"
    )
}

run_install_task <- function() {
    print_header("Installing ahriTRErRs")
    print_step("Installing package from source tree")
    run_in_clean_rscript(
        "if (!requireNamespace('devtools', quietly = TRUE)) stop('devtools is required for --install'); devtools::install(upgrade = FALSE, dependencies = FALSE, quiet = FALSE)",
        "Package install"
    )
}

run_site_task <- function() {
    if (!requireNamespace("pkgdown", quietly = TRUE)) {
        stop("pkgdown is required for --site. Install it with install.packages('pkgdown').")
    }
    print_header("Building pkgdown site")
    print_step("Building site")
    pkgdown::build_site()
}

run_oauth_check_task <- function() {
    print_header("Checking OAuth prerequisites")

    required_env <- c(
        "TRE_SERVER",
        "TRE_TEST_DBNAME",
        "ORCID_ISSUER",
        "ORCID_CLIENT_ID",
        "ORCID_CLIENT_SECRET"
    )
    env_status <- data.frame(
        variable = required_env,
        configured = vapply(required_env, function(name) nzchar(Sys.getenv(name, "")), logical(1)),
        stringsAsFactors = FALSE
    )
    print(env_status)

    helper_path <- file.path("src", "pg_oauth_helper")
    helper_ok <- file.exists(helper_path)
    cat("\nOptional helper script: ", helper_path, " -> ", if (helper_ok) "present" else "missing", "\n", sep = "")

    missing_env <- env_status$variable[!env_status$configured]
    if (length(missing_env) > 0) {
        stop(
            paste0(
                "OAuth prerequisite check failed.",
                if (length(missing_env) > 0) paste0(" Missing env vars: ", paste(missing_env, collapse = ", "), ".") else ""
            )
        )
    }

    if (!helper_ok) {
        cat("  ℹ src/pg_oauth_helper not found; continuing because it is optional for this package.\n")
    }

    cat("\n  ✓ OAuth prerequisites look configured.\n")
}

invalid_cli_args <- setdiff(cli_args, supported_cli_args)
if (length(invalid_cli_args) > 0) {
    print_usage()
    stop("Unsupported option(s): ", paste(invalid_cli_args, collapse = ", "))
}

if ("--help" %in% cli_args) {
    print_usage()
    quit(save = "no", status = 0)
}

initialize_release_env()
ensure_languageserver_package()

build_requested <- "--build" %in% cli_args
strict_check <- "--strict-check" %in% cli_args

if (length(cli_args) > 0) {
    if ("--check-oauth" %in% cli_args) {
        run_oauth_check_task()
    }
    if ("--document" %in% cli_args && !build_requested) {
        run_document_task()
    } else if ("--document" %in% cli_args && build_requested) {
        cat("[INFO] Skipping standalone --document because --build already generates documentation.\n")
    }
    if ("--test" %in% cli_args) {
        run_test_task()
    }
    if ("--check" %in% cli_args) {
        run_check_task(strict = strict_check)
    }
    if ("--site" %in% cli_args) {
        run_site_task()
    }
    if ("--install" %in% cli_args && !build_requested) {
        run_install_task()
    }
    if (!build_requested) {
        quit(save = "no", status = 0)
    }
    if (!("--install" %in% cli_args)) {
        Sys.setenv(AHRI_TRE_AUTO_INSTALL_RELEASE = "false")
    }
}

copy_dir_recursive <- function(from, to) {
    dir.create(to, recursive = TRUE, showWarnings = FALSE)

    entries <- list.files(
        from,
        recursive = TRUE,
        full.names = TRUE,
        all.files = TRUE,
        no.. = TRUE,
        include.dirs = TRUE
    )
    if (length(entries) == 0) {
        return(invisible(TRUE))
    }

    rel <- substring(entries, nchar(from) + 2L)
    info <- file.info(entries)
    is_dir <- !is.na(info$isdir) & info$isdir

    if (any(is_dir)) {
        dir_targets <- file.path(to, rel[is_dir])
        for (d in dir_targets) {
            dir.create(d, recursive = TRUE, showWarnings = FALSE)
        }
    }

    if (any(!is_dir)) {
        file_sources <- entries[!is_dir]
        file_targets <- file.path(to, rel[!is_dir])
        parent_dirs <- unique(dirname(file_targets))
        for (d in parent_dirs) {
            dir.create(d, recursive = TRUE, showWarnings = FALSE)
        }
        ok <- file.copy(
            file_sources,
            file_targets,
            overwrite = TRUE,
            copy.mode = TRUE,
            copy.date = TRUE
        )
        if (!all(ok)) {
            return(invisible(FALSE))
        }
    }

    invisible(TRUE)
}

move_path_portable <- function(from, to, label) {
    if (!file.exists(from) && !dir.exists(from)) {
        return(invisible(FALSE))
    }

    moved <- suppressWarnings(file.rename(from, to))
    if (isTRUE(moved)) {
        return(invisible(TRUE))
    }

    cat("[INFO] Falling back to copy/remove for ", label,
        " (rename unavailable across mounts).\n", sep = "")

    if (dir.exists(from)) {
        if (dir.exists(to) || file.exists(to)) {
            unlink(to, recursive = TRUE, force = TRUE)
        }
        copied <- copy_dir_recursive(from, to)
        if (!isTRUE(copied)) {
            return(invisible(FALSE))
        }
        unlink(from, recursive = TRUE, force = TRUE)
        return(invisible(!dir.exists(from) && dir.exists(to)))
    }

    to_parent <- dirname(to)
    dir.create(to_parent, recursive = TRUE, showWarnings = FALSE)
    copied <- file.copy(from, to, overwrite = TRUE, copy.mode = TRUE, copy.date = TRUE)
    if (!isTRUE(copied)) {
        return(invisible(FALSE))
    }
    unlink(from, force = TRUE)
    invisible(!file.exists(from) && file.exists(to))
}

materialize_libpq_aliases <- function(lib_dir) {
    if (!dir.exists(lib_dir)) {
        return(invisible(FALSE))
    }

    candidates <- list.files(
        lib_dir,
        pattern = "^libpq\\.so\\.[0-9]",
        full.names = TRUE
    )
    candidates <- candidates[file.info(candidates)$size > 0]
    if (length(candidates) == 0) {
        return(invisible(FALSE))
    }

    canonical <- candidates[[1]]
    aliases <- file.path(lib_dir, c("libpq.so.5", "libpq.so"))
    for (alias in aliases) {
        if (!file.exists(alias) || isTRUE(file.info(alias)$size == 0)) {
            ok <- file.copy(canonical, alias, overwrite = TRUE)
            if (!isTRUE(ok)) {
                stop("Failed to materialize libpq alias: ", alias)
            }
        }
    }

    invisible(TRUE)
}

stage_packaged_local_pg <- function() {
    src_root <- "local_pg"
    dst_root <- file.path("inst", "vendor", "local_pg")

    if (!dir.exists(src_root)) {
        cat("  ℹ local_pg not found in workspace; skipping bundled PostgreSQL runtime staging.\n")
        return(invisible(FALSE))
    }

    unlink(dst_root, recursive = TRUE, force = TRUE)
    dir.create(dst_root, recursive = TRUE, showWarnings = FALSE)

    src_include <- file.path(src_root, "include")
    if (dir.exists(src_include)) {
        ok <- file.copy(src_include, dst_root, recursive = TRUE)
        if (!isTRUE(ok)) {
            stop("Failed to stage local_pg include directory into inst/vendor/local_pg")
        }
    }

    src_lib <- file.path(src_root, "lib")
    dst_lib <- file.path(dst_root, "lib")
    if (dir.exists(src_lib)) {
        dir.create(dst_lib, recursive = TRUE, showWarnings = FALSE)
        # Match libpq libraries across platforms:
        # - Linux: libpq.so, libpq.so.5, libpq.so.5.18
        # - macOS: libpq.dylib, libpq.5.dylib
        # - Windows: libpq.dll
        libs <- list.files(src_lib,
                           pattern = "^libpq(\\.so(\\..*)?|\\.dylib(\\..*)?|\\.dll)$",
                           full.names = TRUE)
        libs <- libs[file.info(libs)$size > 0]
        if (length(libs) > 0) {
            ok <- file.copy(libs, dst_lib, overwrite = TRUE)
            if (!all(ok)) {
                stop("Failed to stage libpq shared libraries into inst/vendor/local_pg/lib")
            }
            materialize_libpq_aliases(dst_lib)
        }
    }

    if (dir.exists(dst_lib)) {
        cat("  ✓ Staged bundled local_pg runtime at ", dst_root, "\n", sep = "")
    } else {
        cat("  ℹ local_pg staged without lib directory (headers only).\n")
    }

    invisible(TRUE)
}

print_ducklake_runtime_diagnostics <- function() {
    cat("\n[INFO] DuckLake runtime settings:\n")
    cat("  AHRI_TRE_DUCKLAKE_AUTO_MIGRATION=", env_get_first(c("AHRI_TRE_DUCKLAKE_AUTO_MIGRATION"), default = "<unset>"), "\n", sep = "")
    cat("  AHRI_TRE_SKIP_DUCKLAKE_ATTACH=", env_get_first(c("AHRI_TRE_SKIP_DUCKLAKE_ATTACH"), default = "<unset>"), "\n", sep = "")

    duckdb_version <- tryCatch(
        as.character(utils::packageVersion("duckdb")),
        error = function(e) "<not installed>"
    )
    cat("  duckdb package version=", duckdb_version, "\n", sep = "")

    if (identical(duckdb_version, "<not installed>")) {
        return(invisible(NULL))
    }

    con <- NULL
    tryCatch({
        con <- DBI::dbConnect(duckdb::duckdb())
        on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)

        engine <- DBI::dbGetQuery(con, "SELECT version() AS duckdb_engine_version")
        if (nrow(engine) > 0 && "duckdb_engine_version" %in% names(engine)) {
            cat("  duckdb engine version=", as.character(engine$duckdb_engine_version[[1]]), "\n", sep = "")
        }

        ext <- DBI::dbGetQuery(
            con,
            "SELECT extension_name, installed, loaded, extension_version FROM duckdb_extensions() WHERE extension_name = 'ducklake'"
        )
        if (nrow(ext) > 0) {
            cat(
                "  ducklake extension version=", as.character(ext$extension_version[[1]]),
                " (installed=", as.character(ext$installed[[1]]), ", loaded=", as.character(ext$loaded[[1]]), ")\n",
                sep = ""
            )
        } else {
            cat("  ducklake extension metadata unavailable\n")
        }
    }, error = function(e) {
        cat("  [WARN] Could not inspect ducklake extension metadata: ", conditionMessage(e), "\n", sep = "")
    })
}

# Read package info
desc <- read.dcf("DESCRIPTION")
pkg <- desc[1, "Package"]
ver <- desc[1, "Version"]

print_header("Building ahriTRErRs Package")
cat("\nPackage:", pkg)
cat("\nVersion:", ver)
cat("\nPlatform:", .Platform$OS.type)
cat("\nR version:", R.version.string)
print_ducklake_runtime_diagnostics()

local_dir <- ".local"
local_backup_dir <- file.path(normalizePath(".."), ".ahriTRErRs_local_backup")
local_dir_moved <- FALSE
rproj_user_dir <- ".Rproj.user"
rproj_user_backup_dir <- file.path(normalizePath(".."), ".ahriTRErRs_rproj_user_backup")
rproj_user_moved <- FALSE

restore_local_dir <- function() {
    if (isTRUE(local_dir_moved) && dir.exists(local_backup_dir)) {
        if (dir.exists(local_dir)) {
            warning(".local already exists; skipping backup restore to avoid overwriting.", call. = FALSE)
            return(invisible(NULL))
        }
        ok <- move_path_portable(local_backup_dir, local_dir, ".local backup restore")
        if (isTRUE(ok)) {
            cat("\n[INFO] Restored .local directory after build.\n")
        } else {
            warning("Failed to restore .local directory from backup.", call. = FALSE)
        }
    }
}

restore_rproj_user_dir <- function() {
    if (isTRUE(rproj_user_moved) && dir.exists(rproj_user_backup_dir)) {
        if (dir.exists(rproj_user_dir)) {
            warning(".Rproj.user already exists; skipping backup restore to avoid overwriting.", call. = FALSE)
            return(invisible(NULL))
        }
        ok <- move_path_portable(rproj_user_backup_dir, rproj_user_dir, ".Rproj.user backup restore")
        if (isTRUE(ok)) {
            cat("\n[INFO] Restored .Rproj.user directory after build.\n")
        } else {
            warning("Failed to restore .Rproj.user directory from backup.", call. = FALSE)
        }
    }
}

prepare_rproj_user_for_build <- function() {
    if (!dir.exists(rproj_user_dir)) {
        return(invisible(FALSE))
    }

    lock_files <- list.files(
        rproj_user_dir,
        recursive = TRUE,
        full.names = TRUE,
        all.files = TRUE,
        no.. = TRUE
    )
    lock_files <- lock_files[basename(lock_files) == "lock_file"]

    if (length(lock_files) > 0) {
        suppressWarnings(unlink(lock_files, force = TRUE))
        cat("  ℹ Removed ", length(lock_files), " transient .Rproj.user lock file(s) before build.\n", sep = "")
    }

    if (dir.exists(rproj_user_backup_dir)) {
        unlink(rproj_user_backup_dir, recursive = TRUE, force = TRUE)
    }

    moved <- move_path_portable(rproj_user_dir, rproj_user_backup_dir, ".Rproj.user")
    if (isTRUE(moved)) {
        rproj_user_moved <<- TRUE
        cat("\n[INFO] Temporarily moved .Rproj.user out of package tree for build stability.\n")
        cat("[INFO] Backup location:", rproj_user_backup_dir, "\n")
        return(invisible(TRUE))
    }

    warning("Could not move .Rproj.user directory; source tarball build may fail.", call. = FALSE)
    invisible(FALSE)
}

on.exit(restore_local_dir(), add = TRUE)
on.exit(restore_rproj_user_dir(), add = TRUE)

on.exit(unlink(file.path("inst", "vendor", "local_pg"), recursive = TRUE, force = TRUE), add = TRUE)

if (dir.exists(local_dir)) {
    if (dir.exists(local_backup_dir)) {
        unlink(local_backup_dir, recursive = TRUE, force = TRUE)
    }
    moved <- move_path_portable(local_dir, local_backup_dir, ".local")
    if (isTRUE(moved)) {
        local_dir_moved <- TRUE
        cat("\n[INFO] Temporarily moved .local out of package tree for build compatibility.\n")
        cat("[INFO] Backup location:", local_backup_dir, "\n")
    } else {
        warning("Could not move .local directory; source tarball build may fail.", call. = FALSE)
    }
}

print_step("Preparing RStudio project metadata for source build")
if (!prepare_rproj_user_for_build()) {
    cat("  ℹ .Rproj.user is absent or could not be moved; continuing build.\n")
}

print_step("Staging bundled PostgreSQL runtime into package")
stage_packaged_local_pg()



# Clean all old build artifacts to guarantee a fresh build
print_step("Cleaning old build artifacts from src/")
cleanup_src_artifacts()
cat("  ✓ Removed old .o, .so, .dll files from src/\n")

# Ensure src/pg_oauth_hook_connect.so is built and up to date on Linux.
helper_src <- "src/pg_oauth_hook_connect.c"
helper_so <- "src/pg_oauth_hook_connect.so"
helper_obj <- "src/pg_oauth_hook_connect.o"
if (identical(Sys.info()[["sysname"]], "Linux")) {
    print_step("Ensuring src/pg_oauth_hook_connect.so is present and up to date")
    if (!file.exists(helper_src)) {
        cat("  ℹ ", helper_src, " not found. Skipping optional helper build for this package.\n", sep = "")
    } else {
        need_build <- FALSE
        if (!file.exists(helper_so)) {
            cat("  ℹ ", helper_so, " does not exist. Will build.\n", sep = "")
            need_build <- TRUE
        } else if (file.info(helper_src)$mtime > file.info(helper_so)$mtime) {
            cat("  ℹ ", helper_so, " is older than ", helper_src, ". Will rebuild.\n", sep = "")
            need_build <- TRUE
        } else {
            cat("  ✓ ", helper_so, " is up to date.\n", sep = "")
        }
        if (need_build) {
        pgsql_include <- "local_pg/include"
        pgsql_include_libpq <- file.path(pgsql_include, "libpq")
        pgsql_lib <- "local_pg/lib"
        # Compile object file
        compile_cmd <- sprintf(
            'gcc -std=gnu2x -I"%s" -I"%s" -I/usr/local/lib/R/include -DNDEBUG -I/usr/local/include -fpic -g -O2 -c "%s" -o "%s"',
            pgsql_include, pgsql_include_libpq, helper_src, helper_obj
        )
        cat("  ℹ Compiling with: ", compile_cmd, "\n", sep = "")
        status <- system(compile_cmd)
        if (status != 0 || !file.exists(helper_obj)) {
            cat("  ✗ Failed to compile object file.\n")
            stop("Failed to compile helper object file.")
        }
        # Link shared object
        link_cmd <- sprintf(
            'gcc -shared -o "%s" "%s" -L"%s" -lpq',
            helper_so, helper_obj, pgsql_lib
        )
        cat("  ℹ Linking with: ", link_cmd, "\n", sep = "")
        status <- system(link_cmd)
        if (status != 0 || !file.exists(helper_so)) {
            cat("  ✗ Failed to link shared object.\n")
            stop("Failed to link helper shared object.")
        } else {
            cat("  ✓ Built ", helper_so, " using direct gcc.\n", sep = "")
        }
            unlink(helper_obj, force = TRUE)
        }
    }
} else {
    print_step("Skipping Linux-only pg_oauth helper shared object build")
    cat("  ℹ Native pg_oauth_hook_connect.so build is only required on Linux.\n")
}

unlink(helper_obj, force = TRUE)

# Create release directory (./release)
print_step("Creating release directory: ./release")
release_dir <- "release"
if (!dir.exists(release_dir)) {
    dir.create(release_dir, recursive = TRUE, showWarnings = FALSE)
    cat("  ✓ Created:", release_dir, "\n")
} else {
    cat("  ✓ Release directory already exists:", release_dir, "\n")
}

# Clean previous artifacts in current directory
print_step("Cleaning previous artifacts from current directory")
unlink(paste0(pkg, "_*.tar.gz"), force = TRUE)
unlink(paste0(pkg, "_*.zip"), force = TRUE)
cat("  ✓ Removed old artifacts from current directory\n")

# Clean previous artifacts in release directory
print_step("Cleaning previous artifacts from ./release directory")
unlink(file.path(release_dir, paste0(pkg, "_*.tar.gz")), force = TRUE)
unlink(file.path(release_dir, paste0(pkg, "_*.zip")), force = TRUE)
cat("  ✓ Removed old artifacts from ./release\n")

# Generate documentation
print_step("Generating documentation")
ensure_roxygen_package()
roxygen2::roxygenise(package.dir = ".")
cat("  ✓ Documentation generated\n")

# devtools::document() compiles the package (pkgload::load_all), leaving object
# files in src/. Clean them now so R CMD build does not see them and prompt interactively.
print_step("Cleaning compiled artifacts left by devtools::document()")
cleanup_src_artifacts()
cat("  ✓ Cleaned src/*.{o,so,dll}\n")

print_step("Building source tarball (.tar.gz) into ./release")
tarball <- NULL
use_devtools_tarball <- tolower(trimws(env_get_first(c("AHRI_TRE_USE_DEVTOOLS_TARBALL"), default = "false"))) %in% c("1", "true", "yes", "on")

run_base_r_build <- function() {
    cat("  Building source tarball with staged R CMD build...\n")

    stage_root <- tempfile("ahriTRErRs_build_stage_")
    stage_repo <- file.path(stage_root, pkg)
    dir.create(stage_repo, recursive = TRUE, showWarnings = FALSE)

    on.exit(unlink(stage_root, recursive = TRUE, force = TRUE), add = TRUE)

    copy_cmd <- paste0(
        "tar ",
        "--exclude='.git' ",
        "--exclude='.local-src' ",
        "--exclude='", pkg, ".Rcheck' ",
        "--exclude='..Rcheck' ",
        "--exclude='logs' ",
        "--exclude='release' ",
        "--exclude='.Rproj.user' ",
        "--exclude='.local' ",
        "-cf - . | tar -C ",
        shQuote(stage_repo),
        " -xf -"
    )
    copy_status <- system(copy_cmd)
    if (!identical(copy_status, 0L)) {
        cat("  ✗ Failed to stage source tree for tarball build.\n")
        return(NULL)
    }

    build_cmd <- paste0(
        "cd ", shQuote(stage_repo),
        " && printf 'y\\n' | R CMD build . --no-build-vignettes --no-manual --compact-vignettes=gs+qpdf"
    )
    build_status <- system(build_cmd)
    if (!identical(build_status, 0L)) {
        return(NULL)
    }

    candidates <- list.files(stage_repo, pattern = paste0("^", pkg, "_.*\\.tar\\.gz$"), full.names = TRUE)
    candidate <- if (length(candidates) > 0) candidates[[1]] else NULL
    if (!has_path_file(candidate)) {
        return(NULL)
    }

    target <- file.path(release_dir, basename(candidate))
    ok <- file.copy(candidate, target, overwrite = TRUE)
    if (!isTRUE(ok)) {
        return(NULL)
    }
    if (file.exists(target)) target else NULL
}

run_devtools_build <- function() {
    cat("  Building source tarball with devtools::build...\n")
    tryCatch(
        devtools::build(path = release_dir, binary = FALSE, vignettes = FALSE, manual = FALSE),
        error = function(e) NULL
    )
}

# Prefer base R build by default to avoid intermittent .git/index.lock copy races in devtools.
if (isTRUE(use_devtools_tarball)) {
    tarball <- run_devtools_build()
}

if (!has_path_file(tarball)) {
    tarball <- run_base_r_build()
    if (has_path_file(tarball)) {
        cat("  ✓ Source tarball created via R CMD build in ./release:", basename(tarball), "\n")
    } else {
        cat("  ✗ R CMD build did not produce a source tarball in ./release\n")
    }
}

# Optional last-resort fallback to devtools::build if base build fails.
if (!has_path_file(tarball) && !isTRUE(use_devtools_tarball)) {
    cat("  R CMD build fallback failed. Retrying with devtools::build...\n")
    tarball <- run_devtools_build()
    if (has_path_file(tarball)) {
        cat("  ✓ Source tarball created via devtools::build in ./release:", basename(tarball), "\n")
    }
}

# Verify source tarball was created in ./release
if (has_path_file(tarball)) {
    cat("  ✓ Source tarball created in ./release:", basename(tarball), "\n")
} else {
    cat("  ✗ Failed to create source tarball in ./release\n")
}

# Clean up any .tar.gz left in root (shouldn't be any, but just in case)
leftovers <- list.files(".", pattern = paste0("^", pkg, "_.*\\.tar\\.gz$"), full.names = TRUE)
if (length(leftovers) > 0) {
    for (f in leftovers) {
        target <- file.path(release_dir, basename(f))
        file.copy(f, target, overwrite = TRUE)
        file.remove(f)
        cat("  ✓ Moved tarball to ./release:", basename(f), "\n")
    }
}

# Build Windows binary (.zip)
zipball <- NULL
print_step("Building Windows binary (.zip)")
if (.Platform$OS.type == "windows") {
    zipball <- tryCatch({
        devtools::build(path = release_dir, binary = TRUE, vignettes = FALSE, manual = FALSE)
    }, error = function(e) {
        cat("  ERROR building Windows binary:", e$message, "\n")
        NULL
    })
    
    # Verify Windows binary was created
    if (!is.null(zipball) && file.exists(zipball)) {
        cat("  ✓ Windows binary created:", basename(zipball), "\n")
    } else {
        cat("  ✗ Failed to create Windows binary\n")
        # Try alternative build method
        cat("  Retrying with R CMD build --binary...\n")
        system2("R", c("CMD", "build", "--binary", "."), stdout = TRUE, stderr = TRUE)
        zipball <- list.files(release_dir, pattern = "\\.zip$", full.names = TRUE)
        if (length(zipball) == 0) {
            zipball <- list.files(".", pattern = "\\.zip$", full.names = TRUE)
        }
        if (length(zipball) > 0) {
            zipball <- zipball[1]
            cat("  ✓ Windows binary created via R CMD build:", basename(zipball), "\n")
        }
    }
} else {
    cat("  ℹ Skipping Windows binary (non-Windows platform)\n")
    cat("  ℹ To create Windows binary on this platform, use: R CMD build --binary .\n")
}

# Copy artifacts to release directory (./release)
print_step("Copying artifacts to ./release directory")
release_artifacts <- character()

# Copy source tarball (only if not already in ./release)
if (has_path_file(tarball)) {
    target <- file.path(release_dir, basename(tarball))
    if (normalizePath(tarball) != normalizePath(target)) {
        file.copy(tarball, target, overwrite = TRUE)
        cat("  ✓ Copied to ./release:", basename(tarball), "\n")
    } else {
        cat("  ✓ Source tarball already in ./release:", basename(tarball), "\n")
    }
    release_artifacts <- c(release_artifacts, target)
} else {
    cat("  ✗ Source tarball not found for copying\n")
}

# Copy Windows binary
if (has_path_file(zipball)) {
    target <- file.path(release_dir, basename(zipball))
    if (normalizePath(zipball) != normalizePath(target)) {
        file.copy(zipball, target, overwrite = TRUE)
        cat("  ✓ Copied to ./release:", basename(zipball), "\n")
    } else {
        cat("  ✓ Windows binary already in ./release:", basename(zipball), "\n")
    }
    release_artifacts <- c(release_artifacts, target)
}

# Verify release artifacts exist in ./release
print_step("Verifying artifacts in ./release directory")
expected_tarball <- file.path(release_dir, paste0(pkg, "_", ver, ".tar.gz"))
expected_zip <- file.path(release_dir, paste0(pkg, "_", ver, ".zip"))

if (file.exists(expected_tarball)) {
    file_size <- file.info(expected_tarball)$size
    cat("  ✓", basename(expected_tarball), "exists (", format(file_size, scientific = FALSE), "bytes)\n")
} else {
    cat("  ✗", basename(expected_tarball), "is MISSING from ./release!\n")
}

if (.Platform$OS.type == "windows") {
    if (file.exists(expected_zip)) {
        file_size <- file.info(expected_zip)$size
        cat("  ✓", basename(expected_zip), "exists (", format(file_size, scientific = FALSE), "bytes)\n")
    } else {
        cat("  ✗", basename(expected_zip), "is MISSING from ./release!\n")
    }
}

# Print summary
print_header("Build Complete - Artifacts in ./release")
cat("\nRelease artifacts in ./release folder:\n")
cat(paste(rep("-", 80), collapse = ""), "\n")

if (length(release_artifacts) > 0) {
    for (artifact in release_artifacts) {
        if (file.exists(artifact)) {
            file_size <- file.info(artifact)$size
            cat("  📦", basename(artifact), "\n")
            cat("     Location:", normalizePath(artifact), "\n")
            cat("     Size:", format(file_size, scientific = FALSE), "bytes\n\n")
        }
    }
} else {
    cat("  ✗ No artifacts were created in ./release\n")
}

# Installation instructions
cat(paste(rep("=", 80), collapse = ""), "\n")
cat("INSTALLATION INSTRUCTIONS\n")
cat(paste(rep("=", 80), collapse = ""), "\n")

if (file.exists(expected_tarball)) {
    cat("\n  📦 Install source package (all platforms):\n")
    cat("     install.packages(\"./release/", pkg, "_", ver, ".tar.gz\", repos = NULL, type = \"source\")\n", sep = "")
}

if (.Platform$OS.type == "windows" && file.exists(expected_zip)) {
    cat("\n  📦 Install Windows binary (Windows only):\n")
    cat("     install.packages(\"./release/", pkg, "_", ver, ".zip\", repos = NULL, type = \"win.binary\")\n", sep = "")
}

cat("\n  📦 Load the package:\n")
cat("     library(", pkg, ")\n", sep = "")

cat("\n")

# Automatically install the freshly built artifact
print_step("Installing package from freshly built artifact")
auto_install_release <- tolower(trimws(env_get_first(c("AHRI_TRE_AUTO_INSTALL_RELEASE"), default = "true"))) %in% c("1", "true", "yes", "on")

install_target <- NULL
install_type <- "source"

if (.Platform$OS.type == "windows" && file.exists(expected_zip)) {
    install_target <- expected_zip
    install_type <- "win.binary"
} else if (file.exists(expected_tarball)) {
    install_target <- expected_tarball
}

if (!isTRUE(auto_install_release)) {
    cat("  ℹ Auto-install disabled via AHRI_TRE_AUTO_INSTALL_RELEASE.\n")
} else if (!has_path_file(install_target)) {
    cat("  ✗ No installable artifact found; skipping automatic install.\n")
} else {
    cat("  ℹ Installing from: ", install_target, " (type=", install_type, ")\n", sep = "")
    install_ok <- tryCatch({
        install.packages(install_target, repos = NULL, type = install_type)
        TRUE
    }, error = function(e) {
        cat("  ✗ Automatic install failed: ", conditionMessage(e), "\n", sep = "")
        FALSE
    })

    if (isTRUE(install_ok)) {
        cat("  ✓ Package installed successfully from release artifact.\n")
    }
}

print_step("Restoring temporary build staging")
restore_rproj_user_dir()
restore_local_dir()
unlink(file.path("inst", "vendor", "local_pg"), recursive = TRUE, force = TRUE)

print_header("Done")