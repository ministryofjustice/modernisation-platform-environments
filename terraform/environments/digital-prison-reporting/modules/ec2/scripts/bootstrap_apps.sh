#!/bin/bash -xe
# send script output to /tmp so we can debug boot failures 
exec > /tmp/userdata.log 2>&1

# ENV Variables, 
namespace="dpr-nomis-port-forwarder"
app="nomis-port-forwarder"
bodmis_namespace="dpr-bodmis-port-forwarder"
bodmis_app="bodmis-port-forwarder"
local_port="1521"
bodmis_local_port="1522"
remote_port="1521"
# Location of script that will be used to launch the domain builder jar.
nomis_portforwarder_script="/usr/bin/nomispf.sh"
bodmis_portforwarder_script="/usr/bin/bodmispf.sh"
kubeconfig="/home/ssm-user/.kube/config"
bodmis_kubeconfig="/home/ssm-user/.kube/bodmis_config"

# Setup Required Directories
touch /tmp/hello-ec2

if grep ssm-user /etc/passwd &> /dev/null;
then
  echo "ssm-user already exists - skipping create"
else
  # Create the ssm-user using system defaults.
  # See /etc/default/useradd
  echo "ssm-user does not exist - creating"
  sudo useradd ssm-user --create-home
  echo "ssm-user created"
fi

# Add ssm-user to sudoers temporarily (optional)
echo 'ssm-user ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/ssm-user
chmod 440 /etc/sudoers.d/ssm-user

echo "assumeyes=1" >> /etc/yum.conf

# Update all packages
sudo yum -y update

# Setup YUM install Kinesis Agent
sudo yum -y install wget unzip jq

# Setup Oracle Client Tools
sudo yum install https://yum.oracle.com/repo/OracleLinux/OL7/oracle/instantclient21/x86_64/getPackage/oracle-instantclient-basic-21.8.0.0.0-1.x86_64.rpm
sudo yum install https://yum.oracle.com/repo/OracleLinux/OL7/oracle/instantclient21/x86_64/getPackage/oracle-instantclient-tools-21.8.0.0.0-1.x86_64.rpm
sudo yum install https://yum.oracle.com/repo/OracleLinux/OL7/oracle/instantclient21/x86_64/getPackage/oracle-instantclient-devel-21.8.0.0.0-1.x86_64.rpm
sudo yum install https://yum.oracle.com/repo/OracleLinux/OL7/oracle/instantclient21/x86_64/getPackage/oracle-instantclient-sqlplus-21.8.0.0.0-1.x86_64.rpm
echo "Oracle Client Libs Installed okay !"

# Install SSM Agent, if it is not installed already
cd /tmp
rpm -qa | grep amazon-ssm-agent || yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
echo "SSM Agent Libs Installed okay !"

# Install Postgresql
sudo amazon-linux-extras install postgresql10

# CLI Install
echo "Seup AWSCLI V2....."
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install

# Configure MP -> NOMIS Connectivity, for Development Env Workaround
if [ ${environment} = "development" ]; then

# Add Secondary IP
# Get the Network Interface ID
interface_id=`aws ec2 describe-network-interfaces --region eu-west-2  --filters Name=attachment.instance-id,Values=$(aws sts get-caller-identity --query UserId --output text | cut -d : -f 2) --query "NetworkInterfaces[0].NetworkInterfaceId" --output text`
echo "___Interface ID: $interface_id"

sleep 300
# Add Secondary IP
aws ec2 assign-private-ip-addresses --network-interface-id $interface_id --private-ip-addresses ${static_ip}

# Get Secrets
nomis_cp_k8s_server=$(aws secretsmanager get-secret-value --secret-id external/cloud_platform/k8s_auth | jq --raw-output '.SecretString' | jq -r .cloud_platform_k8s_server)
nomis_cp_k8s_cert_auth=$(aws secretsmanager get-secret-value --secret-id external/cloud_platform/k8s_auth | jq --raw-output '.SecretString' | jq -r .cloud_platform_certificate_auth)
nomis_cp_k8s_cluster_name=$(aws secretsmanager get-secret-value --secret-id external/cloud_platform/k8s_auth | jq --raw-output '.SecretString' | jq -r .cloud_platform_k8s_cluster_name)
nomis_cp_k8s_cluster_context=$(aws secretsmanager get-secret-value --secret-id external/cloud_platform/k8s_auth | jq --raw-output '.SecretString' | jq -r .cloud_platform_k8s_cluster_context)
nomis_cp_k8s_cluster_token=$(aws secretsmanager get-secret-value --secret-id external/cloud_platform/k8s_auth | jq --raw-output '.SecretString' | jq -r .cloud_platform_k8s_token)

echo "SERVER_NAME....$nomis_cp_k8s_server"
# Install KUBECTL Libs
## Download Libs
curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.27.1/2023-04-19/bin/linux/amd64/kubectl
chmod +x ./kubectl
cp ./kubectl /usr/bin/kubectl

