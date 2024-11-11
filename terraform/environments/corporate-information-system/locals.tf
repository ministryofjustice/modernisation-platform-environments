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
sed -i 's/#ClientAliveCountMax.*/ClientAliveCountMax 5/' /etc/ssh/sshd_config
service sshd restart 

# Add TCP keepalive time to sysctl.conf ---> keepalive solution
echo "net.ipv4.tcp_keepalive_time = 120" >> /etc/sysctl.conf
sysctl -p

# Add SQLNET.EXPIRE_TIME to sqlnet.ora ---> keepalive solution
echo "SQLNET.EXPIRE_TIME = 2" >> /oracle/software/product/10.2.0/network/admin/sqlnet.ora

# Modify tnsnames.ora to insert (ENABLE=broken) ---> keepalive solution
sed -i '/(DESCRIPTION =/a\\  (ENABLE=broken)' /oracle/software/product/10.2.0/network/admin/tnsnames.ora

# Changes to oracle files - cis.laa-development.modernisation-platform.service.justice.gov.uk CIS DB without Volumes - 11-Sept-2024
sed -i 's|cis.*legalservices.gov.uk:8080|${local.application_name_short}.${data.aws_route53_zone.external.name}:8080|' /home/batman/bin/dkj-shell-funcs
sed -i 's|cis.*legalservices.gov.uk|${local.application_name_short}.${data.aws_route53_zone.external.name}|' /oracle/software/product/10.2.0/network/admin/listener.ora
sed -i 's|cis.*legalservices.gov.uk|${local.application_name_short}.${data.aws_route53_zone.external.name}|' /oracle/software/product/10.2.0/network/admin/tnsnames.ora

# Set the Oracle environment variables
sudo su - oracle -c 'export PATH=/oracle/software/product/10.2.0/bin/:$PATH'

# Start DB as oracle user
runuser -l oracle -c "sqlplus / as sysdba <<EOF
shutdown abort;
startup;
exit;
EOF" >> /tmp/oracle_startup.log 2>&1

# Start Listener as oracle user
runuser -l oracle -c 'lsnrctl start LISTENER' >> /tmp/listener_startup.log 2>&1

EOF
}