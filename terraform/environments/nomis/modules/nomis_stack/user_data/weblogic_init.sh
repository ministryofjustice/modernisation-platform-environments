#!/bin/bash

su -c "export DB_HOSTNAME=${DB_HOSTNAME}; bash /u01/software/weblogic/weblogic-setup.sh" - oracle
