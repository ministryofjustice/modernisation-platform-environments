#!/bin/bash

# Run weblogic setup script as oracle user
su -c "export DB_HOSTNAME=${DB_HOSTNAME}; bash /u01/software/weblogic/weblogic-setup.sh" - oracle
