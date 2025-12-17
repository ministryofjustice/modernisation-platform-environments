
SET enable_case_sensitive_identifier TO true;

DROP SCHEMA IF EXISTS yjaf_kpi_returns cascade;
CREATE EXTERNAL SCHEMA yjaf_kpi_returns FROM POSTGRES DATABASE 'yjaf' SCHEMA 'kpi_return' URI 'db-yjafrds01.test.yjaf' IAM_ROLE '${iam_role}' SECRET_ARN '${secret_arn}';
GRANT USAGE ON SCHEMA yjaf_kpi_returns TO GROUP yjb_ianda_team;
GRANT USAGE ON SCHEMA yjaf_kpi_returns TO "IAMR:redshift-serverless-yjb-reporting-moj_ap";

DROP SCHEMA IF EXISTS yjaf_refdata;
CREATE EXTERNAL SCHEMA yjaf_refdata FROM POSTGRES DATABASE 'yjaf' SCHEMA 'refdata' URI 'db-yjafrds01.test.yjaf' IAM_ROLE '${iam_role}' SECRET_ARN '${secret_arn}';
GRANT USAGE ON SCHEMA yjaf_refdata TO GROUP yjb_ianda_team;
GRANT USAGE ON SCHEMA yjaf_refdata TO "IAMR:redshift-serverless-yjb-reporting-moj_ap";

DROP SCHEMA IF EXISTS welsh_youth_justice_indicators;
CREATE EXTERNAL SCHEMA welsh_youth_justice_indicators FROM POSTGRES DATABASE "YJB_Summary_Reporting" SCHEMA 'yjb_summary_data_model' URI 'db-yjafrds01.test.yjaf' IAM_ROLE '${iam_role}' SECRET_ARN '${secret_arn}';
GRANT USAGE ON SCHEMA welsh_youth_justice_indicators TO GROUP yjb_ianda_team;

DROP SCHEMA IF EXISTS rds_ingest_ext;
--CREATE EXTERNAL SCHEMA rds_ingest_ext FROM POSTGRES DATABASE "YJB_Case_Reporting" SCHEMA 'redshift' URI 'db-yjafrds01.test.yjaf' IAM_ROLE '${iam_role}' SECRET_ARN '${secret_arn}';
--GRANT USAGE ON SCHEMA rds_ingest_ext TO GROUP yjb_ianda_team;

-- Preprod only
--DROP SCHEMA IF EXISTS yjb_case_reporting_stg_sam;
--CREATE EXTERNAL SCHEMA yjb_case_reporting_stg_sam FROM POSTGRES DATABASE 'YJB_Case_Reporting' SCHEMA 'stg' URI 'db-yjafrds01.test.yjaf' IAM_ROLE '${iam_role}' SECRET_ARN '${secret_arn}';
--GRANT USAGE ON SCHEMA yjb_case_reporting_stg_sam TO GROUP yjb_ianda_team;

SET enable_case_sensitive_identifier TO true;
DROP SCHEMA IF EXISTS yjb_case_reporting_stg cascade;
CREATE EXTERNAL SCHEMA yjb_case_reporting_stg FROM POSTGRES DATABASE "YJB_Case_Reporting" SCHEMA 'stg' URI 'db-yjafrds01.test.yjaf' IAM_ROLE '${iam_role}' SECRET_ARN '${secret_arn}';
GRANT USAGE ON SCHEMA yjb_case_reporting_stg TO GROUP yjb_ianda_team;
GRANT USAGE ON SCHEMA yjb_case_reporting_stg TO yjb_schedular;
GRANT DROP ON SCHEMA yjb_case_reporting_stg TO yjb_schedular;
GRANT ALTER ON SCHEMA yjb_case_reporting_stg TO yjb_schedular;
GRANT USAGE ON SCHEMA yjb_case_reporting_stg TO GROUP yjb_data_science;
GRANT USAGE ON SCHEMA yjb_case_reporting_stg TO "IAMR:redshift-serverless-yjb-reporting-moj_ap";

DROP SCHEMA IF EXISTS yjaf_bands cascade;
CREATE EXTERNAL SCHEMA yjaf_bands FROM POSTGRES DATABASE 'yjaf' SCHEMA 'bands' URI 'db-yjafrds01.test.yjaf' IAM_ROLE '${iam_role}' SECRET_ARN '${secret_arn}';
GRANT USAGE ON SCHEMA yjaf_bands TO GROUP yjb_ianda_team;
GRANT USAGE ON SCHEMA yjaf_bands TO "IAMR:redshift-serverless-yjb-reporting-moj_ap";

-- Prod only
--DROP SCHEMA IF EXISTS yjb_case_reporting_redshift;
--CREATE EXTERNAL SCHEMA yjb_case_reporting_redshift FROM POSTGRES DATABASE 'yjb_case_reporting_load_redshift' SCHEMA 'redshift' URI 'db-yjafrds01.test.yjaf' IAM_ROLE '${iam_role}' SECRET_ARN '${secret_arn}';

DROP SCHEMA IF EXISTS yjaf_auth;
CREATE EXTERNAL SCHEMA yjaf_auth FROM POSTGRES DATABASE 'yjaf' SCHEMA 'auth' URI 'db-yjafrds01.test.yjaf' IAM_ROLE '${iam_role}' SECRET_ARN '${secret_arn}';
GRANT USAGE ON SCHEMA yjaf_auth TO GROUP yjb_ianda_team;
GRANT USAGE ON SCHEMA yjaf_auth TO "IAMR:redshift-serverless-yjb-reporting-moj_ap";
