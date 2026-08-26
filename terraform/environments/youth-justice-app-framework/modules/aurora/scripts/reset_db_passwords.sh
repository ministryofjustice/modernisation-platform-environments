#!/bin/bash

DB_HOST=$1
DB_USERNAME=$2
DB_PASSWORD=$3
CHANGE_USER=$4

# Use PGPASSWORD environment variable to avoid password prompt
export PGPASSWORD=$DB_PASSWORD

# Connect to PostgreSQL and run the SQL commands to reset passwords
psql -h $DB_HOST -U $DB_USERNAME -d postgres -c "
ALTER USER $CHANGE_USER WITH PASSWORD '$NEW_PASSWORD';
"

# Unset the PGPASSWORD environment variable for security
unset PGPASSWORD
