#!/bin/bash

aws rds-data execute-statement --database $DB_NAME --resource-arn $RDS_ARN --secret-arn $SECRETS_ARN --sql tipstaff_staging_predata_backup.sql