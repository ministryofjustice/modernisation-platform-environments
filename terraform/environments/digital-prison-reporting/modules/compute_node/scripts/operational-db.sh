#!/bin/bash

set -eux
# update system packages
yum update -y

# enable repository to install postgresql
amazon-linux-extras enable postgresql14

# Required to allow interactively running sql scripts as other users in SSM
## This is only deployed in the dev environment for the duration of the Spike
cd /etc/sudoers.d
echo "ssm-user ALL=(ALL) NOPASSWD:ALL" > ssm-agent-users

# Install PostgreSQL server and initialize the database 
# cluster for this server
yum install postgresql-server postgresql-devel postgresql-server-devel git -y
sudo postgresql-setup initdb

# Update PostgreSQL authentication config file
# Allow connections
cat <<EOF >/var/lib/pgsql/data/pg_hba.conf
# TYPE  DATABASE        USER            ADDRESS                 METHOD

# "local" is for Unix domain socket connections only
local   all             all                                     peer
# IPv4 local connections:
local   all             all                                     peer
# IPv4 local connections:
host    all             all             127.0.0.1/32            md5
# IPv6 local connections:
host    all             all             ::1/128                 md5
# Allow replication connections from localhost, by a user with the
# replication privilege.
local   replication     all                                     peer
host    replication     all             127.0.0.1/32            ident
host    replication     all             ::1/128                 ident
host    all             all             0.0.0.0/0               md5
EOF

# Update the IPs of the address to listen from PostgreSQL config
sed -i "59i listen_addresses = '*'" /var/lib/pgsql/data/postgresql.conf

# Start the db service
systemctl enable postgresql
systemctl start postgresql

# Setup PG_IVM
git clone https://github.com/sraoss/pg_ivm.git
cd pg_ivm; make install Makefile

# Enable pg_ivm Extension
sudo -Hiu postgres psql -c "CREATE EXTENSION pg_ivm;"

# Set Password for POSTGRES, Root user
sudo -Hiu postgres psql -c "ALTER USER postgres WITH PASSWORD '${POSTGRES_P}';"

# Install oracle_fdw
## Oracle client rpms
mkdir -p /opt/oracle/
aws s3 cp s3://dpr-working-development/oracle-instantclient12.2-basic-12.2.0.1.0-1.x86_64.rpm /opt/oracle/
aws s3 cp s3://dpr-working-development/oracle-instantclient12.2-devel-12.2.0.1.0-1.x86_64.rpm /opt/oracle/
yum install -y  /opt/oracle/oracle-instantclient12.2-basic-12.2.0.1.0-1.x86_64.rpm
yum install -y /opt/oracle/oracle-instantclient12.2-devel-12.2.0.1.0-1.x86_64.rpm
## make Oracle client libs available to postgres
echo -n "/usr/lib/oracle/12.2/client64/lib/" >/etc/ld.so.conf
ldconfig
## Install latest dev version of oracle_fdw
mkdir -p /opt/oracle_fdw
cd /opt/oracle_fdw && git clone https://github.com/laurenz/oracle_fdw.git
cd oracle_fdw
make
make install
systemctl restart postgresql

# Check POSTGRES Service Status
systemctl status postgresql