# ahri-tre-r

Seed repository for the future AHRI TRE R binding.

## Installation

Install from GitHub:

```r
remotes::install_github("AHRIORG/ahri-tre-r")
```

This package is intentionally small. It demonstrates how an R package should
consume a prebuilt AHRI TRE runtime artifact, load the stable C ABI library,
check protocol compatibility, manage the local runtime through ABI lifecycle
helpers, execute generic JSON protocol requests, and convert Arrow IPC payloads
at the R edge.

Ordinary installation must consume released AHRI TRE runtime artifacts. It must
not require this Rust workspace, Cargo, Rust, Zig, PostgreSQL development
headers, or a local `target/` directory.

## Development

For local wrapper work, set `AHRI_TRE_RUNTIME_ROOT` to an unpacked runtime
artifact with this layout:

```text
bin/ahri-tred
include/ahri_tre_ffi_c.h
lib/libahri_tre_ffi_c.so
share/ahri-tre/manifest.json
```

The devcontainer exports:

- `AHRI_TRE_LAKE_CONTAINER_PATH=/workspaces/ahri-tre-r/.lake`
- `TRE_LAKE_PATH=/workspaces/ahri-tre-r/.lake`

The devcontainer reads committed defaults from `.devcontainer/.env.example`.
Copy it to `.devcontainer/.env` only when you need local overrides; the live
`.env` file is ignored and should not be committed.

It also installs the AHRI TRE `v0.8.3` runtime release for the container
architecture and exports `AHRI_TRE_RUNTIME_ROOT=/opt/ahri-tre-runtime`. Set
`AHRI_TRE_RELEASE_TAG` at build time if you need to test another runtime
release. Set `AHRI_TRE_RELEASE_REPOSITORY` if runtime artifacts are published in
a different GitHub repository. If the runtime release is private, set
`GITHUB_TOKEN` in the shell that rebuilds the devcontainer so Docker can
download the release assets.

If release access is unavailable, stage a runtime archive under
`.devcontainer/runtime/` and rebuild. The installer auto-detects archives named
like `ahri-tre-<version>-<target>.tar.gz` for the container architecture and
uses an adjacent `.sha256` or `.sha256sum` file when present. You can override
discovery with `AHRI_TRE_RUNTIME_LOCAL_ARCHIVE` and
`AHRI_TRE_RUNTIME_LOCAL_CHECKSUM` in `.devcontainer/.env`.

`AHRI_TRE_LAKE_CONTAINER_PATH` is the container-visible lake storage location
for local development. Runtime code should continue to use `TRE_LAKE_PATH`.

Run tests in the devcontainer with:

```bash
R -q -e 'devtools::test()'
```

On Windows PowerShell, prefer `R.exe` when running locally because `R` may
resolve to an alias in some shells:

```powershell
R.exe -q -e "devtools::test()"
```

Run full package checks before publishing changes:

```r
devtools::check(document = FALSE, error_on = "warning")
```

## Release Hygiene

- Record user-visible changes in `NEWS.md`.
- Keep generated wrappers in sync with schema updates by running
  `tools/generate_wrappers.ps1`.
- Ensure `devtools::test()` and `devtools::check()` pass before release.

## Project Organization

The package is organized by responsibility:

- `R/artifact.R`, `R/ffi.R`, `R/runtime.R`, `R/protocol.R`, `R/payloads.R`, `R/errors.R`:
  runtime artifact discovery, ABI bridge calls, lifecycle, protocol transport,
  payload conversion, and error handling.
- `R/core.R`:
  shared request envelope helpers for command wrappers.
- `R/*.R` domain modules (`assets.R`, `auth_session.R`, `datastore.R`,
  `entities.R`, `local.R`, `study.R`):
  generated command wrappers split by domain (`assets`, `auth_session`,
  `datastore`, `entities`, `local`, `study`).
- `tests/testthat/`:
  contract and wrapper behavior tests.
- `tools/`:
  regeneration scripts for wrapper/docs artifacts.

Regenerate command wrappers after schema updates:

```powershell
& "tools/generate_wrappers.ps1"
```

Regenerate TRE command reference and schema-derived docs:

```powershell
& "tools/generate_tre_docs.ps1"
```

Run the shared binding_contract smoke path against a staged package with:

```bash
AHRI_TRE_RUNTIME_ROOT=/workspaces/ahri-tre-r/dist/ahri-tre-dev \
  R -q -e 'jsonlite::write_json(ahritre::run_contract_smoke(), stdout(), auto_unbox = TRUE, pretty = TRUE)'
```

The smoke path loads the packaged C ABI, checks ABI/library/protocol
compatibility, observes/discovers/ensures/stops the managed runtime, sends
generic protocol JSON through `ahri_tre_client_execute_protocol_json`, verifies
protocol failure envelope parsing, and reports Arrow IPC payload descriptors
when returned. Its diagnostics redact request bodies, credentials, host paths,
lake internals, and runtime storage paths.

The placeholder tests exercise compatibility helpers, protocol failure parsing,
and Arrow IPC conversion boundaries without requiring a staged runtime.
