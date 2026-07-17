suppressPackageStartupMessages(library(ahriTRErRs))
if (!("opendatastore_oauth" %in% getNamespaceExports("ahriTRErRs"))) {
  cat("[INFO] This legacy example uses datastore APIs not exported by the current ahriTRErRs build.\n")
  cat("[INFO] Skipping execution.\n")
  quit(save = "no", status = 0L)
}

find_repo_root <- function(start = getwd()) {
	current <- normalizePath(start, winslash = "/", mustWork = TRUE)
	repeat {
		if (file.exists(file.path(current, "DESCRIPTION")) && dir.exists(file.path(current, "inst", "examples"))) {
			return(current)
		}
		parent <- dirname(current)
		if (identical(parent, current)) {
			return(NULL)
		}
		current <- parent
	}
}

ensure_ahriTRErRs_available <- function() {
	if (
		"package:ahriTRErRs" %in% search() ||
		"ahriTRErRs" %in% loadedNamespaces() ||
		requireNamespace("ahriTRErRs", quietly = TRUE)
	) {
		suppressPackageStartupMessages(library("ahriTRErRs", character.only = TRUE))
		return(invisible(TRUE))
	}

	repo_root <- find_repo_root()
	if (is.null(repo_root)) {
		stop("Could not locate the ahriTRErRs repository root for load_all().")
	}

	if (requireNamespace("pkgload", quietly = TRUE)) {
		pkgload::load_all(repo_root, export_all = FALSE, quiet = TRUE)
	} else if (requireNamespace("devtools", quietly = TRUE)) {
		devtools::load_all(repo_root, quiet = TRUE)
	} else {
		stop("Package 'ahriTRErRs' is not installed and neither pkgload nor devtools is available.")
	}

	suppressPackageStartupMessages(library("ahriTRErRs", character.only = TRUE))
	invisible(TRUE)
}

is_connectivity_failure <- function(message) {
	grepl(
		paste(
			c(
				"could not translate host name",
				"Temporary failure in name resolution",
				"Name or service not known",
				"Connection refused",
				"No route to host",
				"Network is unreachable",
				"timeout expired",
				"could not connect to server",
				"server is unreachable"
			),
			collapse = "|"
		),
		message,
		ignore.case = TRUE
	)
}

ensure_ahriTRErRs_available()

env_or <- function(name, default = "") {
	value <- Sys.getenv(name, unset = "")
	if (nzchar(value)) value else default
}

if (file.exists(".env")) ahriTRErRs:::.load_dotenv_file(".env", overwrite = FALSE)

to_table <- function(versions) {
	tbl <- data.frame(
		version_id = vapply(versions, function(v) as.character(v$version_id), character(1)),
		major = as.integer(vapply(versions, function(v) v$major, numeric(1))),
		minor = as.integer(vapply(versions, function(v) v$minor, numeric(1))),
		patch = as.integer(vapply(versions, function(v) v$patch, numeric(1))),
		stringsAsFactors = FALSE
	)
	tbl$version <- sprintf("%d.%d.%d", tbl$major, tbl$minor, tbl$patch)
	tbl[order(tbl$major, tbl$minor, tbl$patch), c("version", "version_id"), drop = FALSE]
}

main <- function(
	domain_name = "Basic Science",
	study_name = "The Biology of Subclinical Asymptomic TB",
	asset_name = "scbio_aim1_eav",
	delete_study_when_empty = TRUE
) {
	ds <- DataStore$new(
		server = env_or("POSTGRES_HOST", env_or("PGHOST", env_or("TRE_SERVER", "localhost"))),
		dbname = env_or("TRE_DBNAME", env_or("TRE_TEST_DBNAME", env_or("PGDATABASE", "AHRI_TRER"))),
		user = env_or("POSTGRES_USER", env_or("PGUSER", env_or("TRE_USER", ""))),
		password = env_or("POSTGRES_PASSWORD", env_or("PGPASSWORD", env_or("TRE_PASSWORD", ""))),
		port = as.integer(env_or("POSTGRES_PORT", env_or("PGPORT", env_or("TRE_PORT", "5432")))),
		sslmode = env_or("POSTGRES_SSLMODE", env_or("PGSSLMODE", env_or("TRE_SSLMODE", "require"))),
		lake_data = env_or("TRE_TEST_LAKE_PATH", env_or("TRE_LAKE_DATA", "/data/datalake")),
		lake_db = env_or("TRE_TEST_LAKE_DB", "ducklake_catalog")
	)
	on.exit(try(closedatastore(ds), silent = TRUE), add = TRUE)

	ds <- tryCatch(
		suppressWarnings(opendatastore_oauth(ds, migrate_catalog = TRUE)),
		error = function(e) {
			message_text <- conditionMessage(e)
			if (is_connectivity_failure(message_text)) {
				cat("[WARN] Could not connect to the TRE datastore from this runtime.\n")
				cat("[WARN] TRE_SERVER=", Sys.getenv("TRE_SERVER", unset = ""), "\n", sep = "")
				cat("[WARN] TRE_TEST_DBNAME=", Sys.getenv("TRE_TEST_DBNAME", unset = ""), "\n", sep = "")
				cat("[WARN] Skipping example execution because the configured PostgreSQL host is unreachable.\n")
				cat("[WARN] Details: ", message_text, "\n", sep = "")
				return(NULL)
			}
			stop(e)
		}
	)
	if (is.null(ds)) {
		return(invisible(FALSE))
	}
	domain <- get_domain(ds, domain_name, return_mode = "objects")
	if (is.null(domain)) {
		cat("[INFO] Domain not found: ", domain_name, ". Nothing to clean.\n", sep = "")
		return(invisible(TRUE))
	}
	study <- get_study(ds, study_name, domain = domain, return_mode = "objects")
	if (is.null(study)) {
		cat("[INFO] Study not found: ", study_name, ". Nothing to clean.\n", sep = "")
		return(invisible(TRUE))
	}
	asset <- get_asset(ds, study, asset_name, asset_type = "file")
	if (is.null(asset)) {
		cat("[INFO] Asset not found: ", asset_name, ". Nothing to clean.\n", sep = "")
		return(invisible(TRUE))
	}
	versions <- get_asset_versions(ds, asset, return_mode = "objects")
	if (length(versions) == 0) {
		cat("[INFO] No versions found for asset: ", asset_name, ". Nothing to delete.\n", sep = "")
		return(invisible(TRUE))
	}

	before_tbl <- to_table(versions)
	cat("BEFORE:\n"); print(before_tbl, row.names = FALSE)
	delete_asset(ds, asset, force = TRUE, delete_physical = TRUE)
	cat("DELETED_ASSET:", asset_name, "\n")
	cat("DELETED_VERSIONS:\n")
	print(before_tbl, row.names = FALSE)

	remaining_assets <- get_study_assets(ds, study)
	cat("REMAINING_STUDY_ASSETS:", nrow(remaining_assets), "\n", sep = "")
	if (isTRUE(delete_study_when_empty) && nrow(remaining_assets) == 0) {
		delete_study(ds, study = study, force = TRUE, cascade = TRUE, archive = FALSE)
		cat("DELETED_EMPTY_STUDY:", study_name, "\n", sep = "")
	}
}

main()
