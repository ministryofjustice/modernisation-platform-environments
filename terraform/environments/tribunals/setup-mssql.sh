#!/bin/bash


echo "exported ENV values are 1: ${DB_URL}"

echo "Creating initial database...."
echo "DB_URL is <${DB_URL}>"
sudo apt-get install mssql-tools
sqlcmd -S ${DB_URL} -U ${USER_NAME} -P ${PASSWORD} -Q "create database ${NEW_DB_NAME}"
sqlcmd -S ${DB_URL} -U ${USER_NAME} -P ${PASSWORD} -Q "CREATE LOGIN ${NEW_USER_NAME} WITH PASSWORD = '${NEW_PASSWORD}'"
sqlcmd -S ${DB_URL} -U ${USER_NAME} -P ${PASSWORD} -Q "CREATE USER ${NEW_USER_NAME} FOR LOGIN ${NEW_USER_NAME}"
sqlcmd -S ${DB_URL} -U ${USER_NAME} -P ${PASSWORD} -Q "USE ${NEW_DB_NAME} GO EXEC sp_addrolemember N'db_owner', N'${NEW_USER_NAME}'; GO"
sqlcmd -S ${DB_URL} -U ${USER_NAME} -P ${PASSWORD} -i "./modules/${APP_FOLDER}/sp_migration.sql"