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

echo "Setting up EFS File System"
# Mount FS
mkdir /efs-mount-point
mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport fs-08a0fe185d47b1189.efs.eu-west-2.amazonaws.com:/ /efs-mount-point
chown -R ssm-user /efs-mount-point
chmod +x /efs-mount-point

# Update all packages
sudo yum -y update

# Setup YUM install Kinesis Agent
sudo yum -y install aws-kinesis-agent wget unzip

# Setup Oracle Client Tools
sudo yum install https://yum.oracle.com/repo/OracleLinux/OL7/oracle/instantclient21/x86_64/getPackage/oracle-instantclient-basic-21.8.0.0.0-1.x86_64.rpm
sudo yum install https://yum.oracle.com/repo/OracleLinux/OL7/oracle/instantclient21/x86_64/getPackage/oracle-instantclient-tools-21.8.0.0.0-1.x86_64.rpm
sudo yum install https://yum.oracle.com/repo/OracleLinux/OL7/oracle/instantclient21/x86_64/getPackage/oracle-instantclient-devel-21.8.0.0.0-1.x86_64.rpm
sudo yum install https://yum.oracle.com/repo/OracleLinux/OL7/oracle/instantclient21/x86_64/getPackage/oracle-instantclient-sqlplus-21.8.0.0.0-1.x86_64.rpm

# Install Postgresql
sudo amazon-linux-extras install postgresql10

# Install SSM Agent
#cd /tmp
#sudo yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm

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
    certificate-authority-data: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUN5RENDQWJDZ0F3SUJBZ0lCQURBTkJna3Foa2lHOXcwQkFRc0ZBREFWTVJNd0VRWURWUVFERXdwcmRXSmwKY201bGRHVnpNQjRYRFRJeE1EWXlPREUyTXprMU5sb1hEVE14TURZeU5qRTJNemsxTmxvd0ZURVRNQkVHQTFVRQpBeE1LYTNWaVpYSnVaWFJsY3pDQ0FTSXdEUVlKS29aSWh2Y05BUUVCQlFBRGdnRVBBRENDQVFvQ2dnRUJBTDNZCk9jcWxuVUdZTGR6TFlZTFcyOHVVWk1QdGE3TWJTK09EbTh4RWNXNlRVMXoyeFovcUNwSUhRS0VGelk2SWJwVSsKaHB0Z2VrRnNKQllEc2pjRjhRSTNPSkFaMFVjMXpNaXo1TFE2ZU1pOENsbmRMYnk4NWRNLzliRGZ0T1dlMDVqcQpYSENmYW9RNWR0Y3NCbWplWFAzbm1ZZGRJcTBiRUZZMTJiQjkvOTRLRVJSdnp4U3oxNkg5VkJwdzA3UVArTFRTCnRKT2JjWWlzcEFSTXJUVTlZa1pVS1lJT2FUYnBqRHhHVGdMNm1EaWNSdHlQeU9admx0MUFSTFR3NUpBVG42WUYKaXNCMkt5cHA2Q05DNDVoaFVpU05vZE9vaUcxNVRpNU5WeWM5azQ4eTFqZWExZ0kzTnM0VGFpQXRxNEhPTHR3NQpML2RqMEFRTTJIalZlVG90TVJVQ0F3RUFBYU1qTUNFd0RnWURWUjBQQVFIL0JBUURBZ0trTUE4R0ExVWRFd0VCCi93UUZNQU1CQWY4d0RRWUpLb1pJaHZjTkFRRUxCUUFEZ2dFQkFHUCs2RTZCMDVNSmxFZ04zcEJkRUxEa29yakEKMGJ0SmR2S1lEakkyWTE0cGtSMFlacXZjT2Zkd0tOM1VuL2FYblllT21xNFExdHRpMUZQRDR6MTE0TFU4VjBTcwo3Q080azE5NzNMVGxValRGTVZNNHZoZXlXc0JLRzJxZW10TGhkVjJGSDh1Y2lDZnVWd0hNb3lQTmJJdktCSVFOCnFIS08wclU0bElpSzVrcEdydXBZYWRIV3pLL0VMTlk5alZtelJxcXpGQ3lmVjJuWGZJK2xrbXFUOGN5Y0FWbS8KOExSQjhnK1dhTGxLQThydWMzYmZIWUJNZ2J1ZkpzYTVaU3lGd2dkNlNua0dta1c2KzBERklRUVAweEl5ajRaWgpFL1JxL0QyNE5zK2ZNc3lxWVRUQ21rRktUdTJENzJvQllUdmt5bnQ3Rjh3a0gwSWRiK1MxMXNxUVdCcz0KLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQo=
    server: https://DF366E49809688A3B16EEC29707D8C09.gr7.eu-west-2.eks.amazonaws.com
  name: live.cloud-platform.service.justice.gov.uk
contexts:
- context:
    cluster: live.cloud-platform.service.justice.gov.uk
    namespace: dpr-nomis-port-forwarder
    user: nomis-port-forwarder
  name: live.cloud-platform.service.justice.gov.uk
current-context: live.cloud-platform.service.justice.gov.uk
kind: Config
preferences: {}
users:
- name: nomis-port-forwarder
  user:
    token: eyJhbGciOiJSUzI1NiIsImtpZCI6IlBiS0MzZGN6a1IwbFljNkNOd1dVODY2OXQzLW0tOWRKZ1dpNEdRTG9LOUkifQ.eyJpc3MiOiJrdWJlcm5ldGVzL3NlcnZpY2VhY2NvdW50Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9uYW1lc3BhY2UiOiJkcHItbm9taXMtcG9ydC1mb3J3YXJkZXIiLCJrdWJlcm5ldGVzLmlvL3NlcnZpY2VhY2NvdW50L3NlY3JldC5uYW1lIjoibm9taXMtcG9ydC1mb3J3YXJkZXItdG9rZW4tdGttMmgiLCJrdWJlcm5ldGVzLmlvL3NlcnZpY2VhY2NvdW50L3NlcnZpY2UtYWNjb3VudC5uYW1lIjoibm9taXMtcG9ydC1mb3J3YXJkZXIiLCJrdWJlcm5ldGVzLmlvL3NlcnZpY2VhY2NvdW50L3NlcnZpY2UtYWNjb3VudC51aWQiOiJjZTgwMmMwYy1mNTAwLTRmZDctOTYwZi1jNjAyNDg2YzE4NzEiLCJzdWIiOiJzeXN0ZW06c2VydmljZWFjY291bnQ6ZHByLW5vbWlzLXBvcnQtZm9yd2FyZGVyOm5vbWlzLXBvcnQtZm9yd2FyZGVyIn0.IwnZVyoQCTdQO19NgjAPP88lR6dfRHV014gFnMo4HxaUMv8rIh-UU65hFbK4u0NHQrOD0qr1atIvEEhzXMACKEeWti28SmGK9T2wc4EY7WJzimojjflE3ay9szwET2NeAG9QLD8fhtrOjAY2eScM_SdSyjHXxwkrD2tihMjEIxUJWffCRdjk0-dHAyqzX2Y-CPijrK9QEr7JSSKQWFR1o2yPnqGzJGgCmqdvd0mCtmEttsD4CHM8fiIRWrQkZh9dtZwdbP4NXpDT6dd5S6TpRB5URd5qE7NeMhOzc6MCoeP_YVeekj7MA7OZC5jWFN1t4pcUbAGvLxuO9qOuKG1lww
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