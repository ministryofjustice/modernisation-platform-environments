#!/bin/bash

# Place sensitive values into AWS parameter store (obtained via user input on "terraform apply")
aws ssm put-parameter --name "${ENV}_DB_USERNAME" --type "String" --value "${DB_USERNAME}" --overwrite
aws ssm put-parameter --name "${ENV}_DB_PASSWORD" --type "String" --value "${DB_PASSWORD}" --overwrite
aws ssm put-parameter --name "${ENV}_WEBLOGIC_USERNAME" --type "String" --value "${WEBLOGIC_USERNAME}" --overwrite
aws ssm put-parameter --name "${ENV}_WEBLOGIC_PASSWORD" --type "String" --value "${WEBLOGIC_PASSWORD}" --overwrite

su -c "export DB_HOSTNAME=${DB_HOSTNAME} DB_NAME=${DB_NAME} DB_PORT=${DB_PORT}; bash /u01/software/weblogic/weblogic-setup.sh" - oracle
