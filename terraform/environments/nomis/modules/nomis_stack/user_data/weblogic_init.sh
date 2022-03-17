#!/bin/bash

# Make sure /dev/xvdb is mounted to /u01 (fstab working intermittently)
mount -a

# Create nomis_weblogic service
chkconfig --add nomis_weblogic
chkconfig --level 3 nomis_weblogic on

# Check variables are set and run weblogic setup script
# USAGE
# [-d] Use default credentials for database and Weblogic admin console
# [-e <ENV> e.g. T1]
# [-h <DB_HOSTNAME>]
if [[ -n ${ENV} ]] && [[ -n ${DB_HOSTNAME} ]] && [[ ${USE_DEFAULT_CREDS} = "false" ]]; then
  su -c "bash /u01/software/weblogic/weblogic-setup.sh -d -e ${ENV} -h ${DB_HOSTNAME}" - oracle
elif [[ -n ${DB_HOSTNAME} ]] && [[ ${USE_DEFAULT_CREDS} = "true" ]]; then
  su -c "bash /u01/software/weblogic/weblogic-setup.sh -d -h ${DB_HOSTNAME}" - oracle
else
  echo "Error: Environment variables undefined"
  exit 1
fi