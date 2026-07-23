#!/usr/bin/env Rscript
#
# Fetch REDCap project titles using the API.
# Requires REDCAP_API_URL and REDCAP_API_TOKEN environment variables.
#
# Environment variables:
#   REDCAP_API_URL    - REDCap API endpoint (default: https://population.ahri.org/api/)
#   REDCAP_API_TOKEN  - API token (required)

# Install dependencies if not present.
if (!requireNamespace("httr", quietly = TRUE)) {
  install.packages("httr", repos = "https://cloud.r-project.org")
}
if (!requireNamespace("jsonlite", quietly = TRUE)) {
  install.packages("jsonlite", repos = "https://cloud.r-project.org")
}

suppressPackageStartupMessages(library(httr))
suppressPackageStartupMessages(library(jsonlite))

# Environment config
redcap_url <- Sys.getenv("REDCAP_API_URL", unset = "https://population.ahri.org/api/")
api_token <- Sys.getenv("REDCAP_API_TOKEN", unset = "")

if (!nzchar(api_token)) {
  cat("[INFO] REDCAP_API_TOKEN is not set. Skipping example.\n")
  quit(save = "no", status = 0L)
}

# API call
response <- httr::POST(
  url = redcap_url,
  body = list(
    token = api_token,
    content = "project",
    format = "json"
  ),
  encode = "form"
)

# Check response
if (httr::status_code(response) != 200) {
  stop("REDCap API request failed: ", httr::content(response, "text", encoding = "UTF-8"))
}

# Parse and display
project_info <- jsonlite::fromJSON(httr::content(response, "text", encoding = "UTF-8"))
if (is.data.frame(project_info)) {
  keep <- intersect(c("project_id", "project_title"), names(project_info))
  if (length(keep) > 0) {
    print(project_info[, keep, drop = FALSE])
  } else {
    print(project_info)
  }
} else {
  print(project_info)
}