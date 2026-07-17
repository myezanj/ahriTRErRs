suppressPackageStartupMessages(library(ahriTRErRs))
if (!("opendatastore_oauth" %in% getNamespaceExports("ahriTRErRs"))) {
  cat("[INFO] This legacy example uses datastore APIs not exported by the current ahriTRErRs build.\n")
  cat("[INFO] Skipping execution.\n")
  quit(save = "no", status = 0L)
}

find_repo_root <- function(start = getwd()) {
	current <- normalizePath(start, winslash = "/", mustWork = TRUE)
	repeat {
		if (file.exists(file.path(current, "DESCRIPTION")) && dir.exists(file.path(current, "inst", "examples"))) return(current)
		parent <- dirname(current)
		if (identical(parent, current)) return(NULL)
		current <- parent
	}
}

ensure_ahriTRErRs_available <- function() {
	if ("package:ahriTRErRs" %in% search() || "ahriTRErRs" %in% loadedNamespaces() || requireNamespace("ahriTRErRs", quietly = TRUE)) {
		suppressPackageStartupMessages(library("ahriTRErRs", character.only = TRUE))
		return(invisible(TRUE))
	}

	repo_root <- find_repo_root()
	if (is.null(repo_root)) stop("Could not locate the ahriTRErRs repository root for load_all().")

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

bootstrap_example_session <- function() {
	ensure_ahriTRErRs_available()
	old_auto_repair <- Sys.getenv("AHRI_TRE_AUTO_REPAIR_ON_OPEN", unset = NA_character_)
	on.exit({
		if (is.na(old_auto_repair)) {
			Sys.unsetenv("AHRI_TRE_AUTO_REPAIR_ON_OPEN")
		} else {
			Sys.setenv(AHRI_TRE_AUTO_REPAIR_ON_OPEN = old_auto_repair)
		}
	}, add = TRUE)
	Sys.setenv(AHRI_TRE_AUTO_REPAIR_ON_OPEN = "false")
	runtime <- ahriTRErRs::runtime_platform()
	if (identical(runtime, "local") && file.exists(".env")) {
		ahriTRErRs:::.load_dotenv_file(".env", overwrite = FALSE)
	}

	if (
		nzchar(Sys.getenv("JUPYTERHUB_USER", "")) &&
		!nzchar(Sys.getenv("AHRI_TRE_JUPYTERHUB_HOST", "")) &&
		nzchar(Sys.getenv("TRE_SERVER", ""))
	) {
		Sys.setenv(AHRI_TRE_JUPYTERHUB_HOST = paste0("https://", Sys.getenv("TRE_SERVER")))
		cat("[INFO] Set AHRI_TRE_JUPYTERHUB_HOST from TRE_SERVER: ", Sys.getenv("AHRI_TRE_JUPYTERHUB_HOST"), "\n", sep = "")
	}

	oauth_session <- ahriTRErRs::cached_oauth_options_from_env()
	cat("[INFO] OAuth config: issuer=", oauth_session$issuer, ", client_id=", substr(oauth_session$client_id, 1, 8), "...\n", sep = "")
	cat("[INFO] Initializing DataStore with environment variables...\n")
	cat(
		"[INFO] Environment: TRE_SERVER=", Sys.getenv("TRE_SERVER"),
		", TRE_TEST_DBNAME=", Sys.getenv("TRE_TEST_DBNAME"),
		", ORCID_ISSUER=", Sys.getenv("ORCID_ISSUER"),
		"\n",
		sep = ""
	)
	datastore <- DataStore$new()
	cat("[INFO] Opening DataStore with OAuth...\n")
	datastore <- opendatastore_oauth(
		datastore,
		oauth_config = list(session = oauth_session),
		migrate_catalog = TRUE
	)

	list(runtime = runtime, datastore = datastore)
}

bootstrap <- bootstrap_example_session()

if (is.null(bootstrap)) {
	invisible(FALSE)
} else {
	runtime <- bootstrap$runtime
	datastore <- bootstrap$datastore
	on.exit(closedatastore(datastore), add = TRUE)

	cat("[INFO] Runtime platform: ", runtime, "\n", sep = "")
	cat("[INFO] Store connected: ", !is.null(datastore$store), "\n", sep = "")
	cat("[INFO] Lake connected: ", !is.null(datastore$lake), "\n", sep = "")

	domain_name <- "Basic Science"
	study_name <- "IMPACT BP Training"

	domain <- get_domain(datastore, domain_name, return_mode = "objects")
	if (is.null(domain) || (is.data.frame(domain) && nrow(domain) == 0)) {
		stop("Domain not found: ", domain_name)
	}

	study <- get_study(datastore, study_name, domain = domain, return_mode = "objects")
	if (is.null(study) || (is.data.frame(study) && nrow(study) == 0)) {
		# Fallback in case the study was moved to another domain.
		study <- get_study(datastore, study_name, return_mode = "objects")
	}
	if (is.null(study) || (is.data.frame(study) && nrow(study) == 0)) {
		stop("Study not found: ", study_name)
	}

	study_name_value <- if (is.data.frame(study) && "name" %in% names(study)) {
		as.character(study$name[[1]])
	} else {
		as.character(study$name)
	}

	datasets <- get_study_datasets(datastore, study, include_versions = TRUE)
	if (nrow(datasets) == 0) {
		stop("No datasets found for study: ", study_name_value)
	}

	cat("\n[INFO] Selected study: ", study_name_value, "\n", sep = "")
	cat("[INFO] Dataset versions found: ", nrow(datasets), "\n", sep = "")

	summary_cols <- intersect(
		c("dataset_id", "name", "version", "major", "minor", "patch", "readable", "table_name"),
		names(datasets)
	)
	print(datasets[, summary_cols, drop = FALSE])

	dataset_names <- sort(unique(as.character(datasets$name)))
	for (dataset_name in dataset_names) {
		cat("\n============================================================\n")
		cat("[INFO] Reading dataset: ", dataset_name, "\n", sep = "")

		versions <- get_dataset_versions(datastore, study_name_value, dataset_name)
		if (nrow(versions) == 0) {
			cat("[WARN] No versions found for dataset.\n")
			next
		}

		versions <- versions[order(
			-as.integer(versions$major),
			-as.integer(versions$minor),
			-as.integer(versions$patch)
		), , drop = FALSE]

		readable_rows <- data.frame(stringsAsFactors = FALSE)
		readable_version <- ""

		for (i in seq_len(nrow(versions))) {
			candidate <- versions[i, , drop = FALSE]
			candidate_version <- if ("version" %in% names(candidate)) {
				as.character(candidate$version[[1]])
			} else {
				paste0(candidate$major[[1]], ".", candidate$minor[[1]], ".", candidate$patch[[1]])
			}

			rows <- tryCatch(
				read_dataset(datastore, candidate, limit = 10L, on_missing = "error"),
				error = function(e) {
					cat("[WARN] Could not read version ", candidate_version, ": ", conditionMessage(e), "\n", sep = "")
					NULL
				}
			)

			if (!is.null(rows)) {
				readable_rows <- rows
				readable_version <- candidate_version
				break
			}
		}

		if (!nzchar(readable_version)) {
			cat("[WARN] No readable versions found for this dataset.\n")
			next
		}

		cat("[INFO] Using version: ", readable_version, "\n", sep = "")
		cat("[INFO] Rows read: ", nrow(readable_rows), ", columns: ", ncol(readable_rows), "\n", sep = "")
		print(utils::head(readable_rows, 10L))
	}

	cat("\n[INFO] Finished IMPACT BP Training read example.\n")

	invisible(TRUE)
}
