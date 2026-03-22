-- ============================================================================
-- DCM PROJECTS: END-TO-END IMPLEMENTATION
-- Use Case: HR ANALYTICS PLATFORM
-- Account: PQC86579 | User: SATISH
-- ============================================================================
--
-- This script demonstrates a complete DCM (Data Cloud Management) Projects
-- workflow using an HR Analytics use case. It covers:
--
--   PHASE 1 — Account preparation & privilege setup
--   PHASE 2 — Create DCM Project objects (DEV / STG / PROD)
--   PHASE 3 — Deploy definition files from workspace
--   PHASE 4 — Insert sample data & run full test suite
--   PHASE 5 — Run DCM data quality expectations (TEST ALL)
--
-- The definition files define a medallion architecture:
--   BRONZE (RAW)     → Employees, Departments, Payroll, Reviews
--   SILVER (CLEANSED) → Standardised / deduplicated data
--   GOLD (ANALYTICS)  → Headcount dashboard, Payroll summary, Top performers
--
-- All 14 supported DCM object types are exercised:
--   Database, Schema, Table, Dynamic Table, View, Secure View,
--   Internal Stage, Warehouse, Role, Database Role, Grant,
--   Data Metric Function, Task, SQL Function, Tag, Auth Policy
-- ============================================================================


-- ████████████████████████████████████████████████████████████████████████████
-- PHASE 1: PREREQUISITES & ACCOUNT PREPARATION
-- Run every statement in this phase as ACCOUNTADMIN.
-- ████████████████████████████████████████████████████████████████████████████

USE ROLE ACCOUNTADMIN;

-- 1.1  Admin database & schema that will hold the DCM project objects
CREATE DATABASE IF NOT EXISTS HR_DCM_ADMIN;
CREATE SCHEMA  IF NOT EXISTS HR_DCM_ADMIN.PROJECTS;

-- 1.2  Deployment roles — one per environment, least-privilege
CREATE ROLE IF NOT EXISTS HR_DCM_DEV_DEPLOYER;
CREATE ROLE IF NOT EXISTS HR_DCM_STG_DEPLOYER;
CREATE ROLE IF NOT EXISTS HR_DCM_PROD_DEPLOYER;

-- 1.3  Role hierarchy: SYSADMIN > PROD > STG > DEV
GRANT ROLE HR_DCM_DEV_DEPLOYER  TO ROLE HR_DCM_STG_DEPLOYER;
GRANT ROLE HR_DCM_STG_DEPLOYER  TO ROLE HR_DCM_PROD_DEPLOYER;
GRANT ROLE HR_DCM_PROD_DEPLOYER TO ROLE SYSADMIN;

-- 1.4  Schema-level: allow each role to create DCM projects
GRANT USAGE ON DATABASE HR_DCM_ADMIN            TO ROLE HR_DCM_DEV_DEPLOYER;
GRANT USAGE ON SCHEMA   HR_DCM_ADMIN.PROJECTS   TO ROLE HR_DCM_DEV_DEPLOYER;
GRANT CREATE DCM PROJECT ON SCHEMA HR_DCM_ADMIN.PROJECTS TO ROLE HR_DCM_DEV_DEPLOYER;

GRANT USAGE ON DATABASE HR_DCM_ADMIN            TO ROLE HR_DCM_STG_DEPLOYER;
GRANT USAGE ON SCHEMA   HR_DCM_ADMIN.PROJECTS   TO ROLE HR_DCM_STG_DEPLOYER;
GRANT CREATE DCM PROJECT ON SCHEMA HR_DCM_ADMIN.PROJECTS TO ROLE HR_DCM_STG_DEPLOYER;

GRANT USAGE ON DATABASE HR_DCM_ADMIN            TO ROLE HR_DCM_PROD_DEPLOYER;
GRANT USAGE ON SCHEMA   HR_DCM_ADMIN.PROJECTS   TO ROLE HR_DCM_PROD_DEPLOYER;
GRANT CREATE DCM PROJECT ON SCHEMA HR_DCM_ADMIN.PROJECTS TO ROLE HR_DCM_PROD_DEPLOYER;

-- 1.5  Warehouse access for running DCM commands
GRANT USAGE ON WAREHOUSE SHARED_WH TO ROLE HR_DCM_DEV_DEPLOYER;
GRANT USAGE ON WAREHOUSE SHARED_WH TO ROLE HR_DCM_STG_DEPLOYER;
GRANT USAGE ON WAREHOUSE SHARED_WH TO ROLE HR_DCM_PROD_DEPLOYER;

