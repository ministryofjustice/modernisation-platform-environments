#!/bin/bash -xe
# send script output to /tmp so we can debug boot failures
# Ouput all log
exec > >(tee /tmp/userdata.log|logger -t user-data-extra -s 2>/dev/console) 2>&1

# Install AWS CLI Libs
echo "Seup AWSCLI V2....."
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install

# Part of temporary service discovery
aws s3 rm s3://dpr-working-development/rising-wave/hosts/risingwave_etcd.txt

echo "assumeyes=1" >> /etc/yum.conf

# Update all packages
sudo yum -y update

if grep ssm-user /etc/passwd &> /dev/null;
then
  echo "ssm-user already exists - skipping create"
else
  # Create the ssm-user using system defaults.
  # See /etc/default/useradd
  echo "ssm-user does not exist - creating"
  sudo useradd ssm-user --create-home
  echo "ssm-user created"

  # TODO: Remove temporary NOPASSWD used for dev
  cd /etc/sudoers.d
  echo "ssm-user ALL=(ALL) NOPASSWD:ALL" > ssm-agent-users
fi

# install etcd

sudo groupadd -f etcd
sudo useradd -d /opt/etcd -s /bin/false -g etcd etcd
cd ~

ETCD_VER=v3.5.12

# choose either URL
GOOGLE_URL=https://storage.googleapis.com/etcd
GITHUB_URL=https://github.com/etcd-io/etcd/releases/download
DOWNLOAD_URL=$GOOGLE_URL

sudo rm -f /tmp/etcd-$ETCD_VER-linux-amd64.tar.gz
sudo rm -rf /opt/etcd && mkdir -p /opt/etcd

curl -L $DOWNLOAD_URL/$ETCD_VER/etcd-$ETCD_VER-linux-amd64.tar.gz -o /tmp/etcd-$ETCD_VER-linux-amd64.tar.gz
tar xzvf /tmp/etcd-$ETCD_VER-linux-amd64.tar.gz -C /opt/etcd --strip-components=1
rm -f /tmp/etcd-$ETCD_VER-linux-amd64.tar.gz

sudo chown -R etcd:etcd /opt/etcd

ETCD_HOST_IP=$(ip addr show eth0 | grep "inet\b" | awk '{print $2}' | cut -d/ -f1)
ETCD_NAME=$(hostname -s)


service_file_contents=`cat << EOF
[Unit]
Description=etcd service
Documentation=https://github.com/coreos/etcd

[Service]
User=etcd
Type=notify
ExecStart=/opt/etcd/etcd \\
 --name $ETCD_NAME \\
 --data-dir /opt/etcd/data \\
 --initial-advertise-peer-urls http://$ETCD_HOST_IP:2380 \\
 --listen-peer-urls http://$ETCD_HOST_IP:2380 \\
 --listen-client-urls http://$ETCD_HOST_IP:2379,http://127.0.0.1:2379 \\
 --advertise-client-urls http://$ETCD_HOST_IP:2379 \\
 --initial-cluster-token etcd-cluster-1 \\
 --initial-cluster $ETCD_NAME=http://$ETCD_HOST_IP:2380 \\
 --initial-cluster-state new \\
 --heartbeat-interval 1000 \\
 --election-timeout 5000
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF`

echo "$service_file_contents" | sudo tee /lib/systemd/system/etcd.service > /dev/null


sudo systemctl daemon-reload
sudo systemctl enable etcd
sudo systemctl start etcd.service
sudo systemctl status -l etcd.service

#this_instance_id=$(cat /var/lib/cloud/data/instance-id)

# Part of temporary service discovery
# Write a file to S3 for now and rely on timings
hostname -s >risingwave_etcd.txt
aws s3 cp ./risingwave_etcd.txt s3://dpr-working-development/rising-wave/hosts/risingwave_etcd.txt
echo "Wrote etcd host file to s3 at $(date)"
rm -f ./risingwave_etcd.txt

echo "Finished setup"
