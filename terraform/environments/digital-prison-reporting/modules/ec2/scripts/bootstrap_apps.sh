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
custom_cw_monitor_config="/usr/bin/dpr-custom-amazon-cloudwatch-agent.json"
custom_cw_monitor_script="/usr/bin/dpr_custom_cw_monitor_services.sh"

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

# Add ssm-user to SUDO group
sudo usermod -aG wheel ssm-user

echo "assumeyes=1" >> /etc/yum.conf

# Update all packages
sudo yum -y update

# Setup YUM install Kinesis Agent
sudo yum -y install aws-kinesis-agent amazon-cloudwatch-agent wget unzip jq

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


# Create CloudWatch Agent configuration file with custom metrics
cat << 'CONFIG_EOF' > $custom_cw_monitor_config
{
  "agent": {
    "metrics_collection_interval": 60,
    "logfile": "/opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log",
    "log_level": "debug"
  },
  "metrics": {
    "namespace": "DPRAgentCustomMetrics",    
    "append_dimensions": {
      "AutoScalingGroupName": "$${aws:AutoScalingGroupName}",
      "InstanceId": "$${aws:InstanceId}",
      "InstanceType": "$${aws:InstanceType}"
    },
    "metrics_collected": {
      "cpu": {
        "measurement": [
          "cpu_usage_idle",
          "cpu_usage_iowait",
          "cpu_usage_user",
          "cpu_usage_system"
        ],
        "metrics_collection_interval": 60,
        "totalcpu": false
      },
      "disk": {
        "measurement": [
          "used_percent",
          "inodes_free"
        ],
        "metrics_collection_interval": 60,
        "resources": [
          "/",
          "/mnt"
        ]
      },
      "mem": {
        "measurement": [
          "mem_used_percent",
          "mem_available_percent"
        ],
        "metrics_collection_interval": 60
      },
      "swap": {
        "measurement": [
          "swap_used_percent"
        ],
        "metrics_collection_interval": 60
      },
      "netstat": {
        "measurement": [
          "tcp_established",
          "tcp_time_wait",
          "tcp_close"
        ],
        "metrics_collection_interval": 60
      },
      "processes": {
        "measurement": [
          "running",
          "sleeping",
          "dead"
        ],
        "metrics_collection_interval": 60
      },
      "exec": {
        "commands": [
          "/usr/bin/dpr_custom_cw_monitor_services.sh"
        ],
        "timeout": 600,
        "measurement": [
          "dpr_custom_nomispf_status",
          "dpr_custom_bodmispf_status",
          "dpr_custom_nomispf_uptime",
          "dpr_custom_bodmispf_uptime"
        ],
        "metrics_collection_interval": 60
      }
    }
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/messages",
            "log_group_name": "var-log-messages",
            "log_stream_name": "{instance_id}"
          },
          {
            "file_path": "/var/log/cloud-init.log",
            "log_group_name": "cloud-init-log",
            "log_stream_name": "{instance_id}"
          }
        ]
      }
    }
  }
}
CONFIG_EOF

# Create the service monitoring script
cat << 'SCRIPT_EOF' > $custom_cw_monitor_script
#!/bin/bash

# Function to get service status
get_service_status() {
  local service_name=$1
  systemctl is-active --quiet $service_name
  if [ $? -eq 0 ]; then
    echo "1"  # Service is running
  else
    echo "0"  # Service is not running
  fi
}

# Function to get service uptime in seconds
get_service_uptime() {
  local service_name=$1
  local start_timestamp=$(systemctl show "$service_name" -p ActiveEnterTimestamp | cut -d '=' -f2)
  
  if [[ -n "$start_timestamp" ]]; then
    # Convert timestamp to seconds since epoch
    local start_epoch=$(date +%s -d "$start_timestamp")
    local current_epoch=$(date +%s)
    echo $((current_epoch - start_epoch))
  else
    echo "0"  # Service not running or no timestamp found
  fi
}

# Get status of nomispf.service
nomispf_status=$(get_service_status "nomispf.service")
# Get uptime of nomispf.service
nomispf_uptime=$(get_service_uptime "nomispf.service")

# Get status of bodmispf.service
bodmispf_status=$(get_service_status "bodmispf.service")
# Get uptime of bodmispf.service
bodmispf_uptime=$(get_service_uptime "bodmispf.service")

# Output in JSON format for CloudWatch Agent exec plugin
cat <<EOF
{
  "dpr_custom_nomispf_status": $nomispf_status,
  "dpr_custom_bodmispf_status": $bodmispf_status,
  "dpr_custom_nomispf_uptime": $nomispf_uptime,
  "dpr_custom_bodmispf_uptime": $bodmispf_uptime
}
EOF
SCRIPT_EOF

chmod +x $custom_cw_monitor_script

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

# Start Stream at Start of the EC2 
# sudo chkconfig aws-kinesis-agent on
# sudo service aws-kinesis-agent start
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

# Start CloudWatch Agent with the configuration
# Add correct User Group to amazon-cloudwatch-agent
sudo chown ssm-user:root /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.d/
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:$custom_cw_monitor_config -s

#Verify CloudWatch Agent is running
systemctl enable amazon-cloudwatch-agent
systemctl start amazon-cloudwatch-agent
