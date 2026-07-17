bootstrap_helper_candidates <- c(file.path("inst", "examples", "bootstrap_helpers.r"), "bootstrap_helpers.r")
bootstrap_helper_path <- bootstrap_helper_candidates[file.exists(bootstrap_helper_candidates)][1]
if (is.na(bootstrap_helper_path) || !nzchar(bootstrap_helper_path)) {
	stop("Could not locate inst/examples/bootstrap_helpers.r")
}
source(bootstrap_helper_path, local = TRUE)
if (exists("ensure_ahriTRErRs_available", mode = "function")) {
	ensure_ahriTRErRs_available()
} else if (exists("ensure_ahriTREr_available", mode = "function")) {
	# Backward-compatible fallback when older helper scripts are in use.
	ensure_ahriTREr_available()
} else {
	stop("Could not locate a package bootstrap helper function.")
}

start_time <- Sys.time()
cat("Execution started at:", format(start_time, "%Y-%m-%d %H:%M:%S %Z"), "\n")

bootstrap <- bootstrap_example_session()
if (is.null(bootstrap)) {
	invisible(FALSE)
	quit(save = "no", status = 0L)
}

runtime <- bootstrap$runtime
datastore <- bootstrap$datastore
on.exit({
	if (!is.null(datastore)) {
		cat("Closing DataStore\n")
		try(closedatastore(datastore), silent = TRUE)
	}
}, add = TRUE)

domain_name <- "Basic Science"
study_name <- "The Biology of Subclinical Asymptomic TB"

bootstrap <- ahriTRErRs::example_ensure_domain_study(
	datastore,
	domain_name,
	study_name,
	study_description = paste0("The Biology of Subclinical Asymptomic TB dataset ingest for ", study_name),
	study_external_id = study_name
)
domain <- bootstrap$domain
study <- bootstrap$study

ensure_human_host_participants <- function(ds, domain, study, dataset) {
	transformation <- add_transformation(
		ds,
		Transformation$new(
			"entity",
			"Map Participant_ID values to Human Host entity instances",
			file_path = "inst/examples/ingest_file_example.r"
		)
	)

	human_host <- get_entity(ds, domain$domain_id, "Human Host")
	if (is.null(human_host)) {
		human_host <- upsert_entity(
			ds,
			Entity$new(
				name = "Human Host",
				domain = domain,
				description = "Human host participants identified from the Participant_ID column."
			)
		)
	}

	variables <- get_dataset_variables(ds, dataset)
	participant_var <- variables[variables$name == "Participant_ID", , drop = FALSE]
	if (nrow(participant_var) == 0) {
		stop("Dataset variable not found: Participant_ID")
	}

	rows <- read_dataset(
		ds,
		study_name = study$name,
		dataset_name = dataset$name[[1]],
		include_versions = TRUE
	)
	participant_ids <- sort(unique(trimws(as.character(rows$Participant_ID))))
	participant_ids <- participant_ids[nzchar(participant_ids) & !is.na(participant_ids)]

	if (length(participant_ids) == 0) {
		stop("No non-empty Participant_ID values found in dataset")
	}

	existing_study_links <- list_study_entity_instances(
		ds,
		study,
		entity = human_host,
		return_mode = "data.frame"
	)
	existing_study_links <- existing_study_links[
		!is.na(existing_study_links$external_id) & nzchar(existing_study_links$external_id),
		,
		drop = FALSE
	]
	if (nrow(existing_study_links) > 0) {
		existing_study_links <- existing_study_links[
			!duplicated(existing_study_links$external_id),
			,
			drop = FALSE
		]
		study_instance_ids <- stats::setNames(
			as.character(existing_study_links$entity_instance_id),
			existing_study_links$external_id
		)
	} else {
		study_instance_ids <- character()
	}

	existing_dataset_links <- list_dataset_version_entities(ds, dataset, return_mode = "data.frame")
	linked_instance_ids <- unique(as.character(existing_dataset_links$entity_instance_id))
	linked_instance_ids <- linked_instance_ids[!is.na(linked_instance_ids)]

	created_instances <- 0L
	added_dataset_links <- 0L
	skipped_dataset_links <- 0L

	for (participant_id in participant_ids) {
		existing_instance_id <- unname(study_instance_ids[participant_id])

		if (length(existing_instance_id) > 0 && existing_instance_id %in% linked_instance_ids) {
			skipped_dataset_links <- skipped_dataset_links + 1L
			next
		}

		if (length(existing_instance_id) > 0) {
			entity_instance <- get_entity_instance(ds, existing_instance_id[[1]])
		} else {
			entity_instance <- add_entity_instance(
				ds,
				EntityInstance$new(
					human_host,
					label = participant_id,
					transformation_id = transformation$transformation_id
				)
			)
			add_study_entity_instance(
				ds,
				StudyEntityInstance$new(
					study,
					entity_instance,
					external_id = participant_id,
					transformation_id = transformation$transformation_id
				)
			)
			study_instance_ids[[participant_id]] <- as.character(entity_instance$instance_id)
			created_instances <- created_instances + 1L
		}

		add_dataset_version_entity(
			ds,
			dataset,
			entity_instance,
			entity_variable_id = participant_var$variable_id[[1]],
			transformation_id = transformation$transformation_id
		)
		linked_instance_ids <- c(linked_instance_ids, as.character(entity_instance$instance_id))
		added_dataset_links <- added_dataset_links + 1L
	}

	cat("Linked", length(participant_ids), "Participant_ID values to Human Host entity instances.\n")
	cat("Created", created_instances, "new Human Host entity instances.\n")
	cat("Added", added_dataset_links, "dataset links and skipped", skipped_dataset_links, "existing links.\n")
	cat("Entity ID:", human_host$entity_id, "\n")

	invisible(human_host)
}

