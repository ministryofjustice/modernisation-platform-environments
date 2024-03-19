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
sudo yum -y install aws-kinesis-agent wget unzip

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
    user: nomis-port-forwarder-migrated
  name: live.cloud-platform.service.justice.gov.uk
current-context: live.cloud-platform.service.justice.gov.uk
kind: Config
preferences: {}
users:
- name: nomis-port-forwarder-migrated
  user:
    token: ZXlKaGJHY2lPaUpTVXpJMU5pSXNJbXRwWkNJNklsQmlTME16WkdONmExSXdiRmxqTmtOT2QxZFZPRFkyT1hRekxXMHRPV1JLWjFkcE5FZFJURzlMT1VraWZRLmV5SnBjM01pT2lKcmRXSmxjbTVsZEdWekwzTmxjblpwWTJWaFkyTnZkVzUwSWl3aWEzVmlaWEp1WlhSbGN5NXBieTl6WlhKMmFXTmxZV05qYjNWdWRDOXVZVzFsYzNCaFkyVWlPaUprY0hJdGJtOXRhWE10Y0c5eWRDMW1iM0ozWVhKa1pYSWlMQ0pyZFdKbGNtNWxkR1Z6TG1sdkwzTmxjblpwWTJWaFkyTnZkVzUwTDNObFkzSmxkQzV1WVcxbElqb2libTl0YVhNdGNHOXlkQzFtYjNKM1lYSmtaWEl0YldsbmNtRjBaV1F0ZEc5clpXNHRNREV0TURFdE1qQXdNQ0lzSW10MVltVnlibVYwWlhNdWFXOHZjMlZ5ZG1salpXRmpZMjkxYm5RdmMyVnlkbWxqWlMxaFkyTnZkVzUwTG01aGJXVWlPaUp1YjIxcGN5MXdiM0owTFdadmNuZGhjbVJsY2kxdGFXZHlZWFJsWkNJc0ltdDFZbVZ5Ym1WMFpYTXVhVzh2YzJWeWRtbGpaV0ZqWTI5MWJuUXZjMlZ5ZG1salpTMWhZMk52ZFc1MExuVnBaQ0k2SWpkak9HSXlNVGxsTFRKbU5HRXROREk0WWkxaVl6ZGlMV1UwTjJJeE5qa3paR1ppWkNJc0luTjFZaUk2SW5ONWMzUmxiVHB6WlhKMmFXTmxZV05qYjNWdWREcGtjSEl0Ym05dGFYTXRjRzl5ZEMxbWIzSjNZWEprWlhJNmJtOXRhWE10Y0c5eWRDMW1iM0ozWVhKa1pYSXRiV2xuY21GMFpXUWlmUS5SMFk5a1Z6ZVRFLUJjZDR0d0hOTldGZmZHdmluMXlheWp0ZGVRU2pOVm1RQkQ0MnZhemNFd2JyOEgzRjVpMkE1d1c4ajVUa19JWXpEN1pieTI2enlJaXVfREY4RFhlLWJFUlFFSEZhLUE2cHl5Z25HUVBkV2NEbFpTa2xHQUhCbVVtUUg1cktUcUtEVmZGVzhncFA1OGg4elAzTDUxOHBCVzZlR2ktM0dUZUpIMXBOTDdzQVZ3QWFLRW1iSFdxTVNjQ2lyN0cyMk1DRll3bFZ5VVRhcnVlRkdMeFIwZklkNHkyZUhGQ2FybFNCa0tTUzQ4ZXdDOVdHQ3Aya25KUlpVUndkWm1sU0dHTzJtQVQ0THFxMDZacklId2VfTFVZYzhoc1djVlNHeHFQd2hkckhDbUljbWhYS3o2Tk1Fd0ZwUjZLTm9SQkJBSHppQ2d1ckpRSHpkS0E=
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