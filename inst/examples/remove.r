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

bootstrap_example_session <- function() {
	ensure_ahriTRErRs_available()

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

	datastore <- tryCatch(
		{
			cat("[INFO] Opening DataStore with OAuth...\n")
			opendatastore_oauth(
				DataStore$new(),
				oauth_config = list(session = oauth_session),
				migrate_catalog = TRUE
			)
		},
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

	if (is.null(datastore)) {
		return(NULL)
	}

	list(runtime = runtime, datastore = datastore)
}

ensure_ahriTRErRs_available()

bootstrap <- bootstrap_example_session()
if (is.null(bootstrap)) {
	invisible(FALSE)
	quit(save = "no", status = 0L)
}

runtime <- bootstrap$runtime

target_domain_patterns <- c(
    "vocab_test_domain_", 
	"vocab_test_",
    "df2ds_study_", 
    "survey_",
    "domain_",
    "domain_177",
    "domain_a_",
    "domain_b_",
    "domain_datafiles_",
    "domain_sql2ds_",
    "domain_varcrud_",
    "measurements_",
    "demo_",
    "reptest_",
    "Test-",
    "demographics_"
)

target_study_patterns <- c(
	"filetods_",
	"df2ds_study_",
	"study_",
	"autofix_no_bump_",
	"IMPACT BP Training",
	"Rfam Database Collection"
)

datastore <- bootstrap$datastore

cat("[INFO] Runtime platform: ", runtime, "\n", sep = "")
cat("[INFO] Removing domains containing: ", paste(target_domain_patterns, collapse = ", "), "\n", sep = "")
cat("[INFO] Removing studies containing: ", paste(target_study_patterns, collapse = ", "), "\n", sep = "")

studies <- get_studies(datastore)
study_names <- as.character(studies$name)
study_matches <- Reduce(
	`|`,
	lapply(target_study_patterns, function(pattern) {
		grepl(pattern, study_names, fixed = TRUE)
	})
)
matching_studies <- studies[study_matches, , drop = FALSE]

study_deleted_count <- 0L
study_failed <- character(0)
if (nrow(matching_studies) == 0) {
	cat("[INFO] No matching studies found.\n")
} else {
	cat("[INFO] Matching studies found: ", nrow(matching_studies), "\n", sep = "")
	for (i in seq_len(nrow(matching_studies))) {
		study_name <- as.character(matching_studies$name[[i]])
		cat("[INFO] Deleting study ", i, "/", nrow(matching_studies), ": ", study_name, "\n", sep = "")
		study_err <- tryCatch(
			{
				delete_study(datastore, study = study_name, force = TRUE, cascade = TRUE, archive = FALSE)
				NULL
			},
			error = function(e) e
		)

		if (is.null(study_err)) {
			study_deleted_count <- study_deleted_count + 1L
			next
		}

		msg <- conditionMessage(study_err)
		study_failed <- c(study_failed, paste0(study_name, " -> ", msg))
		cat("[WARN] Study skipped: ", msg, "\n", sep = "")
	}
}

domains <- get_domains(datastore)
domain_names <- as.character(domains$name)
name_matches <- Reduce(
	`|`,
	lapply(target_domain_patterns, function(pattern) {
		grepl(pattern, domain_names, fixed = TRUE)
	})
)
matches <- domains[name_matches, , drop = FALSE]

if (nrow(matches) == 0) {
	cat("[INFO] No matching domains found.\n")
} else {
	cat("[INFO] Matches found: ", nrow(matches), "\n", sep = "")
	deleted_count <- 0L
	failed <- character(0)

	for (i in seq_len(nrow(matches))) {
		domain_name <- as.character(matches$name[[i]])
		domain_uri <- if ("uri" %in% names(matches)) as.character(matches$uri[[i]]) else NA_character_
		domain_obj <- get_domain(
			datastore,
			name = domain_name,
			uri = if (!is.na(domain_uri) && nzchar(domain_uri)) domain_uri else NULL,
			return_mode = "objects"
		)

		cat("[INFO] Deleting ", i, "/", nrow(matches), ": ", domain_name,
				if (!is.na(domain_uri) && nzchar(domain_uri)) paste0(" (", domain_uri, ")") else "",
				"\n", sep = "")

		delete_err <- tryCatch(
			{
				delete_domain(datastore, domain = domain_obj, force = TRUE)
				NULL
			},
			error = function(e) e
		)

		if (!is.null(delete_err) && grepl("last domain for", conditionMessage(delete_err), fixed = TRUE)) {
			blocking_studies <- DBI::dbGetQuery(
				datastore$store,
				"SELECT s.name
				 FROM studies s
				 JOIN study_domains sd ON s.study_id = sd.study_id
				 WHERE sd.domain_id = $1
				   AND NOT EXISTS (
				     SELECT 1
				     FROM study_domains sd2
				     WHERE sd2.study_id = s.study_id
				       AND sd2.domain_id <> $1
				   )",
				list(domain_obj$domain_id)
			)

			if (nrow(blocking_studies) > 0) {
				cat("[INFO] Removing blocking studies linked only to domain: ", nrow(blocking_studies), "\n", sep = "")
				for (j in seq_len(nrow(blocking_studies))) {
					study_name <- as.character(blocking_studies$name[[j]])
					cat("[INFO] Deleting study ", j, "/", nrow(blocking_studies), ": ", study_name, "\n", sep = "")
					delete_study(datastore, study = study_name, force = TRUE, cascade = TRUE, archive = FALSE)
				}

				delete_err <- tryCatch(
					{
						delete_domain(datastore, domain = domain_obj, force = TRUE)
						NULL
					},
					error = function(e) e
				)
			}
		}

		if (is.null(delete_err)) {
			deleted_count <- deleted_count + 1L
			next
		}

		msg <- conditionMessage(delete_err)
		failed <- c(failed, paste0(domain_name, " -> ", msg))
		cat("[WARN] Skipped: ", msg, "\n", sep = "")
	}

	cat("\n[INFO] Delete summary: deleted=", deleted_count,
		", failed=", length(failed), "\n", sep = "")
	cat("[INFO] Study delete summary: deleted=", study_deleted_count,
		", failed=", length(study_failed), "\n", sep = "")
	if (length(failed) > 0) {
		cat("[INFO] Failed domains:\n")
		for (line in failed) {
			cat(" - ", line, "\n", sep = "")
		}
	}
	if (length(study_failed) > 0) {
		cat("[INFO] Failed studies:\n")
		for (line in study_failed) {
			cat(" - ", line, "\n", sep = "")
		}
	}
}

cat("\nClosing DataStore\n")
try(closedatastore(datastore), silent = TRUE)

invisible(NULL)
