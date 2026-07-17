# AHRI TRE R Binding Handoff

This is a seed for the future external `ahriTREr_rs` repository created from
ADR-0005 and the shared binding-repository seed contract:

- `docs/book/src/binding-repository-seed-contract.md`
- `docs/issues/separate-language-binding-repositories/PRD.md`
- `docs/issues/separate-language-binding-repositories/issues/04-create-r-seed-repository-workspace.md`

The ordinary R package installation path must consume a prebuilt AHRI TRE
runtime artifact. It must not build the Rust workspace, depend on Cargo, or
assume repository-relative `target/` paths. Development may set
`AHRI_TRE_RUNTIME_ROOT` to a staged runtime package for wrapper work.

## Contract Smoke

Run the shared contract smoke path against a staged or released runtime
artifact with:

```bash
AHRI_TRE_RUNTIME_ROOT=/workspaces/ahriTREr_rs/dist/ahri-tre-dev \
  R -q -e 'jsonlite::write_json(ahritre::run_contract_smoke(), stdout(), auto_unbox = TRUE, pretty = TRUE)'
```

The smoke path loads the packaged C ABI, checks protocol compatibility,
observes/discovers/ensures/stops the managed runtime, sends generic public
protocol JSON, verifies protocol failure envelope parsing, and reports Arrow
IPC payload descriptors when returned. Diagnostics redact request bodies,
credentials, host paths, lake internals, and runtime storage paths.

## Ownership

The R repository owns:

- package metadata, dependency locks, CI, CRAN/r-universe publication work
- the R `.Call` bridge over the stable C ABI
- R conditions and diagnostics
- JSON request helpers over the public protocol
- Arrow, tibble, and `data.frame` conversion conveniences

The Rust workspace owns:

- stable C ABI functions and generated C header
- runtime package manifests and artifact layout
- managed local runtime lifecycle behavior
- workflow, governance, datastore, provenance, and lake semantics
- the public JSON protocol and data-plane payload contracts

Arrow R objects, tibbles, and `data.frame` values are binding-local
conveniences over Arrow IPC and Parquet contracts. New workflow semantics should
land in the Rust app and protocol layers before this package exposes
R-specific helpers.

## Development Container

The devcontainer runs R with a sibling PostgreSQL service. It exports
`AHRI_TRE_LAKE_CONTAINER_PATH=/workspaces/ahriTREr_rs/.lake` and maps
`TRE_LAKE_PATH` to the same container-visible location. Keep host-only paths out
of runtime code and diagnostics.

The devcontainer reads defaults from `.devcontainer/.env`. Developers should
edit that file for local overrides; `.devcontainer/.env` is ignored and must
remain uncommitted.

The container image installs the `v0.8.3` AHRI TRE runtime release from
`AHRIORG/ahri-tre-rs`, selecting the Linux artifact that matches `uname -m`, and
exports `AHRI_TRE_RUNTIME_ROOT=/opt/ahri-tre-runtime`. If the release is
private, the devcontainer build requires `GITHUB_TOKEN` in the build
environment. Set `AHRI_TRE_RELEASE_REPOSITORY` in `.devcontainer/.env` if
runtime artifacts are hosted in a different GitHub repository.

For offline/private development where release access is unavailable, stage a
runtime archive under `.devcontainer/runtime/`. The installer attempts local
archive install before GitHub release download and will verify checksums when
an adjacent `.sha256` or `.sha256sum` file is present.

## Next Steps

- Keep CI contract smoke coverage in sync with runtime release updates and
  environment requirements.
- Keep bridge/header alignment checks green as C ABI symbols evolve.
- Add higher-level R helpers only after the corresponding public protocol
  operation exists in the Rust workspace.
- Keep end-user runtime installation guidance aligned with release artifact
  naming, target triples, and checksum conventions.
