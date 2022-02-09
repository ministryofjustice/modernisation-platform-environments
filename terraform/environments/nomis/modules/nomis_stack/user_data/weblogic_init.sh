#!/bin/bash

su -c "export USE_DEFAULT_CREDS=${USE_DEFAULT_CREDS} DB_HOSTNAME=${DB_HOSTNAME} ENV=${ENV}; bash /u01/software/weblogic/weblogic-setup.sh" - oracle
