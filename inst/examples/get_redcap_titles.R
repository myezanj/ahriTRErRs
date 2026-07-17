# Install if needed
# install.packages("httr")
# install.packages("jsonlite")

library(httr)
library(jsonlite)

# --- CONFIG ---
# Use environment variables instead of hardcoding credentials.
# Example:
#   export REDCAP_API_URL="https://population.ahri.org/api/"
#   export REDCAP_API_TOKEN="<your_token>"
redcap_url <- Sys.getenv("REDCAP_API_URL", unset = "https://population.ahri.org/api/")
api_token <- Sys.getenv("REDCAP_API_TOKEN", unset = "")

if (!nzchar(api_token)) {
  stop("Missing REDCAP_API_TOKEN environment variable.")
}

# --- API CALL ---
response <- httr::POST(
  url = redcap_url,
  body = list(
    token = api_token,
    content = "project",
    format = "json"
  ),
  encode = "form"
)

# --- CHECK RESPONSE ---
if (httr::status_code(response) != 200) {
  stop("REDCap API request failed: ", httr::content(response, "text", encoding = "UTF-8"))
}

# --- PARSE RESULT ---
project_info <- jsonlite::fromJSON(httr::content(response, "text", encoding = "UTF-8"))

# --- VIEW ---
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
