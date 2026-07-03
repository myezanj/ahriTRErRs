# ahri-tre-r

Seed repository for the future AHRI TRE R binding.

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

`AHRI_TRE_LAKE_CONTAINER_PATH` is the container-visible lake storage location
for local development. Runtime code should continue to use `TRE_LAKE_PATH`.

Run tests in the devcontainer with:

```bash
R -q -e 'devtools::test()'
```

Run the shared binding-contract smoke path against a staged package with:

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