mkdir -p /home/ssm-user/.kube
chown -R ssm-user:ssm-user /home/ssm-user/.kube
chmod -R 755 /home/ssm-user/.kube

# NOMIS
## Add Kubeconfig
cat <<EOF > $kubeconfig
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: $nomis_cp_k8s_cert_auth
    server: $nomis_cp_k8s_server
  name: $nomis_cp_k8s_cluster_name
contexts:
- context:
    cluster: $nomis_cp_k8s_cluster_name
    namespace: dpr-nomis-port-forwarder
    user: nomis-port-forwarder-migrated
  name: $nomis_cp_k8s_cluster_name
current-context: $nomis_cp_k8s_cluster_context
kind: Config
preferences: {}
users:
- name: nomis-port-forwarder-migrated
  user:
    token: $nomis_cp_k8s_cluster_token
EOF

# NOMIS
## Permission for Config
chmod 0755 $kubeconfig

# NOMIS
# Generate a Port forwarder script 
sudo cat <<EOF > $nomis_portforwarder_script
#!/bin/bash

unset KUBE_CONFIG; unset KUBECONFIG

export KUBE_CONFIG=$kubeconfig
export KUBECONFIG=$kubeconfig

## Set Kube Config

kubectl config use-context live.cloud-platform.service.justice.gov.uk           
kubectl config set-cluster live.cloud-platform.service.justice.gov.uk        
kubectl config current-context

## Verify Connectivity CP K8s Cluster,
kubectl get pods

## Port forward from CP to MP
export POD=\$(kubectl get pod -n $namespace -l app=$app -o jsonpath="{.items[0].metadata.name}")
kubectl port-forward pods/\$POD $local_port:$remote_port --address='0.0.0.0'
EOF
###

# BODMIS PortForwarding
# Get Secrets
bodmis_cp_k8s_server=$(aws secretsmanager get-secret-value --secret-id external/cloud_platform/bodmis_k8s_auth | jq --raw-output '.SecretString' | jq -r .cloud_platform_k8s_server)
bodmis_cp_k8s_cert_auth=$(aws secretsmanager get-secret-value --secret-id external/cloud_platform/bodmis_k8s_auth | jq --raw-output '.SecretString' | jq -r .cloud_platform_certificate_auth)
bodmis_cp_k8s_cluster_name=$(aws secretsmanager get-secret-value --secret-id external/cloud_platform/bodmis_k8s_auth | jq --raw-output '.SecretString' | jq -r .cloud_platform_k8s_cluster_name)
bodmis_cp_k8s_cluster_context=$(aws secretsmanager get-secret-value --secret-id external/cloud_platform/bodmis_k8s_auth | jq --raw-output '.SecretString' | jq -r .cloud_platform_k8s_cluster_context)
bodmis_cp_k8s_cluster_token=$(aws secretsmanager get-secret-value --secret-id external/cloud_platform/bodmis_k8s_auth | jq --raw-output '.SecretString' | jq -r .cloud_platform_k8s_token)

echo "SERVER_NAME....$bodmis_cp_k8s_server"
## Add Kubeconfig
cat <<EOF > $bodmis_kubeconfig
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: $bodmis_cp_k8s_cert_auth
    server: $bodmis_cp_k8s_server
  name: $bodmis_cp_k8s_cluster_name
contexts:
- context:
    cluster: $bodmis_cp_k8s_cluster_name
    namespace: dpr-bodmis-port-forwarder
    user: bodmis-port-forwarder-migrated
  name: $bodmis_cp_k8s_cluster_name
current-context: $bodmis_cp_k8s_cluster_context
kind: Config
preferences: {}
users:
- name: bodmis-port-forwarder-migrated
  user:
    token: $bodmis_cp_k8s_cluster_token
EOF

###

# Configure Kubernetes Cluster for CP
## Permission for Config
chmod 0755 $bodmis_kubeconfig

# BODMIS
# Generate a Port forwarder script 
sudo cat <<EOF > $bodmis_portforwarder_script
#!/bin/bash

unset KUBE_CONFIG; unset KUBECONFIG

export KUBE_CONFIG=$bodmis_kubeconfig
export KUBECONFIG=$bodmis_kubeconfig

## Set Kube Config

kubectl config use-context live.cloud-platform.service.justice.gov.uk           
kubectl config set-cluster live.cloud-platform.service.justice.gov.uk        
kubectl config current-context

## Verify Connectivity CP K8s Cluster,
kubectl get pods

## Port forward from CP to MP
export POD=\$(kubectl get pod -n $bodmis_namespace -l app=$bodmis_app -o jsonpath="{.items[0].metadata.name}")
kubectl port-forward pods/\$POD $bodmis_local_port:$remote_port --address='0.0.0.0'
EOF

## Add Permissions and Execute the Nomis and Bodmis Port Forwarders
#chmod 0755 $nomis_portforwarder_script; su -c $nomis_portforwarder_script ssm-user
#chmod 0755 $bodmis_portforwarder_script; su -c $bodmis_portforwarder_script ssm-user
chmod 0755 $nomis_portforwarder_script; chmod 0755 $bodmis_portforwarder_script

