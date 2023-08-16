#!/bin/bash

export PGPASSWORD=$PRA_DB_PASSWORD;
# if database contains schema dbo then store schema name inside variable.
SCHEMA=$(psql -h ${DB_HOSTNAME} -p 5432 -U $PRA_DB_USERNAME -d $DB_NAME -c "SELECT schema_name FROM information_schema.schemata WHERE schema_name = 'dbo'" | grep -o 'dbo')
echo "Schema = $SCHEMA"

export PGPASSWORD=$SOURCE_DB_PASSWORD;
pg_dump -U $SOURCE_DB_USERNAME -h $SOURCE_DB_HOSTNAME -d $SOURCE_DB_NAME -O --section=pre-data > pre-data.sql
pg_dump -U $SOURCE_DB_USERNAME -h $SOURCE_DB_HOSTNAME -d $SOURCE_DB_NAME -t 'dbo.*_seq' > sequences.sql
pg_dump -U $SOURCE_DB_USERNAME -h $SOURCE_DB_HOSTNAME -d $SOURCE_DB_NAME -O --section=data > data.sql
pg_dump -U $SOURCE_DB_USERNAME -h $SOURCE_DB_HOSTNAME -d $SOURCE_DB_NAME -O --section=post-data > post-data.sql

export PGPASSWORD=$PRA_DB_PASSWORD;
psql -U $PRA_DB_USERNAME -h $DB_HOSTNAME -d $DB_NAME -f pre-data.sql
psql -U $PRA_DB_USERNAME -h $DB_HOSTNAME -d $DB_NAME -f sequences.sql
psql -U $PRA_DB_USERNAME -h $DB_HOSTNAME -d $DB_NAME -f data.sql
psql -U $PRA_DB_USERNAME -h $DB_HOSTNAME -d $DB_NAME -f post-data.sql
