#### This file can be used to store locals specific to the member account ####
locals {
  application_name_short         = "cis"
  nonprod_workspaces_local_cidr1 = "10.200.2.0/24"
  nonprod_workspaces_local_cidr2 = "10.200.3.0/24"

  create_cis_s3fs_instance = contains(["development", "preproduction", "production"], local.environment)

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

  s3fs-instance-userdata = <<EOF
#!/bin/bash

yum update -y
amazon-linux-extras install epel -y
yum install s3fs-fuse -y
cd /
mkdir -pm 774 /s3xfer/S3/laa-ccms-inbound-${local.environment}
mkdir -pm 774 /s3xfer/S3/laa-ccms-outbound-${local.environment}
mkdir -pm 774 /s3xfer/S3/laa-cis-inbound-${local.environment}
mkdir -pm 774 /s3xfer/S3/laa-cis-outbound-${local.environment}
mkdir -m 774 cdstemp
echo 's3fs#laa-ccms-outbound-${local.environment} /s3xfer/S3/laa-ccms-outbound-${local.environment} fuse _netdev,allow_other,iam_role=auto 0 0' >> /etc/fstab
echo 's3fs#laa-ccms-inbound-${local.environment} /s3xfer/S3/laa-ccms-inbound-${local.environment} fuse _netdev,allow_other,iam_role=auto 0 0' >> /etc/fstab
echo 's3fs#laa-cis-outbound-${local.environment} /s3xfer/S3/laa-cis-outbound-${local.environment} fuse _netdev,allow_other,iam_role=auto 0 0' >> /etc/fstab
echo 's3fs#laa-cis-inbound-${local.environment} /s3xfer/S3/laa-cis-inbound-${local.environment} fuse _netdev,allow_other,iam_role=auto 0 0' >> /etc/fstab
echo 's3fs#cds-central-print-temp /cdstemp fuse default_acl=bucket-owner-full-control,allow_other,use_cache=/tmp,endpoint=eu-west-2,uid=502,mp_umask=002,multireq_max=5,iam_role=' >> /etc/fstab
mount -a

EOF
}