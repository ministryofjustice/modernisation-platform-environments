#!/bin/sh

./replication.sh aws-glue-assets-053556912568-eu-west-2 053556912568 yjaf-preproduction-glue-assets-archive <dest_acc_no>
./replication.sh preprod-s3-bucket-access-logging 053556912568 yjaf-preproduction-s3-bucket-access-logging-archive <dest_acc_no>
./replication.sh preprod-redshift-serverless-yjb-reporting  053556912568 yjaf-preproduction-redshift-yjb-reporting-archive <dest_acc_no>
./replication.sh yjaf-pre-prod 053556912568 yjaf-preproduction-tableau-alb-logs-archive <dest_acc_no>
./replication.sh yjaf-preprod-cloudfront-alb-logs 053556912568 yjaf-preproduction-yjaf-ext-external-logs-archive <dest_acc_no>
./replication.sh yjaf-preprod-internallb-logs 053556912568 yjaf-preproduction-int-internal-logs-archive <dest_acc_no>
./replication.sh yjaf-preprod-bands 053556912568 yjaf-preproduction-bands <dest_acc_no>
./replication.sh yjaf-preprod-bedunlock 053556912568 yjaf-preproduction-bedunlock <dest_acc_no>
./replication.sh yjaf-preprod-cloudfront-logs 053556912568 yjaf-preproduction-cloudfront-logs-archive <dest_acc_no>
./replication.sh yjaf-preprod-cloudtrail-logs 053556912568 yjaf-preproduction-cloudtrail-logs-archive <dest_acc_no>
./replication.sh yjaf-preprod-cmm 053556912568 yjaf-preproduction-cmm <dest_acc_no>
./replication.sh yjaf-preprod-cms 053556912568 jyaf-preprod-cms <dest_acc_no>
./replication.sh yjaf-preprod-guardduty-global-findings-logs 053556912568 yjaf-preproduction-guardduty-to-fallanx-archive-archive <dest_acc_no>
./replication.sh yjaf-preprod-mis 053556912568 yjaf-preproduction-mis <dest_acc_no>
./replication.sh yjaf-preprod-reporting 053556912568 yjaf-preproduction-reporting <dest_acc_no>
./replication.sh yjaf-preprod-tableau-backups 053556912568 yjaf-preproduction-tableau-backups-archive <dest_acc_no>
./replication.sh yjsm-preprod-artefact 053556912568 yjaf-preproduction-yjsm-artefact <dest_acc_no>
./replication.sh yjaf-preprod-yjsm 053556912568 yjaf-preproduction-yjsm <dest_acc_no>
