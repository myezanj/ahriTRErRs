\name{read_dataset}
\alias{read_dataset}
\title{Read Dataset Rows With Optional Version Preference}
\usage{
read_dataset(
  ds,
  study_name,
  dataset_name,
  include_versions = FALSE,
  version = NULL
)
}
\arguments{
  \item{ds}{DataStore object.}
  \item{study_name}{Character study name.}
  \item{dataset_name}{Character dataset asset name.}
  \item{include_versions}{Logical; if \code{TRUE} search across all dataset versions.}
  \item{version}{Optional dataset version label (for example \code{"1.2.3"} or \code{"v1_2_3"}). If omitted, the latest version is returned. If provided but not available, the latest available version is returned.}
}
\value{
A \code{data.frame} containing dataset rows.
}
\description{
Retrieves dataset rows using AHRI TRE wrappers. If a requested version cannot be
resolved, the function falls back to the latest available dataset read.
}
