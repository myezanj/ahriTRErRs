# AHRI TRE local runtime package

Package: `ahri-tre`

Version: `0.8.3`

Target: `x86_64-unknown-linux-gnu`

## Layout

- `bin/ahri-tre`: public command-line interface
- `bin/ahri-tred`: local daemon used by the CLI and language wrappers
- `lib/`: bundled redistributable runtime libraries, including DuckDB and the stable C ABI library
- `include/`: stable C ABI public header
- `share/ahri-tre/manifest.json`: machine-readable package contract
- `share/ahri-tre/installer.json`: installer contract for prefix-based installs
- `share/ahri-tre/profile.env.example`: non-secret datastore identity profile template
- `share/ahri-tre/secrets.env.example`: placeholder-only optional secret template
- `install.sh`: prefix installer that copies package content and writes launchers

## Installation

Install under a local prefix with `AHRI_TRE_PREFIX=/opt/ahri-tre ./install.sh` or pass the prefix as the first argument. The installer copies `bin/`, `lib/`, `include/`, and `share/ahri-tre/` content, preserves executable bits for staged commands, keeps wrapper discovery at `bin/ahri-tred`, and writes command launchers that set the platform library path to the installed `lib/` directory before executing the packaged runtime binaries. Add `$AHRI_TRE_PREFIX/bin` to `PATH` after installation.

The package does not create PostgreSQL infrastructure, lake storage, Docker resources, or local datastore services. For ordinary identity-bound opens, copy the example profile from `share/ahri-tre/` and set the datastore name handed off by your operator; the datastore binding resolves DuckLake catalog, lake path, encryption policy, and managed catalog credential details.

## Smoke Checks

Run these from the installed package:

```sh
ahri-tre version
ahri-tre doctor --format json
ahri-tre schema list --format json
ahri-tred --help
```

Language wrappers should locate the C ABI library in `lib/`, the public header in `include/`, and the daemon sibling at `bin/ahri-tred`.
