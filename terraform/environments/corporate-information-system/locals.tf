#### This file can be used to store locals specific to the member account ####
locals {
  application_name_short         = "cis"
  nonprod_workspaces_local_cidr1 = "10.200.2.0/24"
  nonprod_workspaces_local_cidr2 = "10.200.3.0/24"

  database-instance-userdata = <<EOF
#!/bin/bash

cd /root

# Update the hostname
hostnamectl set-hostname "${local.application_name_short}.${data.aws_route53_zone.external.name}"

wget https://s3.amazonaws.com/cloudformation-examples/aws-cfn-bootstrap-latest.tar.gz
easy_install --script-dir /opt/aws/bin aws-cfn-bootstrap-latest.tar.gz

# Update SSH configuration
sed -i 's/#ClientAliveInterval.*/ClientAliveInterval 1200/' /etc/ssh/sshd_config
sed -i 's/#ClientAliveCountMax.*/ClientAliveCountMax 3/' /etc/ssh/sshd_config

# Restart SSH service
service sshd restart 

# Add /oracle/software/product/10.2.0/bin/ to PATH
export PATH=/oracle/software/product/10.2.0/bin/:$PATH

# Change the hostname in the listener.ora and tnsnames.ora
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

# Start the listener
sudo su - oracle -c "lsnrctl start LISTENER"

EOF
}