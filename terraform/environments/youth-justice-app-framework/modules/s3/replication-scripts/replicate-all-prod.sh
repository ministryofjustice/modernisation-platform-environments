#!/bin/sh

#./replication.sh prod aws-glue-assets-066012302209-eu-west-2 066012302209 yjaf-production-aws-glue-assets-archive 586794462316
#./replication.sh prod prod-s3-bucket-access-logging 066012302209 yjaf-production-s3-bucket-access-logging-archive 586794462316
#./replication.sh prod redshift-serverless-yjb-reporting  066012302209 yjaf-production-redshift-yjb-reporting-archive 586794462316
#./replication.sh prod yjaf-pre-prod 066012302209 yjaf-production-tableau-alb-logs-archive 586794462316
#./replication.sh prod yjaf-externallb-logs 066012302209 yjaf-production-yjaf-ext-external-logs-archive 586794462316
#./replication.sh prod yjaf-internallb-logs 066012302209 yjaf-production-yjaf-int-internal-logs-archive 586794462316
./replication.sh prod yjaf-prod-bands 066012302209 yjaf-production-bands 586794462316
./replication.sh prod yjaf-prod-bedunlock 066012302209 yjaf-production-bedunlock 586794462316
#./replication.sh prod yjaf-prod-cloudfront-logs 066012302209 yjaf-production-cloudfront-logs-archive 586794462316
#./replication.sh prod yjaf-prod-cloudtrail-logs 066012302209 yjaf-production-cloudtrail-logs-archive 586794462316
./replication.sh prod yjaf-prod-cmm 066012302209 yjaf-production-cmm 586794462316
./replication.sh prod yjaf-prod-cms 066012302209 yjaf-production-cms 586794462316
#./replication.sh prod yjaf-prod-guardduty-global-findings-logs 066012302209 yjaf-production-guardduty-to-fallanx-archive-archive 586794462316
./replication.sh prod yjaf-prod-mis 066012302209 yjaf-production-mis 586794462316
./replication.sh prod yjaf-prod-reporting 066012302209 yjaf-production-reporting 586794462316
#./replication.sh prod yjaf-prod-tableau-backups 066012302209 yjaf-production-tableau-backups-archive 586794462316
./replication.sh prod yjsm-prod-artefact 066012302209 yjaf-production-yjsm-artefact 586794462316
./replication.sh prod yjaf-prod-yjsm 066012302209 yjaf-production-yjsm 586794462316
#./replication.sh prod yjaf-prod-replication-source 066012302209 yjaf-production-transfer 586794462316
./replication.sh prod historical-prodinfrastructure 066012302209 yjaf-production-historical-infrastructure 586794462316
./replication.sh prod historical-prodapps 066012302209 yjaf-production-historical-apps 586794462316
