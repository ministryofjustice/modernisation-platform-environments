#!/bin/bash


echo "exported ENV values are 1: ${DB_URL}"

echo "Checking sqlcmd installation.."
which sqlcmd 2>/dev/null
if [[ $? -eq 1 ]]
then

    echo "sqlCmd has not been installed on this machine"
    echo "Update the priorities.conf file"
    which yum
    find /etc/yum -print
    repoPrConf="/etc/yum/pluginconf.d/priorities.conf"
    rm -f ${repoPrConf}

cat >> ${repoPrConf} << EOF
[main]
enabled = 0
EOF

    echo "Download mssql-tools yum repo..."
    chmod 644 ${repoPrConf}
    curl https://packages.microsoft.com/config/rhel/9.0/prod.repo > /etc/yum.repos.d/msprod.repo

    echo "Update yum and install mssql-tools...."
    yum update -y
    ACCEPT_EULA=y yum install mssql-tools -y
    sudo ln -s /opt/mssql-tools/bin/sqlcmd /usr/local/bin

    which sqlcmd
    if [[ $? -eq 0 ]]
    then
      echo "Creating initial database...."
      echo "DB_URL is <${DB_URL}>"
      sqlcmd -S ${DB_URL} -U ${USER_NAME} -P ${PASSWORD} -Q "create database ${NEW_DB_NAME}"
      sqlcmd -S ${DB_URL} -U ${USER_NAME} -P ${PASSWORD} -Q "CREATE LOGIN ${NEW_USER_NAME} WITH PASSWORD = '${NEW_PASSWORD}'"      
      sqlcmd -S ${DB_URL} -U ${USER_NAME} -P ${PASSWORD} -Q "CREATE USER ${NEW_USER_NAME} FOR LOGIN ${NEW_USER_NAME}"
      sqlcmd -S ${DB_URL} -U ${USER_NAME} -P ${PASSWORD} -Q "USE ${NEW_DB_NAME} GO EXEC sp_addrolemember N'db_owner', N'${NEW_USER_NAME}'; GO"
      sqlcmd -S ${DB_URL} -U ${USER_NAME} -P ${PASSWORD} -i "sp_migration.sql"
    else
      echo "sqlcmd not found"
    fi

else
    echo "SqlCmd has been already installed"
fi