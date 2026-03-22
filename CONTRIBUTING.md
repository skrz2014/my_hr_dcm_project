# Contributing Guide

## Branch Strategy

```
main          ← production-ready, protected
  └── develop ← integration branch
        └── feature/your-change ← your work
```

## Making Changes

1. **Never edit definition files directly on `main`**
2. Create a feature branch: `git checkout -b feature/add-reviews-table`
3. Edit files in `sources/definitions/`
4. Push and open a **Merge Request** — CI auto-runs `PLAN` on all 3 environments
5. Review the plan output posted as MR comment
6. Merge → CI deploys STAGE → manual approval → deploys PROD

## Change Cycle (Day-2 Operations)

```
Edit definition file(s)
       ↓
PLAN  →  review CREATE / ALTER / DROP
       ↓
DEPLOY with a descriptive alias
       ↓
REFRESH ALL  (if dynamic table bodies changed)
       ↓
TEST ALL  (validate all 11 data quality expectations)
```

## Safety Rules

- **Never remove a DEFINE/GRANT/ATTACH without checking the PLAN output first** — removal = DROP on next deploy
- All object names must be **fully qualified** (`database.schema.object`)
- Add `DATA_METRIC_SCHEDULE` to any new table that will have DMFs attached
- New tasks deploy **SUSPENDED** — always resume manually after deployment

## File Ownership

| File | Owner |
|------|-------|
| `manifest.yml` | Platform / DevOps team |
| `01_infrastructure.sql` | Platform / DevOps team |
| `02_tables.sql` – `04_views.sql` | Data Engineering team |
| `05_functions.sql` | Data Engineering team |
| `06_tasks.sql` | Data Engineering / Ops team |
| `07_grants.sql` | Security / Platform team |
| `08_data_quality.sql` | Data Quality / Engineering team |
| `09_security.sql` | Security team |
