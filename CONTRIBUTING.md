# Contributing

Thanks for contributing to ahriTRErRs.

## Development Setup

1. Clone the repository.
2. Install R dependencies:

```r
install.packages(c("devtools", "testthat", "jsonlite"), repos = "https://cloud.r-project.org")
```

3. Run tests:

```r
devtools::test()
```

4. Run package checks before opening a PR:

```r
devtools::check(document = FALSE, error_on = "warning")
```

## Generated Files

Wrapper files are generated from schema metadata. If command metadata changes, regenerate wrappers before committing:

```powershell
& "tools/generate_wrappers.ps1"
```

If command docs/schema artifacts change, regenerate docs too:

```powershell
& "tools/generate_tre_docs.ps1"
```

## Pull Requests

- Keep PRs focused and small.
- Add tests when behavior changes.
- Update `NEWS.md` for user-visible changes.
- Ensure CI passes.
