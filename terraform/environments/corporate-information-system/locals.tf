#### This file can be used to store locals specific to the member account ####
locals {
  application_name_short         = "cis"
  nonprod_workspaces_local_cidr1 = "10.200.2.0/24"
  nonprod_workspaces_local_cidr2 = "10.200.3.0/24"

  database-instance-userdata = <<EOF
#!/bin/bash

hostname ${local.application_name_short}

# Increase ssh session timeout
sed -i 's/#ClientAliveInterval.*/ClientAliveInterval 1200/' /etc/ssh/sshd_config
sed -i 's/#ClientAliveCountMax.*/ClientAliveCountMax 3/' /etc/ssh/sshd_config
service sshd restart 

# Changes to oracle files
sed -i 's|cis.*legalservices.gov.uk:8080|${local.application_name_short}.${data.aws_route53_zone.external.name}:8080|' /home/batman/bin/dkj-shell-funcs
sed -i 's|cis.*legalservices.gov.uk|${local.application_name_short}.${data.aws_route53_zone.external.name}|' /oracle/software/product/10.2.0/network/admin/listener.ora
sed -i 's|cis.*legalservices.gov.uk|${local.application_name_short}.${data.aws_route53_zone.external.name}|' /oracle/software/product/10.2.0/network/admin/tnsnames.ora

# Set the Oracle environment variables and start DB as oracle user
sudo su - oracle -c 'export PATH=/oracle/software/product/10.2.0/bin/:$PATH && sqlplus / as sysdba << EOF
shutdown abort;
startup;
exit;
EOF'

# Start Listener as root user
sudo lsnrctl start LISTENER

EOF
}