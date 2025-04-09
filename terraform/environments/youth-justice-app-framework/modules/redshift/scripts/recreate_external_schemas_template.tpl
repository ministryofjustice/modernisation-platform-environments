CREATE EXTERNAL SCHEMA yjaf_bands_new
FROM POSTGRES
 DATABASE 'yjaf'
 SCHEMA 'bands'
 URI '${postgres_uri}'
 IAM_ROLE ${iam_role}'
 SECRET_ARN '${secret_arn}'
