#!/bin/bash

aws rds-data execute-statement --database $DB_NAME --resource-arn $RDS_ARN --sql --secret-arn $SECRETS_ARN tipstaff_staging_predata_backup.sql --parameters '{"name":"username","value":{"stringValue":"'"$LOCAL_DB_USERNAME"'"}},{"name":"password","value":{"stringValue":"'"$LOCAL_DB_PASSWORD"'"}}'