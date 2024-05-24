#!/bin/bash -xe
# send script output to /tmp so we can debug boot failures
exec > /tmp/userdata.log 2>&1

# ENV Variables, 
namespace="dpr-nomis-port-forwarder"
app="nomis-port-forwarder"
local_port="1521"
remote_port="1521"
# Location of script that will be used to launch the domain builder jar.
nomis_portforwarder_script="/usr/bin/nomis-port-forwarder.sh"
kubeconfig="/home/ssm-user/.kube/config"

# Setup Required Directories
touch /tmp/hello-ec2
mkdir -p /opt/kinesis/scripts

# Add Kinesis Stream Directory where logs are delivered
mkdir -p /opt/kinesis/kinesis-demo-stream
#chown -R ssm-user:ssm-user /opt/kinesis/kinesis-demo-stream
#chown -R ssm-user:ssm-user /opt/kinesis
chmod -R 777 /opt/kinesis

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

echo "assumeyes=1" >> /etc/yum.conf

# Update all packages
sudo yum -y update

# Setup YUM install Kinesis Agent
sudo yum -y install aws-kinesis-agent wget unzip jq

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

# Configure and Enable Kinesis Agent
# /tmp/random.log*
# Additional Configuration here, https://docs.aws.amazon.com/streams/latest/dev/writing-with-agents.html
cat <<EOF >/etc/aws-kinesis/agent.json
{
    "cloudwatch.emitMetrics":true,
    "kinesis.endpoint":"https://kinesis.eu-west-2.amazonaws.com",
    "flows":[
       {
          "filePattern":"/opt/kinesis/kinesis-demo-stream/demo.log",
          "kinesisStream":"dpr-kinesis-data-demo-development"
       },
       {
          "filePattern":"/opt/kinesis/kinesis-demo-stream/test.log",
          "kinesisStream":"dpr-kinesis-data-demo-development"
       }, 
       {
          "filePattern": "/opt/kinesis/kinesis-demo-stream/firehose-stream.log",
          "deliveryStream": "yourfirehosedeliverystream" 
       }
    ]
 }
EOF
chmod -R 777 /opt/kinesis

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
cp_k8s_server=$(aws secretsmanager get-secret-value --secret-id external/cloud_platform/k8s_secrets | jq --raw-output '.SecretString' | jq -r .cloud_platform_k8s_server)
cp_k8s_cert_auth=$(aws secretsmanager get-secret-value --secret-id external/cloud_platform/k8s_secrets | jq --raw-output '.SecretString' | jq -r .cloud_platform_certificate_auth)
cp_k8s_cluster_name=$(aws secretsmanager get-secret-value --secret-id external/cloud_platform/k8s_secrets | jq --raw-output '.SecretString' | jq -r .cloud_platform_k8s_cluster_name)
cp_k8s_cluster_context=$(aws secretsmanager get-secret-value --secret-id external/cloud_platform/k8s_secrets | jq --raw-output '.SecretString' | jq -r .cloud_platform_k8s_cluster_context)
cp_k8s_cluster_token=$(aws secretsmanager get-secret-value --secret-id external/cloud_platform/k8s_secrets | jq --raw-output '.SecretString' | jq -r .cloud_platform_k8s_token)

echo "SERVER_NAME....$cp_k8s_server"
# Install KUBECTL Libs
## Download Libs
curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.27.1/2023-04-19/bin/linux/amd64/kubectl
chmod +x ./kubectl
cp ./kubectl /usr/bin/kubectl

mkdir -p /home/ssm-user/.kube

## Add Kubeconfig
cat <<EOF > $kubeconfig
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: $cp_k8s_cert_auth
    server: $cp_k8s_server
  name: $cp_k8s_cluster_name
contexts:
- context:
    cluster: $cp_k8s_cluster_name
    namespace: dpr-nomis-port-forwarder
    user: nomis-port-forwarder-migrated
  name: $cp_k8s_cluster_name
current-context: $cp_k8s_cluster_context
kind: Config
preferences: {}
users:
- name: nomis-port-forwarder-migrated
  user:
    token: $cp_k8s_cluster_token
EOF

# Configure Kubernetes Cluster for CP
## Permission for Config
chmod 666 $kubeconfig

# Generate a Port forwarder script 
sudo cat <<EOF > $nomis_portforwarder_script
#!/bin/bash

## Set Kube Config

kubectl config use-context live.cloud-platform.service.justice.gov.uk           
kubectl config set-cluster live.cloud-platform.service.justice.gov.uk        
kubectl config current-context

## Verify Connectivity CP K8s Cluster,
kubectl get pods

## Port forward from CP to MP
export POD=\$(kubectl get pod -n $namespace -l app=$app -o jsonpath="{.items[0].metadata.name}")
kubectl port-forward pods/\$POD $remote_port:$local_port --address='0.0.0.0'
EOF

## Add Permissions and Execute the Forwarder
chmod 0755 $nomis_portforwarder_script; su -c $nomis_portforwarder_script ssm-user
fi

# Start Stream at Start of the EC2 
sudo chkconfig aws-kinesis-agent on
sudo service aws-kinesis-agent start
sudo systemctl start amazon-ssm-agent
sudo systemctl enable amazon-ssm-agent