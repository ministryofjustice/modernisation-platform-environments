#!/bin/sh

./replication.sh preprod aws-glue-assets-053556912568-eu-west-2 053556912568 yjaf-preproduction-aws-glue-assets-archive 888577039394
./replication.sh preprod preprod-s3-bucket-access-logging 053556912568 yjaf-preproduction-s3-bucket-access-logging-archive 888577039394
./replication.sh preprod preprod-redshift-serverless-yjb-reporting  053556912568 yjaf-preproduction-redshift-yjb-reporting-archive 888577039394
./replication.sh preprod yjaf-pre-prod 053556912568 yjaf-preproduction-tableau-alb-logs-archive 888577039394
./replication.sh preprod yjaf-preprod-cloudfront-alb-logs 053556912568 yjaf-preproduction-yjaf-ext-external-logs-archive 888577039394
./replication.sh preprod yjaf-preprod-replication-source 053556912568 yjaf-preproduction-transfer 888577039394
./replication.sh preprod yjaf-preprod-internallb-logs 053556912568 yjaf-preproduction-yjaf-int-internal-logs-archive 888577039394
./replication.sh preprod yjaf-preprod-bands 053556912568 yjaf-preproduction-bands 888577039394
./replication.sh preprod yjaf-preprod-bedunlock 053556912568 yjaf-preproduction-bedunlock 888577039394
./replication.sh preprod yjaf-preprod-cloudfront-logs 053556912568 yjaf-preproduction-cloudfront-logs-archive 888577039394
./replication.sh preprod yjaf-preprod-cloudtrail-logs 053556912568 yjaf-preproduction-cloudtrail-logs-archive 888577039394
./replication.sh preprod yjaf-preprod-cmm 053556912568 yjaf-preproduction-cmm 888577039394
./replication.sh preprod yjaf-preprod-cms 053556912568 yjaf-preproduction-cms 888577039394
./replication.sh preprod yjaf-preprod-guardduty-global-findings-logs 053556912568 yjaf-preproduction-guardduty-to-fallanx-archive-archive 888577039394
./replication.sh preprod yjaf-preprod-mis 053556912568 yjaf-preproduction-mis 888577039394
./replication.sh preprod yjaf-preprod-reporting 053556912568 yjaf-preproduction-reporting 888577039394
./replication.sh preprod yjaf-preprod-tableau-backups 053556912568 yjaf-preproduction-tableau-backups-archive 888577039394
./replication.sh preprod yjsm-preprod-artefact 053556912568 yjaf-preproduction-yjsm-artefact 888577039394
./replication.sh preprod yjaf-preprod-yjsm 053556912568 yjaf-preproduction-yjsm 888577039394
./replication.sh preprod historical-preprodinfrastructure 053556912568 yjaf-preproduction-historical-infrastructure 888577039394
./replication.sh preprod historical-preprodapps 053556912568 yjaf-preproduction-historical-apps 888577039394
