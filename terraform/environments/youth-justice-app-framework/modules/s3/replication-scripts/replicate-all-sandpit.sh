#!/bin/sh

#./replication.sh yjaf-sandpit-glue-assetts-<account_ID>-eu-west-2 856879713508 yjaf-test-glue-assets-archive 225989353474
./replication.sh sandpit-s3-bucket-access-logging 856879713508 yjaf-test-s3-bucket-access-logging-archive 225989353474
#./replication.sh sandpit-redshift-serverless-yjb-reporting  856879713508 yjaf-test-redshift-yjb-reporting-archive 225989353474
./replication.sh yjaf-sandpit-alb-tableau 856879713508 yjaf-test-tableau-alb-logs-archive 225989353474
./replication.sh sandpit-yjaf-cluster-lb 856879713508 yjaf-test-yjaf-ext-external-logs-archive 225989353474
./replication.sh private-yjaf-cluster-lb 856879713508 yjaf-test-int-internal-logs-archive 225989353474
./replication.sh yjaf-sandpit-bands 856879713508 yjaf-test-bands 225989353474
./replication.sh yyjaf-sandpit-bedunlock 856879713508 yjaf-test-bedunlock 225989353474
#./replication.sh yjaf-sandpit-cloudfront-logs 856879713508 yjaf-test-cloudfront-logs-archive 225989353474
./replication.sh yjaf-sandpit-cloudtrail-logs 856879713508 yjaf-test-cloudtrail-logs-archive 225989353474
./replication.sh yjaf-sandpit-cmm 856879713508 yjaf-test-cmm 225989353474
./replication.sh yjaf-sandpit-cms 856879713508 yjaf-sandpit-cms 225989353474
./replication.sh yjaf-sandpit-guardduty-global-findings-logs 856879713508 yjaf-test-guardduty-to-fallanx-archive-archive 225989353474
./replication.sh yjaf-sandpit-mis 856879713508 yjaf-test-mis 225989353474
./replication.sh yjaf-sandpit-reporting 856879713508 yjaf-test-reporting 225989353474
./replication.sh yjaf-sandpit-tableau-backups 856879713508 yjaf-test-tableau-backups-archive 225989353474
./replication.sh yjsm-sandpit-artefact 856879713508 yjaf-test-yjsm-artefact 225989353474
./replication.sh yjaf-sandpit-yjsm 856879713508 yjaf-test-yjsm 225989353474

