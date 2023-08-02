#!/bin/bash

export PGPASSWORD=$DACP_DB_PASSWORD;
# if database contains schema dbo then store schema name inside variable.
SCHEMA=$(psql -h ${DB_HOSTNAME} -p 5432 -U $DACP_DB_USERNAME -d $DB_NAME -c "SELECT schema_name FROM information_schema.schemata WHERE schema_name = 'dbo'" | grep -o 'dbo')
echo "Schema = $SCHEMA"

if [ "$SCHEMA" == "dbo" ]; then
    echo "The Schema dbo is already present in the database"
else
    echo "You reached the ELSE"
fi

# psql -h ${DB_HOSTNAME} -p 5432 -U $DACP_DB_USERNAME -d $DB_NAME -c "CREATE SCHEMA IF NOT EXISTS dbo;";
pg_dump -U $SOURCE_DB_USERNAME -h $SOURCE_DB_HOSTNAME -d $SOURCE_DB_NAME --password $SOURCE_DB_PASSWORD -O --section=pre-data > pre-data.sql
pg_dump -U $SOURCE_DB_USERNAME -h $SOURCE_DB_HOSTNAME -d $SOURCE_DB_NAME --password $SOURCE_DB_PASSWORD -t 'dbo.*_seq' > sequences.sql
pg_dump -U $SOURCE_DB_USERNAME -h $SOURCE_DB_HOSTNAME -d $SOURCE_DB_NAME --password $SOURCE_DB_PASSWORD -O --section=data > data.sql
pg_dump -U $SOURCE_DB_USERNAME -h $SOURCE_DB_HOSTNAME -d $SOURCE_DB_NAME --password $SOURCE_DB_PASSWORD -O --section=post-data > post-data.sql

psql -U $DACP_DB_USERNAME -h $DB_HOSTNAME -d $DB_NAME --password $DACP_DB_PASSWORD -f pre-data.sql
psql -U $DACP_DB_USERNAME -h $DB_HOSTNAME -d $DB_NAME --password $DACP_DB_PASSWORD -f sequences.sql
psql -U $DACP_DB_USERNAME -h $DB_HOSTNAME -d $DB_NAME --password $DACP_DB_PASSWORD -f data.sql
psql -U $DACP_DB_USERNAME -h $DB_HOSTNAME -d $DB_NAME --password $DACP_DB_PASSWORD -f post-data.sql