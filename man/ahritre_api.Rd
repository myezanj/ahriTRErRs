\name{ahriTRErRs-api}
\alias{AhriTreClient}
\alias{RuntimeConfig}
\alias{arrow_ipc_to_table}
\alias{check_protocol_compatibility}
\alias{discover_runtime_artifact}
\alias{execute_json}
\alias{payload_smoke_summary}
\alias{protocol_failure_summary}
\alias{redact_diagnostics}
\alias{run_contract_smoke}
\alias{runtime_discover_daemon_binary}
\alias{runtime_ensure}
\alias{runtime_status}
\alias{runtime_stop}
\alias{smoke_failure_request}
\alias{smoke_success_request}
\title{AHRI TRE High-Level R Binding API}
\description{
Core helpers for runtime discovery, compatibility checks, runtime lifecycle,
protocol execution, payload conversion, and smoke diagnostics.
}
\section{Runtime and Compatibility}{
\describe{
  \item{\code{discover_runtime_artifact(root = NULL)}}{Discovers and validates
  the runtime artifact from \code{root} or \code{AHRI_TRE_RUNTIME_ROOT}.}
  \item{\code{RuntimeConfig(...)}}{Builds runtime lifecycle options.}
  \item{\code{check_protocol_compatibility(api = CApi())}}{Checks that runtime
  protocol support overlaps with binding support.}
  \item{\code{runtime_status(...)}}{Reads runtime status through the C ABI.}
  \item{\code{runtime_discover_daemon_binary(...)}}{Discovers daemon binary via
  lifecycle API.}
  \item{\code{runtime_ensure(...)}}{Ensures runtime readiness.}
  \item{\code{runtime_stop(...)}}{Stops the managed runtime.}
}
}
\section{Protocol Client and Results}{
\describe{
  \item{\code{AhriTreClient(...)}}{Creates a protocol client from an ABI API handle.}
  \item{\code{execute_json(client, request)}}{Executes a protocol JSON request
  and returns an envelope plus payloads.}
  \item{\code{protocol_failure_summary(envelope)}}{Normalizes protocol failures
  into \code{status/code/message}.}
  \item{\code{arrow_ipc_to_table(payload)}}{Converts Arrow IPC payload bytes to
  an Arrow Table (requires package \code{arrow}).}
}
}
\section{Contract Smoke Utilities}{
\describe{
  \item{\code{run_contract_smoke(...)}}{Runs end-to-end binding smoke checks and
  returns a redacted report.}
  \item{\code{smoke_success_request()}}{Builds a known-good smoke request.}
  \item{\code{smoke_failure_request()}}{Builds a known-failure smoke request.}
  \item{\code{payload_smoke_summary(result)}}{Summarizes payload metadata from
  a smoke response.}
  \item{\code{redact_diagnostics(value)}}{Redacts sensitive diagnostics fields
  from nested values.}
}
}
\value{
Each function returns a typed list/object or scalar relevant to its API role;
see sections above for intended usage patterns.
}
\note{
See the repository README for setup and development workflow details.
}
\keyword{package}