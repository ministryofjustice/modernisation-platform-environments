#!/bin/bash

export PGPASSWORD=$LOCAL_DB_PASSWORD;
# if database contains schema dbo then store schema name inside variable.
SCHEMA=$(psql -h ${DB_HOSTNAME} -p 5432 -U $LOCAL_DB_USERNAME -d $DB_NAME -c "SELECT schema_name FROM information_schema.schemata WHERE schema_name = 'dbo'" | grep -o 'dbo') 
echo "$SCHEMA"

if [ "$TF_MODE" == "" ]; then
    if [ "$SCHEMA" == "dbo" ]; then 
    echo "The Schema dbo is already present in the database"
    else 
    psql -h ${DB_HOSTNAME} -p 5432 -U $LOCAL_DB_USERNAME -d $DB_NAME -c "\i tipstaff_staging_predata_backup.sql;";
    fi
fi