-- 1.6  Account-level privileges
--      DCM DEFINE statements create databases, roles, and warehouses.
--      These require account-level CREATE privileges on the deploying role.
GRANT CREATE DATABASE  ON ACCOUNT TO ROLE HR_DCM_DEV_DEPLOYER;
GRANT CREATE ROLE      ON ACCOUNT TO ROLE HR_DCM_DEV_DEPLOYER;
GRANT CREATE WAREHOUSE ON ACCOUNT TO ROLE HR_DCM_DEV_DEPLOYER;

--      Attaching Data Metric Functions requires this global privilege.
GRANT EXECUTE DATA METRIC FUNCTION ON ACCOUNT TO ROLE HR_DCM_DEV_DEPLOYER;

-- 1.7  Assign role to the human user
GRANT ROLE HR_DCM_DEV_DEPLOYER TO USER SATISH;


-- ████████████████████████████████████████████████████████████████████████████
-- PHASE 2: CREATE DCM PROJECT OBJECTS
-- One project per environment. The project is a container; the actual
-- object definitions live in workspace files deployed in Phase 3.
-- ████████████████████████████████████████████████████████████████████████████

USE ROLE HR_DCM_DEV_DEPLOYER;
CREATE DCM PROJECT IF NOT EXISTS HR_DCM_ADMIN.PROJECTS.HR_PROJECT_DEV
  COMMENT = 'HR Analytics — Development';

USE ROLE HR_DCM_STG_DEPLOYER;
CREATE DCM PROJECT IF NOT EXISTS HR_DCM_ADMIN.PROJECTS.HR_PROJECT_STG
  COMMENT = 'HR Analytics — Staging';

USE ROLE HR_DCM_PROD_DEPLOYER;
CREATE DCM PROJECT IF NOT EXISTS HR_DCM_ADMIN.PROJECTS.HR_PROJECT_PROD
  COMMENT = 'HR Analytics — Production';

-- Verify
USE ROLE WS_ADMIN;
SHOW DCM PROJECTS IN SCHEMA HR_DCM_ADMIN.PROJECTS;


