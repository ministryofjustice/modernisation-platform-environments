#!/bin/bash

exec > /tmp/userdata.log 2>&1

amazon-linux-extras install -y epel
yum install -y wget unzip vsftpd jq s3fs-fuse
yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm

curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install

wget https://s3.amazonaws.com/amazoncloudwatch-agent/oracle_linux/amd64/latest/amazon-cloudwatch-agent.rpm
rpm -U ./amazon-cloudwatch-agent.rpm

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c ssm:cloud-watch-config

systemctl stop amazon-ssm-agent
rm -rf /var/lib/amazon/ssm/ipc/
systemctl start amazon-ssm-agent

useradd -m s3xfer

echo "pasv_enable=YES" >> /etc/vsftpd/vsftpd.conf
echo "pasv_min_port=3000" >> /etc/vsftpd/vsftpd.conf
echo "pasv_max_port=3010" >> /etc/vsftpd/vsftpd.conf

systemctl restart vsftpd.service

cat > /etc/mount_s3.sh <<- EOM
#!/bin/bash

B=(laa-ccms-inbound-${lz_ftp_bucket_environment} laa-ccms-outbound-${lz_ftp_bucket_environment} laa-cis-outbound-${lz_ftp_bucket_environment} laa-cis-inbound-${lz_ftp_bucket_environment} bacway-${lz_ftp_bucket_environment}-eu-west-2-${lz_aws_account_id_env})

C=\$(aws secretsmanager get-secret-value --secret-id ftp-s3-${environment}-aws-key --region eu-west-2)
K=\$(jq -r '.SecretString' <<< \$${C} |cut -d'"' -f2)
S=\$(jq -r '.SecretString' <<< \$${C} |cut -d'"' -f4)
U=\$(id -u s3xfer)
G=\$(id -g s3xfer)
F=/etc/passwd-s3fs
echo "\$${K}:\$${S}" > "\$${F}"
chmod 600 \$${F}

for b in "\$${B[@]}"; do
  D=/s3xfer/S3/\$${b}

  if [[ -d \$${D} ]]; then
    echo "\$${D} exists."
  else
    mkdir -p \$${D}
  fi

  chown -R s3xfer:users \$${D}
  chmod 755 \$${D}

  s3fs \$${b} \$${D} -o passwd_file=\$${F} -o _netdev,allow_other,use_cache=/tmp,url=https://s3-eu-west-2.amazonaws.com,endpoint=eu-west-2,umask=022,uid=\$${U},gid=\$${G}
  if [[ \$? -eq 0 ]]; then
    s3fs \$${b} \$${D} -o passwd_file=\$${F}
    echo "\$${b} has been mounted in \$${D}"
  else
    echo "\$${b} has not been mounted! Please investigate."
  fi
done

ln -s /s3xfer/S3/laa-ccms-inbound-${lz_ftp_bucket_environment}/CCMS_PRD_TDX/Inbound /home/s3xfer/CCMS_PRD_TDX_Inbound
ln -s /s3xfer/S3/laa-ccms-outbound-${lz_ftp_bucket_environment}/CCMS_PRD_TDX/Outbound /home/s3xfer/CCMS_PRD_TDX_Outbound

chown -h s3xfer:s3xfer /home/s3xfer/CCMS_PRD_TDX_Inbound
chown -h s3xfer:s3xfer /home/s3xfer/CCMS_PRD_TDX_Outbound

rm \$${F}
EOM

chmod +x /etc/mount_s3.sh

chmod +x /etc/rc.d/rc.local
echo "/etc/mount_s3.sh" >> /etc/rc.local
systemctl start rc-local.service