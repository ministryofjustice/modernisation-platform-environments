<dest_acc_no>#!/bin/sh

./replication.sh aws-glue-assets-066012302209-eu-west-2 066012302209 yjaf-production-glue-assets-archive <dest_acc_no>
./replication.sh prod-s3-bucket-access-logging 066012302209 yjaf-production-s3-bucket-access-logging-archive <dest_acc_no>
./replication.sh redshift-serverless-yjb-reporting  066012302209 yjaf-production-redshift-yjb-reporting-archive <dest_acc_no>
#./replication.sh yjaf-pre-prod 066012302209 yjaf-production-tableau-alb-logs-archive <dest_acc_no>
./replication.sh yjaf-externallb-logs 066012302209 yjaf-production-yjaf-ext-external-logs-archive <dest_acc_no>
./replication.sh yjaf-internallb-logs 066012302209 yjaf-production-int-internal-logs-archive <dest_acc_no>
./replication.sh yjaf-prod-bands 066012302209 yjaf-production-bands <dest_acc_no>
./replication.sh yjaf-prod-bedunlock 066012302209 yjaf-production-bedunlock <dest_acc_no>
./replication.sh yjaf-prod-cloudfront-logs 066012302209 yjaf-production-cloudfront-logs-archive <dest_acc_no>
./replication.sh yjaf-prod-cloudtrail-logs 066012302209 yjaf-production-cloudtrail-logs-archive <dest_acc_no>
./replication.sh yjaf-prod-cmm 066012302209 yjaf-production-cmm(<dest_acc_no>
./replication.sh jyaf-prod-cms 066012302209 jyaf-prod-cms <dest_acc_no>
./replication.sh yjaf-prod-guardduty-global-findings-logs 066012302209 yjaf-production-guardduty-to-fallanx-archive-archive <dest_acc_no>
./replication.sh yjaf-prod-mis 066012302209 yjaf-production-mis <dest_acc_no>
./replication.sh yjaf-prod-reporting 066012302209 yjaf-production-reporting <dest_acc_no>
./replication.sh yjaf-prod-tableau-backups 066012302209 yjaf-production-tableau-backups-archive <dest_acc_no>
./replication.sh yjsm-prod-artefact 066012302209 yjaf-production-yjsm-artefact <dest_acc_no>
./replication.sh yjaf-prod-yjsm 066012302209 yjaf-production-yjsm <dest_acc_no>
