#!/bin/bash

# su -c "export USE_DEFAULT_CREDS=${USE_DEFAULT_CREDS} DB_HOSTNAME=${DB_HOSTNAME} ENV=${ENV}; bash /u01/software/weblogic/weblogic-setup.sh" - oracle
su -c "export USE_DEFAULT_CREDS='true' DB_HOSTNAME=db.t1.nomis.hmpps-test.modernisation-platform.service.justice.gov.uk ENV=T1; bash /u01/software/weblogic/weblogic-setup.sh" - oracle

# Create nomis_weblogic service
chkconfig --add nomis_weblogic
chkconfig --level 3 nomis_weblogic on
