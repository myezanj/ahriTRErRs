library(ahriTRErRs)

if (!nzchar(Sys.getenv("ORCID_CLIENT_ID", "")) || !nzchar(Sys.getenv("ORCID_CLIENT_SECRET", ""))) {
    stop("Set ORCID_CLIENT_ID and ORCID_CLIENT_SECRET before running this example.")
}

if (nzchar(Sys.getenv("JUPYTERHUB_USER", "")) &&
    !nzchar(Sys.getenv("AHRI_TRE_JUPYTERHUB_HOST", "")) &&
    nzchar(Sys.getenv("TRE_SERVER", ""))) {
    Sys.setenv(AHRI_TRE_JUPYTERHUB_HOST = paste0("https://", Sys.getenv("TRE_SERVER")))
}

# For remote notebook environments with blocked local listeners, set:
# ORCID_DISABLE_CALLBACK_LISTENER=true and provide ORCID_AUTHORIZATION_RESPONSE_URL.
token_info <- do.call(get_orcid_token, cached_oauth_options_from_env())
cat(token_info$id_token, "\n")