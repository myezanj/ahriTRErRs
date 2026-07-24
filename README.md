# ahriTRErRs

Seed repository for the future AHRI TRE R binding.

## Installation

Install from GitHub:

```r
remotes::install_github("myezanj/ahriTRErRs")
```

This package is intentionally small. It demonstrates how an R package should
consume a prebuilt AHRI TRE runtime artifact, load the stable C ABI library,
check protocol compatibility, manage the local runtime through ABI lifecycle
helpers, execute generic JSON protocol requests, and convert Arrow IPC payloads
at the R edge.

Ordinary installation must consume released AHRI TRE runtime artifacts. It must
not require this Rust workspace, Cargo, Rust, Zig, PostgreSQL development
headers, or a local `target/` directory.

## Runtime Artifact Delivery

Runtime artifacts are distributed through GitHub Releases in
`myezanj/ahri-tre-rs` as architecture-specific archives. This repository does
not bundle runtime binaries inside the R package.

Ordinary users should install a matching runtime archive for their platform,
unpack it, and set `AHRI_TRE_RUNTIME_ROOT` to that directory before using
runtime-backed operations.

For repository development, the devcontainer installer already automates this
release download and verification flow using `.devcontainer/install_ahri_tre_runtime.sh`.

### Runtime Helper For Scripts

For package examples and external scripts, prefer the package helper
`runtime_ensure_root()` instead of duplicating local runtime-manifest checks.

```r
runtime_root <- runtime_ensure_root(candidates = c(
  "/workspaces/ahriTRErRs/.runtime/ahri-tre-runtime",
  "/opt/ahri-tre-runtime"
))
```

Behavior:

- Uses explicit `root` when provided.
- Falls back to `AHRI_TRE_RUNTIME_ROOT` when valid.
- Searches fallback candidate paths for `share/ahri-tre/manifest.json`.
- Sets `AHRI_TRE_RUNTIME_ROOT` to the resolved path.
- Raises `ahri_tre_artifact_error` if no valid runtime root is found.

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

- `AHRI_TRE_LAKE_CONTAINER_PATH=/workspaces/ahriTRErRs/.lake`
- `TRE_LAKE_PATH=/workspaces/ahriTRErRs/.lake`

The devcontainer reads defaults from `.devcontainer/.env`.
Edit that file directly when you need local overrides; `.devcontainer/.env` is
ignored and should not be committed.

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

### Test Lake Mount (Devcontainer)

For TRE integration tests that require NAS lake data, use the repository
mount workflow and validate content after mount:

```bash
sudo /workspaces/ahriTRErRs/scripts/mount_test_lake.sh
/workspaces/ahriTRErRs/scripts/validate_test_lake_content.sh /mnt/test_lake/pilot_tre
```

If `/mnt/test_lake/pilot_tre` is already mounted as non-CIFS and content
validation fails, use controlled overmount:

```bash
ALLOW_OVERMOUNT_CIFS=1 sudo -E /workspaces/ahriTRErRs/scripts/mount_test_lake.sh
```

From VS Code, you can run the same workflow with:

- `Tasks: Run Task` -> `TRE: Mount + Validate Test Lake`
- `Tasks: Run Task` -> `TRE: Validate Test Lake Content`

Expected required paths include:

- `study_019e39f6_24e3_74fa_88e1_41e6c62fe539`
- `study_019ebd22_a12b_727c_9e64_dad1c3b5af89`
- `__tre_duckdb_stage`
- `study_019e3fde_a71e_7ee3_9f0d_180879bfb42e`
- `study_019e3fe4_eabf_7ebf_a931_972ffa8d38a3`

On Windows PowerShell, prefer `R.exe` when running locally because `R` may
resolve to an alias in some shells:

```powershell
R.exe -q -e "devtools::test()"
```

Run full package checks before publishing changes:

```r
devtools::check(document = FALSE, error_on = "warning")
```

## Wrapper Return Values

All generated command wrappers return an `ahri_tre_wrapper_result` object.

Key fields:

- `data`: parsed R object for the command response payload.
- `object`: alias of `data` for explicit object-oriented access.
- `data_frame`: best-effort tabular projection when payload content is
  tabular (`rows`, `items`, `datasets`, `studies`, etc.).
- `envelope`: original protocol envelope.
- `payloads`: attached binary payload descriptors (for example Arrow IPC).

Example:

```r
result <- dataset_list(client, format = "json")

# Native R object
result$object

# Tabular access when available
if (!is.null(result$data_frame)) {
  print(utils::head(result$data_frame))
}
```

## Release Hygiene

- Record user-visible changes in `NEWS.md`.
- Keep generated wrappers in sync with schema updates by running
  `tools/generate_wrappers.ps1`.
- Ensure `devtools::test()` and `devtools::check()` pass before release.

See also:

- `CONTRIBUTING.md` for contribution workflow.
- `CODE_OF_CONDUCT.md` for collaboration standards.

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
AHRI_TRE_RUNTIME_ROOT=/workspaces/ahriTRErRs/dist/ahri-tre-dev \
  R -q -e 'jsonlite::write_json(ahriTRErRs::run_contract_smoke(), stdout(), auto_unbox = TRUE, pretty = TRUE)'
```

The smoke path loads the packaged C ABI, checks ABI/library/protocol
compatibility, observes/discovers/ensures/stops the managed runtime, sends
generic protocol JSON through `ahri_tre_client_execute_protocol_json`, verifies
protocol failure envelope parsing, and reports Arrow IPC payload descriptors
when returned. Its diagnostics redact request bodies, credentials, host paths,
lake internals, and runtime storage paths.

The placeholder tests exercise compatibility helpers, protocol failure parsing,
and Arrow IPC conversion boundaries without requiring a staged runtime.
