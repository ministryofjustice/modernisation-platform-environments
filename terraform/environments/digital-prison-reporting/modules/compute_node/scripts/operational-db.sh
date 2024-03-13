#!/bin/bash
# update system packages
yum update -y

# enable repository to install postgresql
amazon-linux-extras enable postgresql14

# Install PostgreSQL server and initialize the database 
# cluster for this server
yum install postgresql-server postgresql-devel postgresql-server-devel git -y
#/usr/bin/postgresql-setup --initdb
sudo postgresql-setup initdb

# Update PostgreSQL authentication config file
# Add the following to the end of the file to allow client connections to all databases.
echo -e "host    all          all            0.0.0.0/0  md5" >> /var/lib/pgsql/data/pg_hba.conf

# Update the IPs of the address to listen from PostgreSQL config
sed -i "59i listen_addresses = '*'" /var/lib/pgsql/data/postgresql.conf

# Set Password for POSTGRES, Root user
sudo -Hiu postgres psql -c "ALTER USER postgres PASSWORD '${POSTGRES_PASS}';"

# Start the db service
systemctl enable postgresql
systemctl start postgresql

# Setup PG_IVM
git clone https://github.com/sraoss/pg_ivm.git
cd pg_ivm; make install Makefile

# Enable pg_ivm Extension
sudo -Hiu postgres psql -c "CREATE EXTENSION pg_ivm;"

# Check POSTGRES Service Status
systemctl status postgresql