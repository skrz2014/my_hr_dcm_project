# ❄️ Snowflake DCM Projects — HR Analytics Platform

> **Infrastructure as Code for Snowflake | Complete End-to-End Implementation**

[![Snowflake](https://img.shields.io/badge/Snowflake-DCM%20Projects-29B5E8?style=flat&logo=snowflake&logoColor=white)](https://docs.snowflake.com)
[![Medium](https://img.shields.io/badge/Medium-@snowflakechronicles-000000?style=flat&logo=medium&logoColor=white)](https://medium.com/@snowflakechronicles)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Status](https://img.shields.io/badge/Status-Preview%20Feature-orange)](https://docs.snowflake.com)

**Author:** Satish Kumar
**Account:** PQC86579 | **User:** SATISH
**Published on:** [Medium @snowflakechronicles](https://medium.com/@snowflakechronicles)

---

## 📋 Table of Contents

- [Project Overview](#-project-overview)
- [Architecture](#-architecture)
- [Repository Structure](#-repository-structure)
- [Quick Start](#-quick-start)
- [manifest.yml](#-manifestyml)
- [Definition Files](#-definition-files)
- [CI/CD Pipeline](#-cicd-pipeline)
- [Environments](#-environments)
- [Supported Object Types](#-supported-object-types)
- [Key Rules](#-key-rules)
- [Contributing](#-contributing)

---

## 🎯 Project Overview

This repository contains a **complete Snowflake DCM Projects implementation** for an HR Analytics platform — demonstrating all 14 supported object types deployed across DEV, STAGE, and PROD using a single set of Jinja-templated definition files.

| Property | Value |
|----------|-------|
| **Use Case** | HR Analytics Platform |
| **Architecture** | Medallion (Bronze → Silver → Gold) |
| **Environments** | DEV → STAGE → PROD |
| **Definition Files** | 9 |
| **Object Types** | 14 |
| **Data Quality Expectations** | 11 |
| **Test Suite** | 16 checks |
| **Jinja Template Variable** | `{{env}}` |

### What is Snowflake DCM Projects?

DCM Projects is Snowflake's **native Infrastructure as Code** engine:

| Feature | Description |
|---------|-------------|
| 📝 **Declarative** | `DEFINE` instead of `CREATE` — objects are state-declared |
| 🧩 **Templated** | Jinja2 variables resolve per environment at deploy time |
| 🔍 **Dry-run** | `PLAN` shows every CREATE / ALTER / DROP before it runs |
| ✅ **Testable** | `TEST ALL` runs named data quality expectations natively |
| 📜 **Auditable** | Full deployment history built into Snowflake |
| 🔗 **Zero deps** | No Terraform, no dbt, no external tooling required |

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                       MEDALLION ARCHITECTURE                            │
├──────────────────┬─────────────────────────┬───────────────────────────┤
│   🥉 BRONZE      │      🥈 SILVER          │        🥇 GOLD            │
│   RAW Schema     │    CLEANSED Schema      │    ANALYTICS Schema       │
├──────────────────┼─────────────────────────┼───────────────────────────┤
│ EMPLOYEES        │ EMPLOYEES_CLEAN  (DT)   │ DEPT_HEADCOUNT     (DT)  │
│ DEPARTMENTS      │ PAYROLL_CLEAN    (DT)   │ PAYROLL_SUMMARY    (DT)  │
│ PAYROLL          │                         │ VW_ACTIVE_EMPLOYEES       │
│ REVIEWS          │                         │ VW_SALARY_BANDS           │
│                  │                         │ VW_TOP_PERFORMERS  (Sec)  │
│                  │                         │ VW_PAYROLL_OVERVIEW(Sec)  │
└──────────────────┴─────────────────────────┴───────────────────────────┘
DT = Dynamic Table  |  Sec = Secure View
```

```
Multi-Environment Promotion Flow
─────────────────────────────────────────────────────────────
Feature Branch
      │
      ▼
  PLAN (DEV) ──► Review Changeset ──► DEPLOY (DEV)
                                            │  validate + test
                                            ▼
                                      PLAN (STAGE) ──► DEPLOY (STAGE)
                                                              │  validate + test
                                                              ▼
                                                       PLAN (PROD) ──► DEPLOY (PROD)
```

---

## 📁 Repository Structure

```
my_hr_dcm_project/
│
├── 📄 README.md                          ← This file
├── 📄 manifest.yml                       ← Targets, templating config & Jinja vars
├── 📄 DCM_end_to_end.sql                 ← Full Phase 1–5 orchestration script
├── 📄 .gitlab-ci.yml                     ← GitLab CI/CD pipeline
├── 📄 .gitignore
├── 📄 LICENSE
│
└── 📁 sources/
    └── 📁 definitions/
        ├── 📄 01_infrastructure.sql      ← Database, schemas, warehouse, roles
        ├── 📄 02_tables.sql              ← Bronze layer tables + internal stage
        ├── 📄 03_dynamic_tables.sql      ← Silver + Gold dynamic tables
        ├── 📄 04_views.sql               ← Views & secure views
        ├── 📄 05_functions.sql           ← SQL functions + user-defined DMFs
        ├── 📄 06_tasks.sql               ← Scheduled ingestion tasks
        ├── 📄 07_grants.sql              ← All GRANT statements
        ├── 📄 08_data_quality.sql        ← ATTACH system & user DMFs
        └── 📄 09_security.sql            ← Tags & authentication policies
```

---

## ⚡ Quick Start

### Prerequisites

```bash
# Snowflake CLI v3.16+
snow --version

# Verify connection
snow connection test --connection my_connection
```

### 1. Clone this repository

```bash
git clone https://gitlab.com/<your-namespace>/my_hr_dcm_project.git
cd my_hr_dcm_project
```

### 2. Run account preparation (ACCOUNTADMIN required)

```sql
-- Open DCM_end_to_end.sql and run Phase 1 as ACCOUNTADMIN
USE ROLE ACCOUNTADMIN;
-- Execute Phase 1 statements...
```

### 3. Create DCM Project objects

```sql
-- Phase 2: one project per environment
USE ROLE HR_DCM_DEV_DEPLOYER;
CREATE DCM PROJECT IF NOT EXISTS HR_DCM_ADMIN.PROJECTS.HR_PROJECT_DEV
  COMMENT = 'HR Analytics — Development';
```

### 4. Upload definition files to Snowflake Workspace

```
Snowsight → Projects → Workspaces → +Add New → DCM Project
Upload all files from sources/definitions/ and manifest.yml
```

### 5. Plan then Deploy

```sql
-- Always PLAN before DEPLOY
EXECUTE DCM PROJECT HR_DCM_ADMIN.PROJECTS.HR_PROJECT_DEV
  PLAN
  USING CONFIGURATION DEV
FROM 'snow://workspace/USER$.PUBLIC.DEFAULT$/versions/live/my_hr_dcm_project';

-- Deploy to DEV
EXECUTE DCM PROJECT HR_DCM_ADMIN.PROJECTS.HR_PROJECT_DEV
  DEPLOY AS 'initial hr dev deployment'
  USING CONFIGURATION DEV
FROM 'snow://workspace/USER$.PUBLIC.DEFAULT$/versions/live/my_hr_dcm_project';
```

---

## 📦 manifest.yml

```yaml
manifest_version: 2
type: DCM_PROJECT
default_target: DCM_DEV

targets:
  DCM_DEV:
    account_identifier: PQC86579
    project_name:       HR_DCM_ADMIN.PROJECTS.HR_PROJECT_DEV
    project_owner:      HR_DCM_DEV_DEPLOYER
    templating_config:  DEV

  DCM_STG:
    account_identifier: PQC86579
    project_name:       HR_DCM_ADMIN.PROJECTS.HR_PROJECT_STG
    project_owner:      HR_DCM_STG_DEPLOYER
    templating_config:  STAGE

  DCM_PROD:
    account_identifier: PQC86579
    project_name:       HR_DCM_ADMIN.PROJECTS.HR_PROJECT_PROD
    project_owner:      HR_DCM_PROD_DEPLOYER
    templating_config:  PROD

templating:
  defaults:
    env:                 "DEV"
    wh_size:             "SMALL"
    auto_suspend:        300
    data_retention_days: 7

  configurations:
    DEV:
      env:                 "DEV"
      wh_size:             "X-SMALL"
      auto_suspend:        60
      data_retention_days: 1

    STAGE:
      env:                 "STG"
      wh_size:             "SMALL"
      auto_suspend:        300
      data_retention_days: 7

    PROD:
      env:                 "PROD"
      wh_size:             "LARGE"
      auto_suspend:        600
      data_retention_days: 90
```

---

## 📄 Definition Files

| File | Objects Defined | Count |
|------|----------------|-------|
| `01_infrastructure.sql` | Database, 4 Schemas, Warehouse, 3 Roles, 2 DB Roles | 11 |
| `02_tables.sql` | 4 Bronze Tables, Internal Stage | 5 |
| `03_dynamic_tables.sql` | 2 Silver DTs, 2 Gold DTs | 4 |
| `04_views.sql` | 2 Views, 2 Secure Views | 4 |
| `05_functions.sql` | 3 SQL Functions, 3 UDMFs | 6 |
| `06_tasks.sql` | 3 Scheduled Tasks | 3 |
| `07_grants.sql` | Full RBAC grant set | 30+ |
| `08_data_quality.sql` | 11 DMF Expectations | 11 |
| `09_security.sql` | 3 Tags, 2 Auth Policies | 5 |

---

## 🔄 CI/CD Pipeline

The `.gitlab-ci.yml` implements a gate-based promotion model:

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────────┐
│   MR Opened     │    │  Merge to main   │    │   Manual Trigger    │
├─────────────────┤    ├──────────────────┤    ├─────────────────────┤
│ plan:dev        │    │ deploy:stage     │    │ deploy:prod         │
│ plan:stage      │    │ test:stage       │    │ (approval required) │
│ plan:prod       │    │ deploy:prod      │    │                     │
│ post MR comment │    │ test:prod        │    │                     │
└─────────────────┘    └──────────────────┘    └─────────────────────┘
```

### Required GitLab CI/CD Variables

| Variable | Scope | Description |
|----------|-------|-------------|
| `SNOWFLAKE_ACCOUNT` | All | Snowflake account identifier |
| `SNOWFLAKE_USER` | All | Service account username |
| `SNOWFLAKE_PASSWORD` | All | Service account password (masked) |
| `SNOWFLAKE_ROLE_DEV` | DEV | `HR_DCM_DEV_DEPLOYER` |
| `SNOWFLAKE_ROLE_STG` | STAGE | `HR_DCM_STG_DEPLOYER` |
| `SNOWFLAKE_ROLE_PROD` | PROD | `HR_DCM_PROD_DEPLOYER` |
| `DCM_PROJECT_PATH` | All | Workspace path to DCM project |

---

## 🌍 Environments

| Config | Database | Warehouse | Size | Auto Suspend | Retention |
|--------|----------|-----------|------|-------------|-----------|
| **DEV** | `HR_ANALYTICS_DEV` | `HR_ANALYTICS_WH_DEV` | X-SMALL | 60s | 1 day |
| **STAGE** | `HR_ANALYTICS_STG` | `HR_ANALYTICS_WH_STG` | SMALL | 300s | 7 days |
| **PROD** | `HR_ANALYTICS_PROD` | `HR_ANALYTICS_WH_PROD` | LARGE | 600s | 90 days |

---

## 📊 Supported Object Types

| Object Type | DEFINE | GRANT | ATTACH | Key Constraints |
|-------------|:------:|:-----:|:------:|-----------------|
| Database | ✅ | ✅ | — | Rename not supported |
| Schema | ✅ | ✅ | — | Rename not supported |
| Table | ✅ | ✅ | — | No rename / column reorder |
| Dynamic Table | ✅ | ✅ | — | Body change = full refresh |
| View / Secure View | ✅ | ✅ | — | No rename / column reorder |
| Internal Stage | ✅ | ✅ | — | Encryption immutable |
| Warehouse | ✅ | ✅ | — | `INITIALLY_SUSPENDED` immutable |
| Role / DB Role | ✅ | ✅ | — | No Application Role |
| Grant | — | ✅ | — | No APP ROLE / CALLER grants |
| Data Metric Function | ✅ | — | ✅ | Must have `EXPECTATION` for `TEST ALL` |
| Task | ✅ | ✅ | — | Always starts **SUSPENDED** |
| SQL Function | ✅ | — | — | `CREATE OR ALTER` limits apply |
| Tag | ✅ | — | — | No `PROPAGATE`, no column attach in DCM |
| Authentication Policy | ✅ | — | — | |

### ❌ Not Supported in DCM

```
Masking Policies  •  Row Access Policies  •  Column Tag Attachments
Streams  •  Pipes  •  Stored Procedures  •  External Stages
Network Policies  •  Alerts  •  Integrations
```

---

## 📌 Key Rules

1. **Order doesn't matter** — `DEFINE` order across all files is irrelevant. Snowflake resolves dependencies automatically.
2. **Removal = DROP** — Deleting a `DEFINE`, `GRANT`, or `ATTACH` drops that object on next deploy. Always review `PLAN` first.
3. **Fully qualified names** — Every object reference must include `database.schema.object`.
4. **Account-level grants required** — `GRANT CREATE DATABASE / WAREHOUSE / ROLE ON ACCOUNT` needed for DCM to deploy infrastructure.
5. **`DATA_METRIC_SCHEDULE` required** — Must be set on tables before attaching DMFs.
6. **External grants coexist** — Grants added outside DCM are never removed by DCM.
7. **Tasks always suspended** — Resume manually after every deploy: `ALTER TASK <n> RESUME`.
8. **DMFs need expectations** — `ATTACH` without `EXPECTATION` is silently skipped by `TEST ALL`.

---

## 🤝 Contributing

1. Fork this repository
2. Create a feature branch: `git checkout -b feature/add-new-table`
3. Make changes to definition files
4. Push and open a Merge Request
5. CI will automatically run `PLAN` and post the changeset as an MR comment
6. Review, approve, merge — CI deploys to STAGE then PROD

---

## 📖 Read the Full Article

Full end-to-end walkthrough published on Medium:

**[9 Files. 14 Object Types. 3 Environments. Infrastructure as Code — 100% Native to Snowflake](https://medium.com/@snowflakechronicles)**

👏 Clap on Medium | 🔔 Follow @snowflakechronicles | ⭐ Star this repo

---

## 📜 License

MIT License — see [LICENSE](LICENSE) for details.

---

*Satish Kumar | [Medium](https://medium.com/@snowflakechronicles) | @snowflakechronicles*
