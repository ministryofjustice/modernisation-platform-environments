          #!/bin/bash

          #install missing package and hostname change
          yum -y install libXp.i386
          yum -y install sshpass
          echo "HOSTNAME="${edw_app_name}"."${edw_dns_extension}"" >> /etc/sysconfig/network

          # configure aws timesync (external ntp source)
          AwsTimeSync(){
              local RHEL=$1
              local SOURCE=169.254.169.123

              NtpD(){
                  local CONF=/etc/ntp.conf
                  sed -i 's/server \S/#server \S/g' $CONF && \
                  sed -i "20i\server $SOURCE prefer iburst" $CONF
                  /etc/init.d/ntpd status >/dev/null 2>&1 \
                      && /etc/init.d/ntpd restart || /etc/init.d/ntpd start
                  ntpq -p
              }
              ChronyD(){
                  local CONF=/etc/chrony.conf
                  sed -i 's/server \S/#server \S/g' $CONF && \
                  sed -i "7i\server $SOURCE prefer iburst" $CONF
                  systemctl status chronyd >/dev/null 2>&1 \
                      && systemctl restart chronyd || systemctl start chronyd
                  chronyc sources
              }
              case $RHEL in
                  5)
                      NtpD
                      ;;
                  7)
                      ChronyD
                      ;;
              esac
          }
          AwsTimeSync $(cat /etc/redhat-release | cut -d. -f1 | awk '{print $NF}')

          #Install AWS cli
          mkdir -p /opt/aws/bin
          cd /root
          wget https://s3.amazonaws.com/cloudformation-examples/aws-cfn-bootstrap-latest.tar.gz
          easy_install --script-dir /opt/aws/bin aws-cfn-bootstrap-latest.tar.gz
          mkdir -p /run/cfn-init # Path to store cfn-init scripts

          #configure cfn-init variables
          export ip4=$(/sbin/ip -o -4 addr list eth0 | awk '{print $4}' | cut -d/ -f1)
          export LOGS="${edw_app_name}-EC2"
          export APPNAME="${edw_app_name}"
          export ENV="${edw_environment}"
          export BACKUPBUCKET="${edw_s3_backup_bucket}"
          export ROLE="${edw_ec2_role}"
          export SECRET=`/usr/local/bin/aws --region ${edw_region} secretsmanager get-secret-value --secret-id $${terraform output -raw edw_db_secret} --query SecretString --output text`
          export host="$ip4 $APPNAME-$ENV $APPNAME.${edw_dns_extension}"
          export host2="${edw_cis_ip} cis.aws.${edw_environment}.legalservices.gov.uk"
          export host3="${edw_eric_ip} eric.aws.${edw_environment}.legalservices.gov.uk"
          export host3="${edw_ccms_ip} ccms.aws.${edw_environment}.legalservices.gov.uk"
          echo $host >>/etc/hosts
          echo $host2 >>/etc/hosts
          echo $host3 >>/etc/hosts
          mkdir -p /home/oracle/scripts