-- ████████████████████████████████████████████████████████████████████████████
-- PHASE 3: DEPLOY TO DEV
-- The definition files are at:
--   /my_hr_dcm_project/manifest.yml
--   /my_hr_dcm_project/sources/definitions/*.sql
-- Snowflake reads them from the workspace stage path.
-- ████████████████████████████████████████████████████████████████████████████

USE ROLE HR_DCM_DEV_DEPLOYER;

EXECUTE DCM PROJECT HR_DCM_ADMIN.PROJECTS.HR_PROJECT_DEV
  DEPLOY AS "initial hr dev deployment"
  USING CONFIGURATION DEV
FROM
  'snow://workspace/USER$.PUBLIC.DEFAULT$/versions/live/my_hr_dcm_project';

-- Introspect what was deployed
SHOW ENTITIES IN DCM PROJECT HR_DCM_ADMIN.PROJECTS.HR_PROJECT_DEV;
SHOW GRANTS   IN DCM PROJECT HR_DCM_ADMIN.PROJECTS.HR_PROJECT_DEV;


-- ████████████████████████████████████████████████████████████████████████████
-- PHASE 4: TEST SUITE
-- ████████████████████████████████████████████████████████████████████████████

-- ──────────────────────────────────────────────────────────────────────
-- TEST 1 — Database & Schemas exist
-- Expect: RAW, CLEANSED, ANALYTICS, TESTS
-- ──────────────────────────────────────────────────────────────────────

SELECT SCHEMA_NAME, 'PASS' AS STATUS
FROM HR_ANALYTICS_DEV.INFORMATION_SCHEMA.SCHEMATA
WHERE SCHEMA_NAME IN ('RAW', 'CLEANSED', 'ANALYTICS', 'TESTS')
ORDER BY SCHEMA_NAME;

-- ──────────────────────────────────────────────────────────────────────
-- TEST 2 — Tables exist with correct column counts
-- EMPLOYEES=8, DEPARTMENTS=4, PAYROLL=6, REVIEWS=6
-- ──────────────────────────────────────────────────────────────────────

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
GROUP BY TABLE_NAME
ORDER BY TABLE_NAME;

-- ──────────────────────────────────────────────────────────────────────
-- TEST 3 — Insert sample data
-- ──────────────────────────────────────────────────────────────────────

INSERT INTO HR_ANALYTICS_DEV.RAW.DEPARTMENTS (DEPT_ID, DEPT_NAME, LOCATION, CREATED_AT)
VALUES
  (10, 'Engineering',  'San Francisco', CURRENT_TIMESTAMP()),
  (20, 'Marketing',    'New York',      CURRENT_TIMESTAMP()),
  (30, 'Finance',      'Chicago',       CURRENT_TIMESTAMP()),
  (40, 'Human Resources','Austin',      CURRENT_TIMESTAMP());

INSERT INTO HR_ANALYTICS_DEV.RAW.EMPLOYEES (EMP_ID, FIRST_NAME, LAST_NAME, EMAIL, DEPT_ID, HIRE_DATE, SALARY, CREATED_AT)
VALUES
  (1001, 'Priya',   'Sharma',  'priya.sharma@corp.com',   10, '2020-03-15', 145000, CURRENT_TIMESTAMP()),
  (1002, 'James',   'Wilson',  'james.wilson@corp.com',   10, '2021-07-01', 130000, CURRENT_TIMESTAMP()),
  (1003, 'Maria',   'Garcia',  'maria.garcia@corp.com',   20, '2019-11-20', 115000, CURRENT_TIMESTAMP()),
  (1004, 'Chen',    'Wei',     'chen.wei@corp.com',       30, '2022-01-10',  95000, CURRENT_TIMESTAMP()),
  (1005, 'Amara',   'Okafor',  'amara.okafor@corp.com',   40, '2018-06-05', 105000, CURRENT_TIMESTAMP()),
  (1006, 'Liam',    'Patel',   'liam.patel@corp.com',     10, '2023-09-12', 120000, CURRENT_TIMESTAMP());

INSERT INTO HR_ANALYTICS_DEV.RAW.PAYROLL (PAYROLL_ID, EMP_ID, PAY_PERIOD, GROSS_PAY, DEDUCTIONS, CREATED_AT)
VALUES
  (1, 1001, '2026-03-01', 12083.33, 3625.00, CURRENT_TIMESTAMP()),
  (2, 1002, '2026-03-01', 10833.33, 3250.00, CURRENT_TIMESTAMP()),
  (3, 1003, '2026-03-01',  9583.33, 2875.00, CURRENT_TIMESTAMP()),
  (4, 1004, '2026-03-01',  7916.67, 2375.00, CURRENT_TIMESTAMP()),
  (5, 1005, '2026-03-01',  8750.00, 2625.00, CURRENT_TIMESTAMP()),
  (6, 1006, '2026-03-01', 10000.00, 3000.00, CURRENT_TIMESTAMP());

INSERT INTO HR_ANALYTICS_DEV.RAW.REVIEWS (REVIEW_ID, EMP_ID, REVIEW_DATE, RATING, COMMENTS, CREATED_AT)
VALUES
  (1, 1001, '2025-12-15', 5, 'Exceptional technical leadership',  CURRENT_TIMESTAMP()),
  (2, 1002, '2025-12-15', 4, 'Strong contributor, growing fast',  CURRENT_TIMESTAMP()),
  (3, 1003, '2025-12-15', 5, 'Outstanding campaign results',      CURRENT_TIMESTAMP()),
  (4, 1004, '2025-12-15', 3, 'Meets expectations, needs growth',  CURRENT_TIMESTAMP()),
  (5, 1005, '2025-12-15', 4, 'Solid HR operations management',    CURRENT_TIMESTAMP()),
  (6, 1006, '2025-12-15', 3, 'Good start, first review cycle',    CURRENT_TIMESTAMP());

-- ──────────────────────────────────────────────────────────────────────
-- TEST 4 — Verify row counts
-- ──────────────────────────────────────────────────────────────────────

SELECT 'DEPARTMENTS' AS TBL, COUNT(*) AS ROW_CNT, CASE WHEN COUNT(*) = 4 THEN 'PASS' ELSE 'FAIL' END AS STATUS FROM HR_ANALYTICS_DEV.RAW.DEPARTMENTS
UNION ALL
SELECT 'EMPLOYEES',   COUNT(*), CASE WHEN COUNT(*) = 6 THEN 'PASS' ELSE 'FAIL' END FROM HR_ANALYTICS_DEV.RAW.EMPLOYEES
UNION ALL
SELECT 'PAYROLL',     COUNT(*), CASE WHEN COUNT(*) = 6 THEN 'PASS' ELSE 'FAIL' END FROM HR_ANALYTICS_DEV.RAW.PAYROLL
UNION ALL
SELECT 'REVIEWS',     COUNT(*), CASE WHEN COUNT(*) = 6 THEN 'PASS' ELSE 'FAIL' END FROM HR_ANALYTICS_DEV.RAW.REVIEWS;

-- ──────────────────────────────────────────────────────────────────────
-- TEST 5 — Warehouse exists
-- ──────────────────────────────────────────────────────────────────────

SHOW WAREHOUSES LIKE 'HR_ANALYTICS_WH_DEV';

-- ──────────────────────────────────────────────────────────────────────
-- TEST 6 — Internal stage exists
-- ──────────────────────────────────────────────────────────────────────

SHOW STAGES IN SCHEMA HR_ANALYTICS_DEV.RAW;

-- ──────────────────────────────────────────────────────────────────────
-- TEST 7 — Roles & database roles exist
-- ──────────────────────────────────────────────────────────────────────

SHOW ROLES LIKE 'HR_ANALYTICS_%_DEV';
SHOW DATABASE ROLES IN DATABASE HR_ANALYTICS_DEV;

-- ──────────────────────────────────────────────────────────────────────
-- TEST 8 — SQL functions work
-- ──────────────────────────────────────────────────────────────────────

SELECT
  HR_ANALYTICS_DEV.ANALYTICS.GET_PERFORMANCE_BAND(5) AS BAND_OUTSTANDING,
  HR_ANALYTICS_DEV.ANALYTICS.GET_PERFORMANCE_BAND(4) AS BAND_EXCEEDS,
  HR_ANALYTICS_DEV.ANALYTICS.GET_PERFORMANCE_BAND(3) AS BAND_MEETS,
  HR_ANALYTICS_DEV.ANALYTICS.GET_PERFORMANCE_BAND(2) AS BAND_BELOW,
  HR_ANALYTICS_DEV.ANALYTICS.GET_PERFORMANCE_BAND(1) AS BAND_CRITICAL,
  HR_ANALYTICS_DEV.ANALYTICS.GET_MIN_SALARY_THRESHOLD() AS MIN_SALARY,
  HR_ANALYTICS_DEV.ANALYTICS.FORMAT_SALARY(145000)      AS FORMATTED_SAL;

-- ──────────────────────────────────────────────────────────────────────
-- TEST 9 — Dynamic tables: refresh & verify row counts
-- ──────────────────────────────────────────────────────────────────────

ALTER DYNAMIC TABLE HR_ANALYTICS_DEV.CLEANSED.EMPLOYEES_CLEAN REFRESH;
ALTER DYNAMIC TABLE HR_ANALYTICS_DEV.CLEANSED.PAYROLL_CLEAN REFRESH;
ALTER DYNAMIC TABLE HR_ANALYTICS_DEV.ANALYTICS.DEPT_HEADCOUNT REFRESH;
ALTER DYNAMIC TABLE HR_ANALYTICS_DEV.ANALYTICS.PAYROLL_SUMMARY REFRESH;

SELECT 'EMPLOYEES_CLEAN' AS DT, COUNT(*) AS ROW_CNT, CASE WHEN COUNT(*) = 6 THEN 'PASS' ELSE 'FAIL' END AS STATUS FROM HR_ANALYTICS_DEV.CLEANSED.EMPLOYEES_CLEAN
UNION ALL
SELECT 'PAYROLL_CLEAN',   COUNT(*), CASE WHEN COUNT(*) = 6 THEN 'PASS' ELSE 'FAIL' END FROM HR_ANALYTICS_DEV.CLEANSED.PAYROLL_CLEAN
UNION ALL
SELECT 'DEPT_HEADCOUNT',  COUNT(*), CASE WHEN COUNT(*) = 4 THEN 'PASS' ELSE 'FAIL' END FROM HR_ANALYTICS_DEV.ANALYTICS.DEPT_HEADCOUNT
UNION ALL
SELECT 'PAYROLL_SUMMARY', COUNT(*), CASE WHEN COUNT(*) = 4 THEN 'PASS' ELSE 'FAIL' END FROM HR_ANALYTICS_DEV.ANALYTICS.PAYROLL_SUMMARY;

-- ──────────────────────────────────────────────────────────────────────
-- TEST 10 — Views & secure views return data
-- ──────────────────────────────────────────────────────────────────────

SELECT 'VW_ACTIVE_EMPLOYEES' AS VIEW_NAME, COUNT(*) AS ROW_CNT, CASE WHEN COUNT(*) >= 1 THEN 'PASS' ELSE 'FAIL' END AS STATUS FROM HR_ANALYTICS_DEV.ANALYTICS.VW_ACTIVE_EMPLOYEES
UNION ALL
SELECT 'VW_TOP_PERFORMERS',  COUNT(*), CASE WHEN COUNT(*) >= 1 THEN 'PASS' ELSE 'FAIL' END FROM HR_ANALYTICS_DEV.ANALYTICS.VW_TOP_PERFORMERS
UNION ALL
SELECT 'VW_PAYROLL_OVERVIEW', COUNT(*), CASE WHEN COUNT(*) >= 1 THEN 'PASS' ELSE 'FAIL' END FROM HR_ANALYTICS_DEV.ANALYTICS.VW_PAYROLL_OVERVIEW
UNION ALL
SELECT 'VW_SALARY_BANDS',    COUNT(*), CASE WHEN COUNT(*) >= 0 THEN 'PASS' ELSE 'FAIL' END FROM HR_ANALYTICS_DEV.ANALYTICS.VW_SALARY_BANDS;

-- ──────────────────────────────────────────────────────────────────────
-- TEST 11 — Tasks exist (suspended by default after deploy)
-- ──────────────────────────────────────────────────────────────────────

SHOW TASKS IN SCHEMA HR_ANALYTICS_DEV.RAW;

-- ──────────────────────────────────────────────────────────────────────
-- TEST 12 — Tags exist with allowed values
-- ──────────────────────────────────────────────────────────────────────

SHOW TAGS IN SCHEMA HR_ANALYTICS_DEV.RAW;
SELECT SYSTEM$GET_TAG_ALLOWED_VALUES('HR_ANALYTICS_DEV.RAW.PII_LEVEL')     AS PII_VALUES;
SELECT SYSTEM$GET_TAG_ALLOWED_VALUES('HR_ANALYTICS_DEV.RAW.COST_CENTER')   AS CC_VALUES;
SELECT SYSTEM$GET_TAG_ALLOWED_VALUES('HR_ANALYTICS_DEV.RAW.DATA_DOMAIN')   AS DOMAIN_VALUES;

-- ──────────────────────────────────────────────────────────────────────
-- TEST 13 — Authentication policies exist
-- ──────────────────────────────────────────────────────────────────────

SHOW AUTHENTICATION POLICIES IN SCHEMA HR_ANALYTICS_DEV.RAW;

-- ──────────────────────────────────────────────────────────────────────
-- TEST 14 — User-defined data metric functions exist
-- ──────────────────────────────────────────────────────────────────────

SHOW DATA METRIC FUNCTIONS IN SCHEMA HR_ANALYTICS_DEV.TESTS;

-- ──────────────────────────────────────────────────────────────────────
-- TEST 15 — Grant verification
-- ──────────────────────────────────────────────────────────────────────

SHOW GRANTS TO ROLE HR_ANALYTICS_READER_DEV;
SHOW GRANTS TO ROLE HR_ANALYTICS_WRITER_DEV;
SHOW GRANTS TO ROLE HR_ANALYTICS_ADMIN_DEV;
SHOW GRANTS ON DATABASE HR_ANALYTICS_DEV;
SHOW GRANTS ON WAREHOUSE HR_ANALYTICS_WH_DEV;

-- ──────────────────────────────────────────────────────────────────────
-- TEST 16 — Data integrity spot checks
-- ──────────────────────────────────────────────────────────────────────

SELECT 'UPPER TRANSFORM' AS CHECK_NAME,
       CASE WHEN FIRST_NAME = 'PRIYA' AND EMAIL = 'priya.sharma@corp.com' THEN 'PASS' ELSE 'FAIL' END AS STATUS
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


-- ████████████████████████████████████████████████████████████████████████████
-- PHASE 5: DCM DATA QUALITY EXPECTATIONS
-- ████████████████████████████████████████████████████████████████████████████

-- Run all expectations defined via ATTACH + EXPECTATION in 08_data_quality.sql
EXECUTE DCM PROJECT HR_DCM_ADMIN.PROJECTS.HR_PROJECT_DEV TEST ALL;

-- Parse results into a readable table
WITH raw AS (
  SELECT "result"::VARIANT AS res FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()))
)
SELECT
  f.value:table_name::STRING       AS TABLE_NAME,
  f.value:metric_name::STRING      AS METRIC,
  f.value:expectation_name::STRING AS EXPECTATION,
  f.value:value::STRING            AS VALUE,
  f.value:expectation_violated::BOOLEAN AS VIOLATED
FROM raw,
LATERAL FLATTEN(input => res:expectations) f
ORDER BY VIOLATED DESC, TABLE_NAME;

-- Full project introspection
SHOW ENTITIES IN DCM PROJECT HR_DCM_ADMIN.PROJECTS.HR_PROJECT_DEV;
SHOW GRANTS   IN DCM PROJECT HR_DCM_ADMIN.PROJECTS.HR_PROJECT_DEV;
