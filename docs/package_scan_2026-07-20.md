# Package Scan Report (2026-07-20)

## Scope
- Package: ahriTRErRs
- Workspace: /workspaces/ahriTRErRs
- R version: 4.4.2

## Commands Run
1. Static diagnostics (workspace errors)
2. `testthat::test_local(".", stop_on_failure = FALSE)`
3. `rcmdcheck::rcmdcheck(args = c("--no-manual"), error_on = "never")`

## Results

### Static Diagnostics
- No errors found.

### Test Suite
- PASS: 590
- FAIL: 0
- WARN: 0
- SKIP: 1

Skipped test detail:
- `tests/testthat/test_ffi_bridge_header_alignment.R`: bridge source file is not available.

### R CMD Check (No Manual)
- Errors: 0
- Warnings: 0
- Notes: 0

## Conclusion
- Package quality gates are clean in this environment.
- Residual runtime/backend data availability issues can still affect live row reads for specific studies (for example RFAM), but these are not package structure or check failures.