# Create a systemd service for Nomis PortForward
cat <<EOL > /etc/systemd/system/nomispf.service
[Unit]
Description=NOMIS PortForward Service
StartLimitIntervalSec=300  # Increase interval for better fault tolerance
StartLimitBurst=3          # Reduce burst to avoid frequent restarts in short time

[Service]
ExecStart=$nomis_portforwarder_script
Restart=on-failure      # Restart only on failure to avoid restarting on manual stops
RestartSec=10           # Increase delay slightly to give time for underlying issues to be resolved
TimeoutSec=30           # Add a timeout to gracefully handle any potential hanging

[Install]
WantedBy=multi-user.target
EOL

# Create a systemd service for Bodmis PortForward
cat <<EOL > /etc/systemd/system/bodmispf.service
[Unit]
Description=BODMIS PortForward Service
StartLimitIntervalSec=300  # Increase interval for better fault tolerance
StartLimitBurst=3          # Reduce burst to avoid frequent restarts in short time

[Service]
ExecStart=$bodmis_portforwarder_script
Restart=on-failure      # Restart only on failure to avoid restarting on manual stops
RestartSec=10           # Increase delay slightly to give time for underlying issues to be resolved
TimeoutSec=30           # Add a timeout to gracefully handle any potential hanging

[Install]
WantedBy=multi-user.target
EOL


fi

systemctl daemon-reload

# NOMIS PF Service 
sudo systemctl enable nomispf.service
sudo systemctl start nomispf.service

# BODMIS PF Service 
sudo systemctl enable bodmispf.service
sudo systemctl start bodmispf.service

# AMAZON SSM SGENT
sudo systemctl start amazon-ssm-agent
sudo systemctl enable amazon-ssm-agent

## ODATA DEMO
set -euxo pipefail

# Clean and update
yum clean metadata
yum update -y

# Install Java 21 safely
# Optional: remove older versions
yum remove -y java-11-amazon-corretto java-17-amazon-corretto || true

# Download Amazon Corretto 21 RPM
cd /tmp
wget https://corretto.aws/downloads/latest/amazon-corretto-21-x64-linux-jdk.rpm

# Install the RPM
yum localinstall -y amazon-corretto-21-x64-linux-jdk.rpm

# Register with alternatives and set as default
alternatives --install /usr/bin/java java /usr/lib/jvm/java-21-amazon-corretto/bin/java 2100
alternatives --set java /usr/lib/jvm/java-21-amazon-corretto/bin/java

# Confirm version
java -version

# Cleanup
rm -f /tmp/amazon-corretto-21-x64-linux-jdk.rpm

# Set up service (ODATA)
#mkdir -p /opt/odata-demo
#cd /opt/odata-demo
#aws s3 cp s3://dpr-artifact-store-development/third-party/odata-demo/OData-demo-0.0.1-SNAPSHOT.jar ./OData-demo.jar
#chown -R ec2-user:ec2-user /opt/odata-demo

#cat <<EOF > /etc/systemd/system/odata-demo.service
#[Unit]
#Description=OData Demo Java Service
#After=network.target

#[Service]
#WorkingDirectory=/opt/odata-demo
#ExecStart=/usr/bin/java -jar /opt/odata-demo/OData-demo.jar
#SuccessExitStatus=143
#Restart=on-failure
#RestartSec=10

#[Install]
#WantedBy=multi-user.target
#EOF

# Configure MP -> NOMIS Connectivity, for Development Env Workaround
if [ ${environment} = "development" ]; then
# Set up service (headless BI)
mkdir -p /opt/headless-bi
cd /opt/headless-bi

# Check if UNZIP exists
command -v unzip >/dev/null 2>&1 || yum install -y unzip

# Download and unzip JAR
#aws s3 cp s3://dpr-artifact-store-development/third-party/headless-bi/hmpps-probation-headless-bi-poc.jar ./headless-bi.jar
aws s3 cp s3://dpr-artifact-store-development/third-party/zip_files/hmpps-probation-headless-bi-poc/hmpps-probation-headless-bi-poc.jar.zip ./hmpps-probation-headless-bi-poc.jar.zip
unzip ./hmpps-probation-headless-bi-poc.jar.zip

# Set correct ownership
chown -R ec2-user:ec2-user /opt/headless-bi

# Create systemd service
cat <<EOF > /etc/systemd/system/headless-bi.service
[Unit]
Description=headless-bi Java Service
After=network.target

[Service]
WorkingDirectory=/opt/headless-bi
ExecStart=/usr/bin/java -jar /opt/headless-bi/hmpps-probation-headless-bi-poc.jar --spring.profiles.active=dev
User=ec2-user
Group=ec2-user
SuccessExitStatus=143
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Enable and start service
systemctl daemon-reload
systemctl enable headless-bi.service
systemctl start headless-bi.service

# Verify Service
echo "_____ Check if Headless BI Service..."
systemctl status headless-bi.service --no-pager
fi