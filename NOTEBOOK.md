# ❄️ Snowflake DCM Projects — HR Analytics Platform
### Infrastructure as Code for Snowflake | Complete End-to-End Implementation

> **Author:** Satish Kumar | **Platform:** Snowflake Data Cloud Management (Preview)
> **Account:** PQC86579 | **User:** SATISH
> **Published:** [Medium](https://medium.com/@snowflakechronicles) | **Follow:** @snowflakechronicles

---

## 📋 Table of Contents

| # | Section |
|---|---------|
| 1 | [Project Overview](#-project-overview) |
| 2 | [Architecture](#-architecture) |
| 3 | [Repository Structure](#-repository-structure) |
| 4 | [manifest.yml](#-manifestyml) |
| 5 | [Phase 1 — Account Preparation](#-phase-1--account-preparation) |
| 6 | [Phase 2 — Create DCM Projects](#-phase-2--create-dcm-project-objects) |
| 7 | [Phase 3 — Deploy to DEV](#-phase-3--plan--deploy-to-dev) |
| 8 | [01_infrastructure.sql](#-01_infrastructuresql) |
| 9 | [02_tables.sql](#-02_tablessql) |
| 10 | [03_dynamic_tables.sql](#-03_dynamic_tablessql) |
| 11 | [04_views.sql](#-04_viewssql) |
| 12 | [05_functions.sql](#-05_functionssql) |
| 13 | [06_tasks.sql](#-06_taskssql) |
| 14 | [07_grants.sql](#-07_grantssql) |
| 15 | [08_data_quality.sql](#-08_data_qualitysql) |
| 16 | [09_security.sql](#-09_securitysql) |
| 17 | [Phase 4 — Test Suite](#-phase-4--insert-sample-data--test-suite) |
| 18 | [Phase 5 — TEST ALL](#-phase-5--dcm-data-quality-expectations) |
| 19 | [Supported Object Types](#-supported-object-types-reference) |
| 20 | [Key Rules](#-key-rules) |

---

## 🎯 Project Overview

This notebook demonstrates a **complete DCM Projects workflow** for an HR Analytics platform.

| Property | Value |
|----------|-------|
| **Use Case** | HR Analytics Platform |
| **Architecture** | Medallion (Bronze → Silver → Gold) |
| **Environments** | DEV → STAGE → PROD |
| **Definition Files** | 9 |
| **Object Types Covered** | 14 |
| **Data Quality Expectations** | 11 |
| **Test Suite** | 16 checks |
| **Jinja Variable** | `{{env}}` → DEV / STG / PROD |

### What is DCM Projects?

Snowflake DCM Projects is a **Preview feature** that brings Infrastructure as Code to Snowflake natively:

- ✅ **Declarative** — `DEFINE` instead of `CREATE`
- ✅ **Templated** — Jinja2 variables across all environments
- ✅ **Dry-run** — `PLAN` before every `DEPLOY`
- ✅ **Testable** — native `TEST ALL` with named expectations
- ✅ **Auditable** — full deployment history built in
- ✅ **Zero external tooling** — no Terraform, no dbt, no extra dependencies

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                    MEDALLION ARCHITECTURE                           │
├──────────────┬──────────────────────┬───────────────────────────────┤
│  🥉 BRONZE   │     🥈 SILVER        │         🥇 GOLD               │
│  RAW Schema  │   CLEANSED Schema    │      ANALYTICS Schema         │
├──────────────┼──────────────────────┼───────────────────────────────┤
│ EMPLOYEES    │ EMPLOYEES_CLEAN (DT) │ DEPT_HEADCOUNT (DT)           │
│ DEPARTMENTS  │ PAYROLL_CLEAN (DT)   │ PAYROLL_SUMMARY (DT)          │
│ PAYROLL      │                      │ VW_ACTIVE_EMPLOYEES (View)    │
│ REVIEWS      │                      │ VW_SALARY_BANDS (View)        │
│              │                      │ VW_TOP_PERFORMERS (Sec. View) │
│              │                      │ VW_PAYROLL_OVERVIEW (Sec. View│
└──────────────┴──────────────────────┴───────────────────────────────┘

DT = Dynamic Table | Sec. View = Secure View
```

```
Multi-Environment Promotion Flow:
──────────────────────────────────
Feature Branch
      │
      ▼
  PLAN (DEV) ──► Review Changeset ──► DEPLOY (DEV)
                                            │
                                            ▼
                                      PLAN (STAGE) ──► DEPLOY (STAGE)
                                                              │
                                                              ▼
                                                       PLAN (PROD) ──► DEPLOY (PROD)
```

---

## 📁 Repository Structure

```
my_hr_dcm_project/
│
├── 📄 manifest.yml                  ← Project config, targets & Jinja variables
│
└── 📁 sources/
    └── 📁 definitions/
        ├── 📄 01_infrastructure.sql  ← Database, schemas, warehouse, roles
        ├── 📄 02_tables.sql          ← Bronze layer tables + internal stage
        ├── 📄 03_dynamic_tables.sql  ← Silver + Gold dynamic tables
        ├── 📄 04_views.sql           ← Views & secure views
        ├── 📄 05_functions.sql       ← SQL functions + user-defined DMFs
        ├── 📄 06_tasks.sql           ← Scheduled ingestion tasks
        ├── 📄 07_grants.sql          ← All GRANT statements
        ├── 📄 08_data_quality.sql    ← ATTACH system & user DMFs
        └── 📄 09_security.sql        ← Tags & authentication policies
```

> **⚠️ Key rule:** `DEFINE` statement order across all files does **not** matter.
> Snowflake resolves all object dependencies automatically at deploy time.
> All object references **must** be fully qualified (`database.schema.object`).

---

## 📦 manifest.yml

The manifest is the heart of the project. It maps targets to environments and sets all Jinja variables per configuration. The primary template variable `{{env}}` builds fully qualified names like `HR_ANALYTICS_DEV`, `HR_ANALYTICS_STG`, `HR_ANALYTICS_PROD`.

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
    warehouse:           "SHARED_WH"
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

### Variable Resolution per Environment

| Variable | DEV | STAGE | PROD |
|----------|-----|-------|------|
| `{{env}}` | `DEV` | `STG` | `PROD` |
| `{{wh_size}}` | `X-SMALL` | `SMALL` | `LARGE` |
| `{{auto_suspend}}` | `60` sec | `300` sec | `600` sec |
| `{{data_retention_days}}` | `1` | `7` | `90` |
| Database name | `HR_ANALYTICS_DEV` | `HR_ANALYTICS_STG` | `HR_ANALYTICS_PROD` |
| Warehouse name | `HR_ANALYTICS_WH_DEV` | `HR_ANALYTICS_WH_STG` | `HR_ANALYTICS_WH_PROD` |

---

## ⚙️ Phase 1 — Account Preparation

> **Role required:** `ACCOUNTADMIN`
> Run every statement in this section before creating any DCM project objects.

```sql
-- ============================================================================
-- PHASE 1: PREREQUISITES & ACCOUNT PREPARATION
-- Run every statement in this phase as ACCOUNTADMIN.
-- ============================================================================

USE ROLE ACCOUNTADMIN;

-- ── 1.1  Admin database & schema to hold DCM project objects ─────────────────
CREATE DATABASE IF NOT EXISTS HR_DCM_ADMIN;
CREATE SCHEMA  IF NOT EXISTS HR_DCM_ADMIN.PROJECTS;

-- ── 1.2  Deployment roles — one per environment, least-privilege ─────────────
CREATE ROLE IF NOT EXISTS HR_DCM_DEV_DEPLOYER;
CREATE ROLE IF NOT EXISTS HR_DCM_STG_DEPLOYER;
CREATE ROLE IF NOT EXISTS HR_DCM_PROD_DEPLOYER;

-- ── 1.3  Role hierarchy: SYSADMIN > PROD > STG > DEV ────────────────────────
GRANT ROLE HR_DCM_DEV_DEPLOYER  TO ROLE HR_DCM_STG_DEPLOYER;
GRANT ROLE HR_DCM_STG_DEPLOYER  TO ROLE HR_DCM_PROD_DEPLOYER;
GRANT ROLE HR_DCM_PROD_DEPLOYER TO ROLE SYSADMIN;

-- ── 1.4  Schema-level: allow each role to create DCM projects ────────────────
GRANT USAGE ON DATABASE HR_DCM_ADMIN           TO ROLE HR_DCM_DEV_DEPLOYER;
GRANT USAGE ON SCHEMA   HR_DCM_ADMIN.PROJECTS  TO ROLE HR_DCM_DEV_DEPLOYER;
GRANT CREATE DCM PROJECT ON SCHEMA HR_DCM_ADMIN.PROJECTS
    TO ROLE HR_DCM_DEV_DEPLOYER;

GRANT USAGE ON DATABASE HR_DCM_ADMIN           TO ROLE HR_DCM_STG_DEPLOYER;
GRANT USAGE ON SCHEMA   HR_DCM_ADMIN.PROJECTS  TO ROLE HR_DCM_STG_DEPLOYER;
GRANT CREATE DCM PROJECT ON SCHEMA HR_DCM_ADMIN.PROJECTS
    TO ROLE HR_DCM_STG_DEPLOYER;

GRANT USAGE ON DATABASE HR_DCM_ADMIN           TO ROLE HR_DCM_PROD_DEPLOYER;
GRANT USAGE ON SCHEMA   HR_DCM_ADMIN.PROJECTS  TO ROLE HR_DCM_PROD_DEPLOYER;
GRANT CREATE DCM PROJECT ON SCHEMA HR_DCM_ADMIN.PROJECTS
    TO ROLE HR_DCM_PROD_DEPLOYER;

-- ── 1.5  Warehouse access for running DCM commands ──────────────────────────
GRANT USAGE ON WAREHOUSE SHARED_WH TO ROLE HR_DCM_DEV_DEPLOYER;
GRANT USAGE ON WAREHOUSE SHARED_WH TO ROLE HR_DCM_STG_DEPLOYER;
GRANT USAGE ON WAREHOUSE SHARED_WH TO ROLE HR_DCM_PROD_DEPLOYER;

-- ── 1.6  Account-level privileges ────────────────────────────────────────────
--   DCM DEFINE creates databases, roles, and warehouses at the account level.
--   These require account-level CREATE privileges on the deploying role.
GRANT CREATE DATABASE  ON ACCOUNT TO ROLE HR_DCM_DEV_DEPLOYER;
GRANT CREATE ROLE      ON ACCOUNT TO ROLE HR_DCM_DEV_DEPLOYER;
GRANT CREATE WAREHOUSE ON ACCOUNT TO ROLE HR_DCM_DEV_DEPLOYER;

--   Attaching Data Metric Functions requires this global privilege.
GRANT EXECUTE DATA METRIC FUNCTION ON ACCOUNT TO ROLE HR_DCM_DEV_DEPLOYER;

-- ── 1.7  Assign role to the human user ──────────────────────────────────────
GRANT ROLE HR_DCM_DEV_DEPLOYER TO USER SATISH;
```

---

## 🗂️ Phase 2 — Create DCM Project Objects

> One DCM PROJECT object per environment. The project is a container —
> actual object definitions live in the 9 workspace files deployed in Phase 3.

```sql
-- ============================================================================
-- PHASE 2: CREATE DCM PROJECT OBJECTS
-- ============================================================================

USE ROLE HR_DCM_DEV_DEPLOYER;
CREATE DCM PROJECT IF NOT EXISTS HR_DCM_ADMIN.PROJECTS.HR_PROJECT_DEV
  COMMENT = 'HR Analytics — Development';

USE ROLE HR_DCM_STG_DEPLOYER;
CREATE DCM PROJECT IF NOT EXISTS HR_DCM_ADMIN.PROJECTS.HR_PROJECT_STG
  COMMENT = 'HR Analytics — Staging';

USE ROLE HR_DCM_PROD_DEPLOYER;
CREATE DCM PROJECT IF NOT EXISTS HR_DCM_ADMIN.PROJECTS.HR_PROJECT_PROD
  COMMENT = 'HR Analytics — Production';

-- Verify all three projects were created
USE ROLE WS_ADMIN;
SHOW DCM PROJECTS IN SCHEMA HR_DCM_ADMIN.PROJECTS;
```

---

## 🚀 Phase 3 — PLAN + Deploy to DEV

> **Always PLAN before DEPLOY.**
> Review the JSON changeset for unexpected `DROP` operations before proceeding.

```sql
-- ============================================================================
-- PHASE 3: PLAN (dry run) then DEPLOY TO DEV
-- ============================================================================

USE ROLE HR_DCM_DEV_DEPLOYER;

-- ── Step 1: Dry run — no changes applied ─────────────────────────────────────
EXECUTE DCM PROJECT HR_DCM_ADMIN.PROJECTS.HR_PROJECT_DEV
  PLAN
  USING CONFIGURATION DEV
FROM
  'snow://workspace/USER$.PUBLIC.DEFAULT$/versions/live/my_hr_dcm_project';

-- Review JSON output:
--   changeset[].type = CREATE | ALTER | DROP
--   Verify no unexpected DROP operations before proceeding.

-- ── Step 2: Deploy to DEV ─────────────────────────────────────────────────────
EXECUTE DCM PROJECT HR_DCM_ADMIN.PROJECTS.HR_PROJECT_DEV
  DEPLOY AS 'initial hr dev deployment'
  USING CONFIGURATION DEV
FROM
  'snow://workspace/USER$.PUBLIC.DEFAULT$/versions/live/my_hr_dcm_project';

-- ── Step 3: Introspect what was deployed ──────────────────────────────────────
SHOW ENTITIES IN DCM PROJECT HR_DCM_ADMIN.PROJECTS.HR_PROJECT_DEV;
SHOW GRANTS   IN DCM PROJECT HR_DCM_ADMIN.PROJECTS.HR_PROJECT_DEV;

-- ── Step 4: Deploy to STAGE (after DEV validation) ───────────────────────────
USE ROLE HR_DCM_STG_DEPLOYER;
EXECUTE DCM PROJECT HR_DCM_ADMIN.PROJECTS.HR_PROJECT_STG
  DEPLOY AS 'initial hr stage deployment'
  USING CONFIGURATION STAGE
FROM
  'snow://workspace/USER$.PUBLIC.DEFAULT$/versions/live/my_hr_dcm_project';

-- ── Step 5: Deploy to PROD (after STAGE validation — service user only) ───────
USE ROLE HR_DCM_PROD_DEPLOYER;
EXECUTE DCM PROJECT HR_DCM_ADMIN.PROJECTS.HR_PROJECT_PROD
  DEPLOY AS 'initial hr prod deployment'
  USING CONFIGURATION PROD
FROM
  'snow://workspace/USER$.PUBLIC.DEFAULT$/versions/live/my_hr_dcm_project';
```

---

## 📄 01_infrastructure.sql

> **Defines:** Database · 4 Schemas · Warehouse · 3 Account Roles · 2 Database Roles

```sql
-- 01_infrastructure.sql — Database, Schemas, Warehouse, Roles

DEFINE DATABASE HR_ANALYTICS_{{env}};

DEFINE SCHEMA HR_ANALYTICS_{{env}}.RAW;
DEFINE SCHEMA HR_ANALYTICS_{{env}}.CLEANSED;
DEFINE SCHEMA HR_ANALYTICS_{{env}}.ANALYTICS;
DEFINE SCHEMA HR_ANALYTICS_{{env}}.TESTS;

DEFINE WAREHOUSE HR_ANALYTICS_WH_{{env}}
    WAREHOUSE_SIZE = '{{wh_size}}'
    AUTO_SUSPEND   = {{auto_suspend}}
    AUTO_RESUME    = TRUE
    COMMENT        = 'HR Analytics warehouse';

-- Account-level roles
DEFINE ROLE HR_ANALYTICS_READER_{{env}};
DEFINE ROLE HR_ANALYTICS_WRITER_{{env}};
DEFINE ROLE HR_ANALYTICS_ADMIN_{{env}};

-- Database roles
DEFINE DATABASE ROLE HR_ANALYTICS_{{env}}.DB_READER;
DEFINE DATABASE ROLE HR_ANALYTICS_{{env}}.DB_WRITER;
```

---

## 📄 02_tables.sql

> **Defines:** 4 Bronze tables · 1 Internal stage
> **Note:** `DATA_METRIC_SCHEDULE` is required on all tables that will have DMFs attached.

```sql
-- 02_tables.sql — Bronze layer tables + internal stage

DEFINE TABLE HR_ANALYTICS_{{env}}.RAW.EMPLOYEES (
    EMP_ID       NUMBER(38,0)    NOT NULL,
    FIRST_NAME   VARCHAR(100),
    LAST_NAME    VARCHAR(100),
    EMAIL        VARCHAR(255),
    DEPT_ID      NUMBER(38,0),
    HIRE_DATE    DATE,
    SALARY       NUMBER(12,2),
    CREATED_AT   TIMESTAMP_NTZ   DEFAULT CURRENT_TIMESTAMP()
)
DATA_RETENTION_TIME_IN_DAYS = {{data_retention_days}}
DATA_METRIC_SCHEDULE        = 'TRIGGER_ON_CHANGES';

DEFINE TABLE HR_ANALYTICS_{{env}}.RAW.DEPARTMENTS (
    DEPT_ID    NUMBER(38,0)    NOT NULL,
    DEPT_NAME  VARCHAR(100),
    LOCATION   VARCHAR(100),
    CREATED_AT TIMESTAMP_NTZ   DEFAULT CURRENT_TIMESTAMP()
)
DATA_RETENTION_TIME_IN_DAYS = {{data_retention_days}}
DATA_METRIC_SCHEDULE        = 'TRIGGER_ON_CHANGES';

DEFINE TABLE HR_ANALYTICS_{{env}}.RAW.PAYROLL (
    PAYROLL_ID  NUMBER(38,0)    NOT NULL,
    EMP_ID      NUMBER(38,0)    NOT NULL,
    PAY_PERIOD  DATE,
    GROSS_PAY   NUMBER(12,2),
    DEDUCTIONS  NUMBER(12,2),
    CREATED_AT  TIMESTAMP_NTZ   DEFAULT CURRENT_TIMESTAMP()
)
DATA_RETENTION_TIME_IN_DAYS = {{data_retention_days}}
DATA_METRIC_SCHEDULE        = 'TRIGGER_ON_CHANGES';

DEFINE TABLE HR_ANALYTICS_{{env}}.RAW.REVIEWS (
    REVIEW_ID   NUMBER(38,0)    NOT NULL,
    EMP_ID      NUMBER(38,0)    NOT NULL,
    REVIEW_DATE DATE,
    RATING      NUMBER(1,0),
    COMMENTS    VARCHAR(500),
    CREATED_AT  TIMESTAMP_NTZ   DEFAULT CURRENT_TIMESTAMP()
)
DATA_RETENTION_TIME_IN_DAYS = {{data_retention_days}}
DATA_METRIC_SCHEDULE        = 'TRIGGER_ON_CHANGES';

-- Internal stage for raw HR file ingestion
DEFINE STAGE HR_ANALYTICS_{{env}}.RAW.HR_LOAD_STAGE
    DIRECTORY = (ENABLE = TRUE)
    COMMENT   = 'Stage for HR data file ingestion';
```

---

## 📄 03_dynamic_tables.sql

> **Defines:** 2 Silver (cleansed) dynamic tables · 2 Gold (analytics) dynamic tables
> **Note:** DCM resolves the dependency chain (Gold reads from Silver) automatically.

```sql
-- 03_dynamic_tables.sql — Silver (cleansed) + Gold (analytics) layers

-- ── SILVER: Cleansed layer ───────────────────────────────────────────────────

DEFINE DYNAMIC TABLE HR_ANALYTICS_{{env}}.CLEANSED.EMPLOYEES_CLEAN
    TARGET_LAG   = '1 hour'
    WAREHOUSE    = HR_ANALYTICS_WH_{{env}}
    REFRESH_MODE = AUTO
    INITIALIZE   = ON_CREATE
AS
    SELECT
        EMP_ID,
        TRIM(UPPER(FIRST_NAME)) AS FIRST_NAME,
        TRIM(UPPER(LAST_NAME))  AS LAST_NAME,
        LOWER(TRIM(EMAIL))      AS EMAIL,
        DEPT_ID,
        HIRE_DATE,
        SALARY,
        CREATED_AT
    FROM HR_ANALYTICS_{{env}}.RAW.EMPLOYEES
    WHERE EMP_ID IS NOT NULL;

DEFINE DYNAMIC TABLE HR_ANALYTICS_{{env}}.CLEANSED.PAYROLL_CLEAN
    TARGET_LAG   = '1 hour'
    WAREHOUSE    = HR_ANALYTICS_WH_{{env}}
    REFRESH_MODE = AUTO
    INITIALIZE   = ON_CREATE
AS
    SELECT
        PAYROLL_ID,
        EMP_ID,
        PAY_PERIOD,
        GROSS_PAY,
        DEDUCTIONS,
        GROSS_PAY - DEDUCTIONS AS NET_PAY,
        CREATED_AT
    FROM HR_ANALYTICS_{{env}}.RAW.PAYROLL
    WHERE PAYROLL_ID IS NOT NULL
      AND EMP_ID     IS NOT NULL;

-- ── GOLD: Analytics layer ────────────────────────────────────────────────────

DEFINE DYNAMIC TABLE HR_ANALYTICS_{{env}}.ANALYTICS.DEPT_HEADCOUNT
    TARGET_LAG   = '1 hour'
    WAREHOUSE    = HR_ANALYTICS_WH_{{env}}
    REFRESH_MODE = AUTO
    INITIALIZE   = ON_CREATE
AS
    SELECT
        d.DEPT_ID,
        UPPER(TRIM(d.DEPT_NAME)) AS DEPT_NAME,
        d.LOCATION,
        COUNT(e.EMP_ID)          AS HEADCOUNT,
        AVG(e.SALARY)            AS AVG_SALARY,
        MIN(e.HIRE_DATE)         AS EARLIEST_HIRE,
        MAX(e.HIRE_DATE)         AS LATEST_HIRE
    FROM HR_ANALYTICS_{{env}}.RAW.DEPARTMENTS d
    LEFT JOIN HR_ANALYTICS_{{env}}.CLEANSED.EMPLOYEES_CLEAN e
        ON d.DEPT_ID = e.DEPT_ID
    GROUP BY d.DEPT_ID, d.DEPT_NAME, d.LOCATION;

DEFINE DYNAMIC TABLE HR_ANALYTICS_{{env}}.ANALYTICS.PAYROLL_SUMMARY
    TARGET_LAG   = '1 hour'
    WAREHOUSE    = HR_ANALYTICS_WH_{{env}}
    REFRESH_MODE = AUTO
    INITIALIZE   = ON_CREATE
AS
    SELECT
        d.DEPT_ID,
        UPPER(TRIM(d.DEPT_NAME))        AS DEPT_NAME,
        COUNT(DISTINCT p.EMP_ID)        AS EMPLOYEE_COUNT,
        SUM(p.GROSS_PAY)                AS TOTAL_GROSS,
        SUM(p.DEDUCTIONS)               AS TOTAL_DEDUCTIONS,
        SUM(p.GROSS_PAY - p.DEDUCTIONS) AS TOTAL_NET
    FROM HR_ANALYTICS_{{env}}.CLEANSED.PAYROLL_CLEAN    p
    JOIN HR_ANALYTICS_{{env}}.CLEANSED.EMPLOYEES_CLEAN  e
        ON p.EMP_ID = e.EMP_ID
    JOIN HR_ANALYTICS_{{env}}.RAW.DEPARTMENTS           d
        ON e.DEPT_ID = d.DEPT_ID
    GROUP BY d.DEPT_ID, d.DEPT_NAME;
```

---

## 📄 04_views.sql

> **Defines:** 2 standard views · 2 secure views
> **Note:** `SECURE VIEW` hides the view definition from non-privileged users — essential for salary and payroll data.

```sql
-- 04_views.sql — Views & Secure Views

DEFINE VIEW HR_ANALYTICS_{{env}}.ANALYTICS.VW_ACTIVE_EMPLOYEES
AS
    SELECT e.*, d.DEPT_NAME
    FROM HR_ANALYTICS_{{env}}.CLEANSED.EMPLOYEES_CLEAN e
    JOIN HR_ANALYTICS_{{env}}.RAW.DEPARTMENTS d
        ON e.DEPT_ID = d.DEPT_ID;

DEFINE VIEW HR_ANALYTICS_{{env}}.ANALYTICS.VW_SALARY_BANDS
AS
    SELECT
        EMP_ID,
        FIRST_NAME,
        LAST_NAME,
        SALARY,
        HR_ANALYTICS_{{env}}.ANALYTICS.GET_PERFORMANCE_BAND(
            (SELECT r.RATING
             FROM   HR_ANALYTICS_{{env}}.RAW.REVIEWS r
             WHERE  r.EMP_ID = e.EMP_ID
             ORDER BY r.REVIEW_DATE DESC
             LIMIT 1)
        ) AS PERFORMANCE_BAND
    FROM HR_ANALYTICS_{{env}}.CLEANSED.EMPLOYEES_CLEAN e
    WHERE SALARY < HR_ANALYTICS_{{env}}.ANALYTICS.GET_MIN_SALARY_THRESHOLD();

DEFINE SECURE VIEW HR_ANALYTICS_{{env}}.ANALYTICS.VW_TOP_PERFORMERS
AS
    SELECT
        e.EMP_ID,
        e.FIRST_NAME,
        e.LAST_NAME,
        d.DEPT_NAME,
        r.RATING,
        HR_ANALYTICS_{{env}}.ANALYTICS.GET_PERFORMANCE_BAND(r.RATING)  AS PERFORMANCE_BAND,
        e.SALARY,
        HR_ANALYTICS_{{env}}.ANALYTICS.FORMAT_SALARY(e.SALARY)         AS SALARY_DISPLAY
    FROM HR_ANALYTICS_{{env}}.CLEANSED.EMPLOYEES_CLEAN e
    JOIN HR_ANALYTICS_{{env}}.RAW.REVIEWS     r ON e.EMP_ID  = r.EMP_ID
    JOIN HR_ANALYTICS_{{env}}.RAW.DEPARTMENTS d ON e.DEPT_ID = d.DEPT_ID
    WHERE r.RATING >= 4
    ORDER BY r.RATING DESC, e.SALARY DESC;

DEFINE SECURE VIEW HR_ANALYTICS_{{env}}.ANALYTICS.VW_PAYROLL_OVERVIEW
AS
    SELECT
        DEPT_NAME,
        EMPLOYEE_COUNT,
        TOTAL_GROSS,
        TOTAL_DEDUCTIONS,
        TOTAL_NET
    FROM HR_ANALYTICS_{{env}}.ANALYTICS.PAYROLL_SUMMARY;
```

---

## 📄 05_functions.sql

> **Defines:** 3 SQL scalar functions · 3 user-defined Data Metric Functions (UDMFs)
> **Note:** UDMFs defined here are referenced in `08_data_quality.sql` via `ATTACH`.

```sql
-- 05_functions.sql — SQL Functions & User-Defined Data Metric Functions

-- ── SQL Scalar Functions ─────────────────────────────────────────────────────

DEFINE FUNCTION HR_ANALYTICS_{{env}}.ANALYTICS.GET_PERFORMANCE_BAND(RATING NUMBER)
    RETURNS VARCHAR
AS
$$
    CASE
        WHEN RATING = 5 THEN 'OUTSTANDING'
        WHEN RATING = 4 THEN 'EXCEEDS EXPECTATIONS'
        WHEN RATING = 3 THEN 'MEETS EXPECTATIONS'
        WHEN RATING = 2 THEN 'BELOW EXPECTATIONS'
        ELSE                  'CRITICAL'
    END
$$;

DEFINE FUNCTION HR_ANALYTICS_{{env}}.ANALYTICS.GET_MIN_SALARY_THRESHOLD()
    RETURNS NUMBER
AS
$$
    100000
$$;

DEFINE FUNCTION HR_ANALYTICS_{{env}}.ANALYTICS.FORMAT_SALARY(AMOUNT NUMBER)
    RETURNS VARCHAR
AS
$$
    '$' || TO_VARCHAR(AMOUNT, '999,999,999.00')
$$;

-- ── User-Defined Data Metric Functions (UDMFs) ───────────────────────────────

DEFINE DATA METRIC FUNCTION HR_ANALYTICS_{{env}}.TESTS.SALARY_RANGE_CHECK(
    TABLE_NAME TABLE(COLUMN_VALUE NUMBER)
)
    RETURNS NUMBER
AS
$$
    SELECT COUNT(*)
    FROM   TABLE_NAME
    WHERE  COLUMN_VALUE IS NOT NULL
      AND  (COLUMN_VALUE < 30000 OR COLUMN_VALUE > 500000)
$$;

DEFINE DATA METRIC FUNCTION HR_ANALYTICS_{{env}}.TESTS.EMAIL_FORMAT_CHECK(
    TABLE_NAME TABLE(COLUMN_VALUE VARCHAR)
)
    RETURNS NUMBER
AS
$$
    SELECT COUNT(*)
    FROM   TABLE_NAME
    WHERE  COLUMN_VALUE IS NOT NULL
      AND  COLUMN_VALUE NOT RLIKE
           '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$'
$$;

DEFINE DATA METRIC FUNCTION HR_ANALYTICS_{{env}}.TESTS.RATING_RANGE_CHECK(
    TABLE_NAME TABLE(COLUMN_VALUE NUMBER)
)
    RETURNS NUMBER
AS
$$
    SELECT COUNT(*)
    FROM   TABLE_NAME
    WHERE  COLUMN_VALUE IS NOT NULL
      AND  (COLUMN_VALUE < 1 OR COLUMN_VALUE > 5)
$$;
```

---

## 📄 06_tasks.sql

> **Defines:** 3 scheduled COPY INTO tasks
> **Note:** All newly deployed tasks are **SUSPENDED by default**. Resume manually after deployment.
> Tasks use business-appropriate schedules: employees daily, payroll bi-monthly, reviews weekly.

```sql
-- 06_tasks.sql — Scheduled data ingestion tasks
-- ⚠️  All newly deployed tasks start SUSPENDED.
--     Resume via: ALTER TASK <task_name> RESUME;

DEFINE TASK HR_ANALYTICS_{{env}}.RAW.LOAD_EMPLOYEES_TASK
    WAREHOUSE = HR_ANALYTICS_WH_{{env}}
    SCHEDULE  = 'USING CRON 0 2 * * * America/New_York'
    COMMENT   = 'Load employees from stage daily at 2 AM'
AS
    COPY INTO HR_ANALYTICS_{{env}}.RAW.EMPLOYEES
    FROM @HR_ANALYTICS_{{env}}.RAW.HR_LOAD_STAGE/employees/
    FILE_FORMAT = (TYPE = 'CSV' SKIP_HEADER = 1);

DEFINE TASK HR_ANALYTICS_{{env}}.RAW.LOAD_PAYROLL_TASK
    WAREHOUSE = HR_ANALYTICS_WH_{{env}}
    SCHEDULE  = 'USING CRON 0 3 1,15 * * America/New_York'
    COMMENT   = 'Load payroll on 1st and 15th of each month'
AS
    COPY INTO HR_ANALYTICS_{{env}}.RAW.PAYROLL
    FROM @HR_ANALYTICS_{{env}}.RAW.HR_LOAD_STAGE/payroll/
    FILE_FORMAT = (TYPE = 'CSV' SKIP_HEADER = 1);

DEFINE TASK HR_ANALYTICS_{{env}}.RAW.LOAD_REVIEWS_TASK
    WAREHOUSE = HR_ANALYTICS_WH_{{env}}
    SCHEDULE  = 'USING CRON 0 4 * * 1 America/New_York'
    COMMENT   = 'Load reviews weekly on Monday at 4 AM'
AS
    COPY INTO HR_ANALYTICS_{{env}}.RAW.REVIEWS
    FROM @HR_ANALYTICS_{{env}}.RAW.HR_LOAD_STAGE/reviews/
    FILE_FORMAT = (TYPE = 'CSV' SKIP_HEADER = 1);
```

### Resume Tasks After Deployment

```sql
-- Run after each environment deployment to activate tasks
ALTER TASK HR_ANALYTICS_DEV.RAW.LOAD_EMPLOYEES_TASK  RESUME;
ALTER TASK HR_ANALYTICS_DEV.RAW.LOAD_PAYROLL_TASK    RESUME;
ALTER TASK HR_ANALYTICS_DEV.RAW.LOAD_REVIEWS_TASK    RESUME;
```

---

## 📄 07_grants.sql

> **Defines:** Full RBAC — role hierarchy, database roles, schema/table/view/stage/warehouse grants
> **Note:** Grants applied outside DCM coexist and are **not** removed by DCM on subsequent deploys.

```sql
-- 07_grants.sql — Role hierarchy, schema/object privileges

-- ── Role hierarchy ───────────────────────────────────────────────────────────
GRANT ROLE HR_ANALYTICS_READER_{{env}} TO ROLE HR_ANALYTICS_WRITER_{{env}};
GRANT ROLE HR_ANALYTICS_WRITER_{{env}} TO ROLE HR_ANALYTICS_ADMIN_{{env}};

-- ── Database role mapping ────────────────────────────────────────────────────
GRANT DATABASE ROLE HR_ANALYTICS_{{env}}.DB_READER TO ROLE HR_ANALYTICS_READER_{{env}};
GRANT DATABASE ROLE HR_ANALYTICS_{{env}}.DB_WRITER TO ROLE HR_ANALYTICS_WRITER_{{env}};

-- ── Database & Schema — READER ───────────────────────────────────────────────
GRANT USAGE ON DATABASE HR_ANALYTICS_{{env}}           TO ROLE HR_ANALYTICS_READER_{{env}};
GRANT USAGE ON SCHEMA   HR_ANALYTICS_{{env}}.RAW       TO ROLE HR_ANALYTICS_READER_{{env}};
GRANT USAGE ON SCHEMA   HR_ANALYTICS_{{env}}.CLEANSED  TO ROLE HR_ANALYTICS_READER_{{env}};
GRANT USAGE ON SCHEMA   HR_ANALYTICS_{{env}}.ANALYTICS TO ROLE HR_ANALYTICS_READER_{{env}};

-- ── Database & Schema — WRITER ───────────────────────────────────────────────
GRANT USAGE ON DATABASE HR_ANALYTICS_{{env}}           TO ROLE HR_ANALYTICS_WRITER_{{env}};
GRANT USAGE ON SCHEMA   HR_ANALYTICS_{{env}}.RAW       TO ROLE HR_ANALYTICS_WRITER_{{env}};

-- ── Database & Schema — ADMIN ────────────────────────────────────────────────
GRANT USAGE ON DATABASE HR_ANALYTICS_{{env}}           TO ROLE HR_ANALYTICS_ADMIN_{{env}};
GRANT USAGE ON SCHEMA   HR_ANALYTICS_{{env}}.RAW       TO ROLE HR_ANALYTICS_ADMIN_{{env}};
GRANT USAGE ON SCHEMA   HR_ANALYTICS_{{env}}.CLEANSED  TO ROLE HR_ANALYTICS_ADMIN_{{env}};
GRANT USAGE ON SCHEMA   HR_ANALYTICS_{{env}}.ANALYTICS TO ROLE HR_ANALYTICS_ADMIN_{{env}};
GRANT USAGE ON SCHEMA   HR_ANALYTICS_{{env}}.TESTS     TO ROLE HR_ANALYTICS_ADMIN_{{env}};

-- ── Table privileges — READER ────────────────────────────────────────────────
GRANT SELECT ON TABLE HR_ANALYTICS_{{env}}.RAW.EMPLOYEES   TO ROLE HR_ANALYTICS_READER_{{env}};
GRANT SELECT ON TABLE HR_ANALYTICS_{{env}}.RAW.DEPARTMENTS TO ROLE HR_ANALYTICS_READER_{{env}};
GRANT SELECT ON TABLE HR_ANALYTICS_{{env}}.RAW.PAYROLL     TO ROLE HR_ANALYTICS_READER_{{env}};
GRANT SELECT ON TABLE HR_ANALYTICS_{{env}}.RAW.REVIEWS     TO ROLE HR_ANALYTICS_READER_{{env}};

-- ── Table privileges — WRITER ────────────────────────────────────────────────
GRANT INSERT, UPDATE ON TABLE HR_ANALYTICS_{{env}}.RAW.EMPLOYEES   TO ROLE HR_ANALYTICS_WRITER_{{env}};
GRANT INSERT, UPDATE ON TABLE HR_ANALYTICS_{{env}}.RAW.DEPARTMENTS TO ROLE HR_ANALYTICS_WRITER_{{env}};
GRANT INSERT, UPDATE ON TABLE HR_ANALYTICS_{{env}}.RAW.PAYROLL     TO ROLE HR_ANALYTICS_WRITER_{{env}};
GRANT INSERT, UPDATE ON TABLE HR_ANALYTICS_{{env}}.RAW.REVIEWS     TO ROLE HR_ANALYTICS_WRITER_{{env}};

-- ── Dynamic table privileges — READER ───────────────────────────────────────
GRANT SELECT ON DYNAMIC TABLE HR_ANALYTICS_{{env}}.CLEANSED.EMPLOYEES_CLEAN  TO ROLE HR_ANALYTICS_READER_{{env}};
GRANT SELECT ON DYNAMIC TABLE HR_ANALYTICS_{{env}}.CLEANSED.PAYROLL_CLEAN    TO ROLE HR_ANALYTICS_READER_{{env}};
GRANT SELECT ON DYNAMIC TABLE HR_ANALYTICS_{{env}}.ANALYTICS.DEPT_HEADCOUNT  TO ROLE HR_ANALYTICS_READER_{{env}};
GRANT SELECT ON DYNAMIC TABLE HR_ANALYTICS_{{env}}.ANALYTICS.PAYROLL_SUMMARY TO ROLE HR_ANALYTICS_READER_{{env}};

-- ── View privileges — READER ─────────────────────────────────────────────────
GRANT SELECT ON VIEW HR_ANALYTICS_{{env}}.ANALYTICS.VW_ACTIVE_EMPLOYEES TO ROLE HR_ANALYTICS_READER_{{env}};
GRANT SELECT ON VIEW HR_ANALYTICS_{{env}}.ANALYTICS.VW_SALARY_BANDS     TO ROLE HR_ANALYTICS_READER_{{env}};
GRANT SELECT ON VIEW HR_ANALYTICS_{{env}}.ANALYTICS.VW_TOP_PERFORMERS   TO ROLE HR_ANALYTICS_READER_{{env}};
GRANT SELECT ON VIEW HR_ANALYTICS_{{env}}.ANALYTICS.VW_PAYROLL_OVERVIEW TO ROLE HR_ANALYTICS_READER_{{env}};

-- ── Stage privileges — WRITER ────────────────────────────────────────────────
GRANT READ  ON STAGE HR_ANALYTICS_{{env}}.RAW.HR_LOAD_STAGE TO ROLE HR_ANALYTICS_WRITER_{{env}};
GRANT WRITE ON STAGE HR_ANALYTICS_{{env}}.RAW.HR_LOAD_STAGE TO ROLE HR_ANALYTICS_WRITER_{{env}};

-- ── Warehouse — all roles ────────────────────────────────────────────────────
GRANT USAGE ON WAREHOUSE HR_ANALYTICS_WH_{{env}} TO ROLE HR_ANALYTICS_READER_{{env}};
GRANT USAGE ON WAREHOUSE HR_ANALYTICS_WH_{{env}} TO ROLE HR_ANALYTICS_WRITER_{{env}};
GRANT USAGE ON WAREHOUSE HR_ANALYTICS_WH_{{env}} TO ROLE HR_ANALYTICS_ADMIN_{{env}};
```

---

## 📄 08_data_quality.sql

> **Defines:** 11 named data quality expectations across 4 tables
> **Note:** Only `ATTACH` statements here. UDMF definitions live in `05_functions.sql`.
> DMFs without an `EXPECTATION` clause are silently **skipped** by `TEST ALL`.

```sql
-- 08_data_quality.sql — ATTACH system & user DMFs with expectations

-- ── EMPLOYEES — System DMFs ──────────────────────────────────────────────────
ATTACH DATA METRIC FUNCTION SNOWFLAKE.CORE.NULL_COUNT
    TO TABLE HR_ANALYTICS_{{env}}.RAW.EMPLOYEES ON (EMP_ID)
    EXPECTATION NO_NULL_EMP_IDS (VALUE = 0);

ATTACH DATA METRIC FUNCTION SNOWFLAKE.CORE.DUPLICATE_COUNT
    TO TABLE HR_ANALYTICS_{{env}}.RAW.EMPLOYEES ON (EMP_ID)
    EXPECTATION NO_DUPLICATE_EMP_IDS (VALUE = 0);

ATTACH DATA METRIC FUNCTION SNOWFLAKE.CORE.DUPLICATE_COUNT
    TO TABLE HR_ANALYTICS_{{env}}.RAW.EMPLOYEES ON (EMAIL)
    EXPECTATION NO_DUPLICATE_EMAILS (VALUE = 0);

ATTACH DATA METRIC FUNCTION SNOWFLAKE.CORE.NULL_COUNT
    TO TABLE HR_ANALYTICS_{{env}}.RAW.EMPLOYEES ON (EMAIL)
    EXPECTATION NO_NULL_EMAILS (VALUE = 0);

-- ── DEPARTMENTS — System DMFs ────────────────────────────────────────────────
ATTACH DATA METRIC FUNCTION SNOWFLAKE.CORE.NULL_COUNT
    TO TABLE HR_ANALYTICS_{{env}}.RAW.DEPARTMENTS ON (DEPT_ID)
    EXPECTATION NO_NULL_DEPT_IDS (VALUE = 0);

ATTACH DATA METRIC FUNCTION SNOWFLAKE.CORE.DUPLICATE_COUNT
    TO TABLE HR_ANALYTICS_{{env}}.RAW.DEPARTMENTS ON (DEPT_ID)
    EXPECTATION NO_DUPLICATE_DEPT_IDS (VALUE = 0);

-- ── PAYROLL — System DMFs ────────────────────────────────────────────────────
ATTACH DATA METRIC FUNCTION SNOWFLAKE.CORE.NULL_COUNT
    TO TABLE HR_ANALYTICS_{{env}}.RAW.PAYROLL ON (PAYROLL_ID)
    EXPECTATION NO_NULL_PAYROLL_IDS (VALUE = 0);

-- ── REVIEWS — System DMFs ────────────────────────────────────────────────────
ATTACH DATA METRIC FUNCTION SNOWFLAKE.CORE.NULL_COUNT
    TO TABLE HR_ANALYTICS_{{env}}.RAW.REVIEWS ON (REVIEW_ID)
    EXPECTATION NO_NULL_REVIEW_IDS (VALUE = 0);

-- ── EMPLOYEES — User-Defined DMFs ───────────────────────────────────────────
ATTACH DATA METRIC FUNCTION HR_ANALYTICS_{{env}}.TESTS.EMAIL_FORMAT_CHECK
    TO TABLE HR_ANALYTICS_{{env}}.RAW.EMPLOYEES ON (EMAIL)
    EXPECTATION ALL_EMAILS_VALID (VALUE = 0);

ATTACH DATA METRIC FUNCTION HR_ANALYTICS_{{env}}.TESTS.SALARY_RANGE_CHECK
    TO TABLE HR_ANALYTICS_{{env}}.RAW.EMPLOYEES ON (SALARY)
    EXPECTATION ALL_SALARIES_IN_RANGE (VALUE = 0);

-- ── REVIEWS — User-Defined DMFs ─────────────────────────────────────────────
ATTACH DATA METRIC FUNCTION HR_ANALYTICS_{{env}}.TESTS.RATING_RANGE_CHECK
    TO TABLE HR_ANALYTICS_{{env}}.RAW.REVIEWS ON (RATING)
    EXPECTATION ALL_RATINGS_1_TO_5 (VALUE = 0);
```

### Expectations Summary

| Table | Expectation | DMF | Type |
|-------|-------------|-----|------|
| EMPLOYEES | `NO_NULL_EMP_IDS` | `SNOWFLAKE.CORE.NULL_COUNT` | System |
| EMPLOYEES | `NO_DUPLICATE_EMP_IDS` | `SNOWFLAKE.CORE.DUPLICATE_COUNT` | System |
| EMPLOYEES | `NO_DUPLICATE_EMAILS` | `SNOWFLAKE.CORE.DUPLICATE_COUNT` | System |
| EMPLOYEES | `NO_NULL_EMAILS` | `SNOWFLAKE.CORE.NULL_COUNT` | System |
| EMPLOYEES | `ALL_EMAILS_VALID` | `TESTS.EMAIL_FORMAT_CHECK` | User-defined |
| EMPLOYEES | `ALL_SALARIES_IN_RANGE` | `TESTS.SALARY_RANGE_CHECK` | User-defined |
| DEPARTMENTS | `NO_NULL_DEPT_IDS` | `SNOWFLAKE.CORE.NULL_COUNT` | System |
| DEPARTMENTS | `NO_DUPLICATE_DEPT_IDS` | `SNOWFLAKE.CORE.DUPLICATE_COUNT` | System |
| PAYROLL | `NO_NULL_PAYROLL_IDS` | `SNOWFLAKE.CORE.NULL_COUNT` | System |
| REVIEWS | `NO_NULL_REVIEW_IDS` | `SNOWFLAKE.CORE.NULL_COUNT` | System |
| REVIEWS | `ALL_RATINGS_1_TO_5` | `TESTS.RATING_RANGE_CHECK` | User-defined |

---

## 📄 09_security.sql

> **Defines:** 3 governance tags · 2 authentication policies
> **Note:** Tag `PROPAGATE` attribute is not supported in DCM. Column-level tag attachments must be done manually outside the project.

```sql
-- 09_security.sql — Tags & Authentication Policies

-- ── Governance Tags ──────────────────────────────────────────────────────────
DEFINE TAG HR_ANALYTICS_{{env}}.RAW.PII_LEVEL
    ALLOWED_VALUES 'HIGH', 'MEDIUM', 'LOW', 'NONE';

DEFINE TAG HR_ANALYTICS_{{env}}.RAW.COST_CENTER
    ALLOWED_VALUES 'ENGINEERING', 'MARKETING', 'FINANCE', 'HR', 'EXECUTIVE';

DEFINE TAG HR_ANALYTICS_{{env}}.RAW.DATA_DOMAIN
    ALLOWED_VALUES 'EMPLOYEE', 'PAYROLL', 'PERFORMANCE', 'DEPARTMENT';

-- ── Authentication Policies ──────────────────────────────────────────────────

-- UI access: MFA required for all human users
DEFINE AUTHENTICATION POLICY HR_ANALYTICS_{{env}}.RAW.HR_MFA_POLICY
    AUTHENTICATION_METHODS = ('PASSWORD')
    MFA_ENROLLMENT         = 'REQUIRED'
    CLIENT_TYPES           = ('SNOWFLAKE_UI')
    SECURITY_INTEGRATIONS  = ('ALL')
    COMMENT                = 'MFA required for HR data access via UI';

-- Driver/service access: password + keypair for ETL service accounts
DEFINE AUTHENTICATION POLICY HR_ANALYTICS_{{env}}.RAW.HR_SERVICE_POLICY
    AUTHENTICATION_METHODS = ('PASSWORD', 'KEYPAIR')
    CLIENT_TYPES           = ('SNOWFLAKE_UI', 'DRIVERS')
    SECURITY_INTEGRATIONS  = ('ALL')
    COMMENT                = 'Auth policy for HR ETL service accounts';
```

---

## 🧪 Phase 4 — Insert Sample Data & Test Suite

### Sample Data

```sql
-- ── Departments (4 rows) ─────────────────────────────────────────────────────
INSERT INTO HR_ANALYTICS_DEV.RAW.DEPARTMENTS
    (DEPT_ID, DEPT_NAME, LOCATION, CREATED_AT)
VALUES
    (10, 'Engineering',    'San Francisco', CURRENT_TIMESTAMP()),
    (20, 'Marketing',      'New York',      CURRENT_TIMESTAMP()),
    (30, 'Finance',        'Chicago',       CURRENT_TIMESTAMP()),
    (40, 'Human Resources','Austin',        CURRENT_TIMESTAMP());

-- ── Employees (6 rows) ──────────────────────────────────────────────────────
INSERT INTO HR_ANALYTICS_DEV.RAW.EMPLOYEES
    (EMP_ID, FIRST_NAME, LAST_NAME, EMAIL, DEPT_ID, HIRE_DATE, SALARY, CREATED_AT)
VALUES
    (1001,'Priya', 'Sharma', 'priya.sharma@corp.com',  10,'2020-03-15',145000,CURRENT_TIMESTAMP()),
    (1002,'James', 'Wilson', 'james.wilson@corp.com',  10,'2021-07-01',130000,CURRENT_TIMESTAMP()),
    (1003,'Maria', 'Garcia', 'maria.garcia@corp.com',  20,'2019-11-20',115000,CURRENT_TIMESTAMP()),
    (1004,'Chen',  'Wei',    'chen.wei@corp.com',      30,'2022-01-10', 95000,CURRENT_TIMESTAMP()),
    (1005,'Amara', 'Okafor', 'amara.okafor@corp.com',  40,'2018-06-05',105000,CURRENT_TIMESTAMP()),
    (1006,'Liam',  'Patel',  'liam.patel@corp.com',    10,'2023-09-12',120000,CURRENT_TIMESTAMP());

-- ── Payroll (6 rows — March 2026 pay period) ─────────────────────────────────
INSERT INTO HR_ANALYTICS_DEV.RAW.PAYROLL
    (PAYROLL_ID, EMP_ID, PAY_PERIOD, GROSS_PAY, DEDUCTIONS, CREATED_AT)
VALUES
    (1,1001,'2026-03-01',12083.33,3625.00,CURRENT_TIMESTAMP()),
    (2,1002,'2026-03-01',10833.33,3250.00,CURRENT_TIMESTAMP()),
    (3,1003,'2026-03-01', 9583.33,2875.00,CURRENT_TIMESTAMP()),
    (4,1004,'2026-03-01', 7916.67,2375.00,CURRENT_TIMESTAMP()),
    (5,1005,'2026-03-01', 8750.00,2625.00,CURRENT_TIMESTAMP()),
    (6,1006,'2026-03-01',10000.00,3000.00,CURRENT_TIMESTAMP());

-- ── Reviews (6 rows — Q4 2025 cycle) ─────────────────────────────────────────
INSERT INTO HR_ANALYTICS_DEV.RAW.REVIEWS
    (REVIEW_ID, EMP_ID, REVIEW_DATE, RATING, COMMENTS, CREATED_AT)
VALUES
    (1,1001,'2025-12-15',5,'Exceptional technical leadership', CURRENT_TIMESTAMP()),
    (2,1002,'2025-12-15',4,'Strong contributor, growing fast', CURRENT_TIMESTAMP()),
    (3,1003,'2025-12-15',5,'Outstanding campaign results',     CURRENT_TIMESTAMP()),
    (4,1004,'2025-12-15',3,'Meets expectations, needs growth', CURRENT_TIMESTAMP()),
    (5,1005,'2025-12-15',4,'Solid HR operations management',   CURRENT_TIMESTAMP()),
    (6,1006,'2025-12-15',3,'Good start, first review cycle',   CURRENT_TIMESTAMP());
```

### 16-Point Test Suite

```sql
-- ── TEST 1: Database & schemas exist ─────────────────────────────────────────
SELECT SCHEMA_NAME, 'PASS' AS STATUS
FROM HR_ANALYTICS_DEV.INFORMATION_SCHEMA.SCHEMATA
WHERE SCHEMA_NAME IN ('RAW','CLEANSED','ANALYTICS','TESTS')
ORDER BY SCHEMA_NAME;

-- ── TEST 2: Tables exist with correct column counts ───────────────────────────
-- Expected: EMPLOYEES=8, DEPARTMENTS=4, PAYROLL=6, REVIEWS=6
SELECT TABLE_NAME, COUNT(*) AS COL_COUNT,
    CASE TABLE_NAME
        WHEN 'EMPLOYEES'   THEN CASE WHEN COUNT(*) = 8 THEN 'PASS' ELSE 'FAIL' END
        WHEN 'DEPARTMENTS' THEN CASE WHEN COUNT(*) = 4 THEN 'PASS' ELSE 'FAIL' END
        WHEN 'PAYROLL'     THEN CASE WHEN COUNT(*) = 6 THEN 'PASS' ELSE 'FAIL' END
        WHEN 'REVIEWS'     THEN CASE WHEN COUNT(*) = 6 THEN 'PASS' ELSE 'FAIL' END
    END AS STATUS
FROM HR_ANALYTICS_DEV.INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'RAW'
  AND TABLE_NAME IN ('EMPLOYEES','DEPARTMENTS','PAYROLL','REVIEWS')
GROUP BY TABLE_NAME ORDER BY TABLE_NAME;

-- ── TEST 3: Row counts after insert ──────────────────────────────────────────
SELECT 'DEPARTMENTS' AS TBL, COUNT(*) AS ROW_CNT,
       CASE WHEN COUNT(*) = 4 THEN 'PASS' ELSE 'FAIL' END AS STATUS
FROM HR_ANALYTICS_DEV.RAW.DEPARTMENTS
UNION ALL
SELECT 'EMPLOYEES', COUNT(*), CASE WHEN COUNT(*) = 6 THEN 'PASS' ELSE 'FAIL' END
FROM HR_ANALYTICS_DEV.RAW.EMPLOYEES
UNION ALL
SELECT 'PAYROLL',   COUNT(*), CASE WHEN COUNT(*) = 6 THEN 'PASS' ELSE 'FAIL' END
FROM HR_ANALYTICS_DEV.RAW.PAYROLL
UNION ALL
SELECT 'REVIEWS',   COUNT(*), CASE WHEN COUNT(*) = 6 THEN 'PASS' ELSE 'FAIL' END
FROM HR_ANALYTICS_DEV.RAW.REVIEWS;

-- ── TEST 4: Warehouse exists ──────────────────────────────────────────────────
SHOW WAREHOUSES LIKE 'HR_ANALYTICS_WH_DEV';

-- ── TEST 5: Internal stage exists ────────────────────────────────────────────
SHOW STAGES IN SCHEMA HR_ANALYTICS_DEV.RAW;

-- ── TEST 6: Roles & database roles exist ─────────────────────────────────────
SHOW ROLES LIKE 'HR_ANALYTICS_%_DEV';
SHOW DATABASE ROLES IN DATABASE HR_ANALYTICS_DEV;

-- ── TEST 7: SQL functions return correct values ───────────────────────────────
SELECT
    HR_ANALYTICS_DEV.ANALYTICS.GET_PERFORMANCE_BAND(5) AS BAND_OUTSTANDING,
    HR_ANALYTICS_DEV.ANALYTICS.GET_PERFORMANCE_BAND(4) AS BAND_EXCEEDS,
    HR_ANALYTICS_DEV.ANALYTICS.GET_PERFORMANCE_BAND(3) AS BAND_MEETS,
    HR_ANALYTICS_DEV.ANALYTICS.GET_PERFORMANCE_BAND(2) AS BAND_BELOW,
    HR_ANALYTICS_DEV.ANALYTICS.GET_PERFORMANCE_BAND(1) AS BAND_CRITICAL,
    HR_ANALYTICS_DEV.ANALYTICS.GET_MIN_SALARY_THRESHOLD() AS MIN_SALARY,
    HR_ANALYTICS_DEV.ANALYTICS.FORMAT_SALARY(145000)       AS FORMATTED_SAL;

-- ── TEST 8: Dynamic tables — manual refresh + row counts ─────────────────────
ALTER DYNAMIC TABLE HR_ANALYTICS_DEV.CLEANSED.EMPLOYEES_CLEAN  REFRESH;
ALTER DYNAMIC TABLE HR_ANALYTICS_DEV.CLEANSED.PAYROLL_CLEAN    REFRESH;
ALTER DYNAMIC TABLE HR_ANALYTICS_DEV.ANALYTICS.DEPT_HEADCOUNT  REFRESH;
ALTER DYNAMIC TABLE HR_ANALYTICS_DEV.ANALYTICS.PAYROLL_SUMMARY REFRESH;

SELECT 'EMPLOYEES_CLEAN'  AS DT, COUNT(*) AS ROW_CNT,
       CASE WHEN COUNT(*) = 6 THEN 'PASS' ELSE 'FAIL' END AS STATUS
FROM HR_ANALYTICS_DEV.CLEANSED.EMPLOYEES_CLEAN
UNION ALL
SELECT 'PAYROLL_CLEAN',   COUNT(*), CASE WHEN COUNT(*) = 6 THEN 'PASS' ELSE 'FAIL' END
FROM HR_ANALYTICS_DEV.CLEANSED.PAYROLL_CLEAN
UNION ALL
SELECT 'DEPT_HEADCOUNT',  COUNT(*), CASE WHEN COUNT(*) = 4 THEN 'PASS' ELSE 'FAIL' END
FROM HR_ANALYTICS_DEV.ANALYTICS.DEPT_HEADCOUNT
UNION ALL
SELECT 'PAYROLL_SUMMARY', COUNT(*), CASE WHEN COUNT(*) = 4 THEN 'PASS' ELSE 'FAIL' END
FROM HR_ANALYTICS_DEV.ANALYTICS.PAYROLL_SUMMARY;

-- ── TEST 9: Views & secure views return data ──────────────────────────────────
SELECT 'VW_ACTIVE_EMPLOYEES'  AS VIEW_NAME, COUNT(*) AS ROW_CNT,
       CASE WHEN COUNT(*) >= 1 THEN 'PASS' ELSE 'FAIL' END AS STATUS
FROM HR_ANALYTICS_DEV.ANALYTICS.VW_ACTIVE_EMPLOYEES
UNION ALL
SELECT 'VW_TOP_PERFORMERS',   COUNT(*), CASE WHEN COUNT(*) >= 1 THEN 'PASS' ELSE 'FAIL' END
FROM HR_ANALYTICS_DEV.ANALYTICS.VW_TOP_PERFORMERS
UNION ALL
SELECT 'VW_PAYROLL_OVERVIEW', COUNT(*), CASE WHEN COUNT(*) >= 1 THEN 'PASS' ELSE 'FAIL' END
FROM HR_ANALYTICS_DEV.ANALYTICS.VW_PAYROLL_OVERVIEW
UNION ALL
SELECT 'VW_SALARY_BANDS',     COUNT(*), CASE WHEN COUNT(*) >= 0 THEN 'PASS' ELSE 'FAIL' END
FROM HR_ANALYTICS_DEV.ANALYTICS.VW_SALARY_BANDS;

-- ── TEST 10: Tasks exist (suspended by default) ───────────────────────────────
SHOW TASKS IN SCHEMA HR_ANALYTICS_DEV.RAW;

-- ── TEST 11: Tags exist with correct allowed values ───────────────────────────
SHOW TAGS IN SCHEMA HR_ANALYTICS_DEV.RAW;
SELECT SYSTEM$GET_TAG_ALLOWED_VALUES('HR_ANALYTICS_DEV.RAW.PII_LEVEL')   AS PII_VALUES;
SELECT SYSTEM$GET_TAG_ALLOWED_VALUES('HR_ANALYTICS_DEV.RAW.COST_CENTER') AS CC_VALUES;
SELECT SYSTEM$GET_TAG_ALLOWED_VALUES('HR_ANALYTICS_DEV.RAW.DATA_DOMAIN') AS DOMAIN_VALUES;

-- ── TEST 12: Authentication policies exist ────────────────────────────────────
SHOW AUTHENTICATION POLICIES IN SCHEMA HR_ANALYTICS_DEV.RAW;

-- ── TEST 13: User-defined DMFs exist ─────────────────────────────────────────
SHOW DATA METRIC FUNCTIONS IN SCHEMA HR_ANALYTICS_DEV.TESTS;

-- ── TEST 14: Grant verification ───────────────────────────────────────────────
SHOW GRANTS TO ROLE HR_ANALYTICS_READER_DEV;
SHOW GRANTS TO ROLE HR_ANALYTICS_WRITER_DEV;
SHOW GRANTS TO ROLE HR_ANALYTICS_ADMIN_DEV;
SHOW GRANTS ON DATABASE  HR_ANALYTICS_DEV;
SHOW GRANTS ON WAREHOUSE HR_ANALYTICS_WH_DEV;

-- ── TEST 15: Data integrity spot checks ───────────────────────────────────────
SELECT 'UPPER TRANSFORM' AS CHECK_NAME,
    CASE WHEN FIRST_NAME = 'PRIYA' AND EMAIL = 'priya.sharma@corp.com'
         THEN 'PASS' ELSE 'FAIL' END AS STATUS
FROM HR_ANALYTICS_DEV.CLEANSED.EMPLOYEES_CLEAN WHERE EMP_ID = 1001
UNION ALL
SELECT 'DEPT HEADCOUNT',
    CASE WHEN HEADCOUNT = 3 THEN 'PASS' ELSE 'FAIL' END
FROM HR_ANALYTICS_DEV.ANALYTICS.DEPT_HEADCOUNT WHERE DEPT_NAME = 'ENGINEERING'
UNION ALL
SELECT 'PAYROLL SUMMARY',
    CASE WHEN EMPLOYEE_COUNT = 3 THEN 'PASS' ELSE 'FAIL' END
FROM HR_ANALYTICS_DEV.ANALYTICS.PAYROLL_SUMMARY WHERE DEPT_NAME = 'ENGINEERING'
UNION ALL
SELECT 'TOP PERFORMER BAND',
    CASE WHEN PERFORMANCE_BAND = 'OUTSTANDING' THEN 'PASS' ELSE 'FAIL' END
FROM HR_ANALYTICS_DEV.ANALYTICS.VW_TOP_PERFORMERS WHERE EMP_ID = 1001;

-- ── TEST 16: Net pay calculation accuracy ─────────────────────────────────────
SELECT 'NET PAY CALC' AS CHECK_NAME,
    CASE WHEN NET_PAY = GROSS_PAY - DEDUCTIONS THEN 'PASS' ELSE 'FAIL' END AS STATUS
FROM HR_ANALYTICS_DEV.CLEANSED.PAYROLL_CLEAN
WHERE EMP_ID = 1001;
```

---

## ✅ Phase 5 — DCM Data Quality Expectations

```sql
-- ============================================================================
-- PHASE 5: DCM DATA QUALITY EXPECTATIONS
-- Runs all 11 expectations defined in 08_data_quality.sql in one command.
-- ============================================================================

EXECUTE DCM PROJECT HR_DCM_ADMIN.PROJECTS.HR_PROJECT_DEV TEST ALL;

-- ── Parse results into a readable table ──────────────────────────────────────
WITH raw AS (
    SELECT "result"::VARIANT AS res
    FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()))
)
SELECT
    f.value:table_name::STRING        AS TABLE_NAME,
    f.value:metric_name::STRING       AS METRIC,
    f.value:expectation_name::STRING  AS EXPECTATION,
    f.value:value::STRING             AS VALUE,
    f.value:expectation_violated::BOOLEAN AS VIOLATED
FROM raw,
LATERAL FLATTEN(input => res:expectations) f
ORDER BY VIOLATED DESC, TABLE_NAME;

-- ── Full project introspection ────────────────────────────────────────────────
SHOW ENTITIES IN DCM PROJECT HR_DCM_ADMIN.PROJECTS.HR_PROJECT_DEV;
SHOW GRANTS   IN DCM PROJECT HR_DCM_ADMIN.PROJECTS.HR_PROJECT_DEV;

-- ── Deployment history ────────────────────────────────────────────────────────
SHOW DEPLOYMENTS IN DCM PROJECT HR_DCM_ADMIN.PROJECTS.HR_PROJECT_DEV;

SELECT *
FROM TABLE(INFORMATION_SCHEMA.DCM_DEPLOYMENT_HISTORY(
    PROJECT_NAME => 'HR_DCM_ADMIN.PROJECTS.HR_PROJECT_DEV'
));
```

---

## 📊 Supported Object Types Reference

| Object Type | DEFINE | GRANT | ATTACH | Key Constraints |
|-------------|:------:|:-----:|:------:|-----------------|
| Database | ✅ | ✅ | — | Rename not supported |
| Schema | ✅ | ✅ | — | Rename not supported |
| Table | ✅ | ✅ | — | No rename / column reorder |
| Dynamic Table | ✅ | ✅ | — | Body change = full refresh · `INITIALIZE` immutable |
| View / Secure View | ✅ | ✅ | — | No rename / column reorder |
| Internal Stage | ✅ | ✅ | — | Encryption type immutable |
| Warehouse | ✅ | ✅ | — | `INITIALLY_SUSPENDED` immutable |
| Role / DB Role | ✅ | ✅ | — | No Application Role |
| Grant | — | ✅ | — | No APP ROLE / CALLER grants |
| Data Metric Function | ✅ | — | ✅ | DMFs without `EXPECTATION` skipped by `TEST ALL` |
| Task | ✅ | ✅ | — | New tasks always start **SUSPENDED** |
| SQL Function | ✅ | — | — | `CREATE OR ALTER` limits apply |
| Tag | ✅ | — | — | No `PROPAGATE` · no column attachments in DCM |
| Authentication Policy | ✅ | — | — | |

### ❌ Not Supported in DCM (Manage Manually)

```
Masking Policies        Row Access Policies     Column-level Tag Attachments
Streams                 Pipes                   Stored Procedures
External Stages         Network Policies        Alerts
```

---

## 📌 Key Rules

| # | Rule |
|---|------|
| **1** | **Order doesn't matter** — `DEFINE` order across all 9 files is irrelevant. Snowflake resolves dependencies automatically. |
| **2** | **Removal = DROP** — Deleting a `DEFINE`, `GRANT`, or `ATTACH` drops that object on the next deploy. Always review `PLAN` first. |
| **3** | **Fully qualified names everywhere** — Every reference must be `database.schema.object`. |
| **4** | **Account-level grants required** — DCM needs `GRANT CREATE DATABASE / WAREHOUSE / ROLE ON ACCOUNT` to deploy infrastructure objects. |
| **5** | **`DATA_METRIC_SCHEDULE` required** — Must be set on any table that will have DMFs attached. Without it, `ATTACH` fails at deploy time. |
| **6** | **External grants coexist** — Grants applied outside DCM are not removed by subsequent DCM deploys. |
| **7** | **Tasks always suspended** — Every new or modified task must be manually resumed after deploy. |
| **8** | **DMFs need expectations** — `ATTACH` without an `EXPECTATION` clause is silently skipped by `TEST ALL`. |

---

## 🔗 Resources

- 📖 [Full Medium Article](https://medium.com/@snowflakechronicles)
- ❄️ [Snowflake DCM Projects Documentation](https://docs.snowflake.com)
- 🐙 [GitLab Repository](https://gitlab.com)

---

## 👏 Found This Useful?

If this notebook saved you time, please consider:

**📖 Read the full article on Medium** → [@snowflakechronicles](https://medium.com/@snowflakechronicles)
**👏 Clap on Medium** — helps more engineers find it (up to 50 claps!)
**⭐ Star this repository** — it means a lot
**🔔 Follow on Medium** — new Snowflake deep-dives every week
**🔗 Share** with your data engineering team

---

*Satish Kumar | Medium | @snowflakechronicles*
*Snowflake Data Cloud Management — Preview Feature*
*HR Analytics Platform — DEV / STG / PROD*

---

### Tags
`#Snowflake` `#DataEngineering` `#InfrastructureAsCode` `#DCMProjects`
`#SnowflakeDCM` `#HRAnalytics` `#DataOps` `#GitOps` `#MedallionArchitecture`
`#DynamicTables` `#DataQuality` `#DataMetricFunctions` `#Jinja`
`#CloudDataWarehouse` `#SnowflakeSQL` `#Analytics` `#DataGovernance`
`#ETL` `#SoftwareDevelopment` `#GitLab`