#file_path <- "inst/extdata/live-births-england-and-wales-1938-2024.csv"
file_path <- "inst/extdata/sctb_bio_df_collated_data.csv"

if (!file.exists(file_path)) {
	stop("File does not exist: ", file_path)
}

asset_name <- "sctb_bio_df_collated_data_2026_05_30"
description <- "The Biology of Subclinical Asymptomic TB collated data (2026-05-30) ingested from CSV"
dataset_name <- "sctb_bio_df_collated_data_2026_05_30_ds"
dataset_description <- "Dataset materialized from The Biology of Subclinical Asymptomic TB collated data (2026-05-30) CSV file"

cat("Domain:", domain$name, "\n")
cat("Study:", study$name, "\n")
cat("File:", normalizePath(file_path), "\n")
cat("Asset:", asset_name, "\n")
cat("Dataset:", dataset_name, "\n")

# datafile <- ingest_file(
# 	ds = datastore,
# 	study = study,
# 	asset_name = asset_name,
# 	file_path = file_path,
# 	edam_format = "http://edamontology.org/format_3752",
# 	description = description,
# 	compress = FALSE,
# 	new_version = FALSE
# )

# dataset <- datafile_to_dataset(
# 	ds = datastore,
# 	datafile = datafile,
# 	domain = domain,
# 	dataset_name = dataset_name,
# 	format = "csv",
# 	description = dataset_description,
# 	replace = FALSE
# )

dataset <- get_dataset(datastore, study$name, dataset_name, include_versions = TRUE)
dataset <- dataset[1, , drop = FALSE]

cat("Dataset found. Using version ID:", dataset$version_id[[1]], "\n")
cat("Dataset name:", dataset$name[[1]], "\n")
if ("description" %in% names(dataset) && !is.na(dataset$description[[1]])) {
	cat("Dataset description:", dataset$description[[1]], "\n")
}

cat("Ensuring Human Host entity instances are linked to Participant_ID values in dataset.\n")
ensure_human_host_participants(datastore, domain, study, dataset)

cat("Ingest complete.\n")
cat("Dataset Asset ID:", dataset$asset_id[[1]], "\n")
cat("Dataset Version ID:", dataset$version_id[[1]], "\n")
