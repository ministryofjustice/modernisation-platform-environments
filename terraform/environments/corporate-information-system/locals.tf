#### This file can be used to store locals specific to the member account ####
locals {
  application_name_short         = "cis"
  nonprod_workspaces_local_cidr1 = "10.200.2.0/24"
  nonprod_workspaces_local_cidr2 = "10.200.3.0/24"

  database-instance-userdata = <<EOF
#!/bin/bash

hostname ${local.application_name_short}

# Use sed to replace the line in the file
sed -i 's/#ClientAliveInterval.*/ClientAliveInterval 1200/' /etc/ssh/sshd_config
sed -i 's/#ClientAliveCountMax.*/ClientAliveCountMax 3/' /etc/ssh/sshd_config
sed -i 's|cis.aws.tst.legalservices.gov.uk:8080|${local.application_name_short}.${data.aws_route53_zone.external.name}:8080|' /home/batman/bin/dkj-shell-funcs
service sshd restart 


sudo su - oracle
export PATH=/oracle/software/product/10.2.0/bin/:$PATH

cat <<EOT > /oracle/software/product/10.2.0/network/admin/listener.ora
SID_LIST_LISTENER =
  (SID_LIST =
    (SID_DESC =
      (SID_NAME = PLSExtProc)
      (ORACLE_HOME = /oracle/software/product/10.2.0)
      (PROGRAM = extproc)
    )
    (SID_DESC =
      (SID_NAME = CIS)
      (ORACLE_HOME = /oracle/software/product/10.2.0)
    )
  )

LISTENER =
  (DESCRIPTION_LIST =
    (DESCRIPTION =
      (ADDRESS = (PROTOCOL = IPC)(KEY = EXTPROC1))
      (ADDRESS = (PROTOCOL = TCP)(HOST = ${local.application_name_short}.${data.aws_route53_zone.external.name})(PORT = 1521))
    )
  )
EOT

cat <<EOT > /oracle/software/product/10.2.0/network/admin/tnsnames.ora
CIS =
  (DESCRIPTION =
    (ADDRESS_LIST =
      (ADDRESS = (PROTOCOL = TCP)(HOST = ${local.application_name_short}.${data.aws_route53_zone.external.name})(PORT = 1521))
    )
    (CONNECT_DATA =
      (SID = CIS)
    )
  )
EOT

# Start DB
sqlplus / as sysdba << EOF
shutdown abort;
startup;
exit;
EOF"

# Start Listener
lsnrctl start LISTENER

EOF
}