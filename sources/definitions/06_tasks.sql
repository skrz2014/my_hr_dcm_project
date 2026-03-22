-- 06_tasks.sql — Scheduled data ingestion tasks

DEFINE TASK HR_ANALYTICS_{{env}}.RAW.LOAD_EMPLOYEES_TASK
    WAREHOUSE = HR_ANALYTICS_WH_{{env}}
    SCHEDULE = 'USING CRON 0 2 * * * America/New_York'
    COMMENT = 'Load employees from stage daily at 2 AM'
AS
    COPY INTO HR_ANALYTICS_{{env}}.RAW.EMPLOYEES
    FROM @HR_ANALYTICS_{{env}}.RAW.HR_LOAD_STAGE/employees/
    FILE_FORMAT = (TYPE = 'CSV' SKIP_HEADER = 1);

DEFINE TASK HR_ANALYTICS_{{env}}.RAW.LOAD_PAYROLL_TASK
    WAREHOUSE = HR_ANALYTICS_WH_{{env}}
    SCHEDULE = 'USING CRON 0 3 1,15 * * America/New_York'
    COMMENT = 'Load payroll on 1st and 15th of each month'
AS
    COPY INTO HR_ANALYTICS_{{env}}.RAW.PAYROLL
    FROM @HR_ANALYTICS_{{env}}.RAW.HR_LOAD_STAGE/payroll/
    FILE_FORMAT = (TYPE = 'CSV' SKIP_HEADER = 1);

DEFINE TASK HR_ANALYTICS_{{env}}.RAW.LOAD_REVIEWS_TASK
    WAREHOUSE = HR_ANALYTICS_WH_{{env}}
    SCHEDULE = 'USING CRON 0 4 * * 1 America/New_York'
    COMMENT = 'Load reviews weekly on Monday at 4 AM'
AS
    COPY INTO HR_ANALYTICS_{{env}}.RAW.REVIEWS
    FROM @HR_ANALYTICS_{{env}}.RAW.HR_LOAD_STAGE/reviews/
    FILE_FORMAT = (TYPE = 'CSV' SKIP_HEADER = 1);
