# RFAM Row-Read Backend Handoff (2026-07-20)

## Scope
- Study: Rfam_Database_Collection
- Datastore: pilot_tre on svrlducklakedev01.ahri.org
- Lake path: /mnt/test_lake/pilot_tre
- Lake catalog: pilot_tre_catalog

## Current Result
- Strict validation fails as expected because no dataset rows are readable.
- Relaxed diagnostics complete and report zero readable rows across all RFAM datasets.

## Confirmed Runtime State
- Live session is active.
- Session lake path is writable from the container runtime user.
- Row access still fails at backend table resolution.

## Reproduction Commands
1. Strict fail-fast validation
AHRI_TRE_TARGET_STUDY=Rfam_Database_Collection Rscript inst/examples/validate_row_read_strict.r

2. Full relaxed diagnostics
AHRI_TRE_TARGET_STUDY=Rfam_Database_Collection AHRI_TRE_ROW_PREFLIGHT_FAIL_FAST=false AHRI_TRE_ENFORCE_ROW_READ=false Rscript inst/examples/read_rfam.r

3. Latest relaxed run log used for evidence
/tmp/read_rfam_relaxed_after_cleanup.log

## Failure Signatures
- dataset_data returns request envelope is invalid.
- dataset_preview returns DuckDB catalog errors for missing tables.

Observed missing tables:
- clan_1_0_0
- clan_membership_1_0_0
- family_1_0_0
- full_region_1_0_0
- rfamseq_part_00001_1_0_0
- rfamseq_part_00002_1_0_0
- rfamseq_part_00003_1_0_0
- rfamseq_part_00004_1_0_0
- taxonomy_1_0_0

Affected datasets:
- clan
- clan_membership
- family
- full_region
- rfamseq_part_00001
- rfamseq_part_00002
- rfamseq_part_00003
- rfamseq_part_00004
- taxonomy

## Additional Validation Performed
- A temporary isolated test study in Test domain successfully ingested and previewed rows.
- That confirms client/runtime row-read mechanics are functioning.
- Remaining blocker is RFAM backend table availability/materialization in the target study.

## Backend Actions Requested
1. Re-materialize or restore RFAM dataset lake tables listed above for study Rfam_Database_Collection.
2. Confirm pilot_tre_catalog has resolvable objects for those dataset versions.
3. Re-run strict validation command after remediation.
