#!/bin/bash -xe
# send script output to /tmp so we can debug boot failures
exec > /tmp/userdata.log 2>&1

echo test of user_data | sudo tee /tmp/user_data.log

# Setup Required Directories
touch /tmp/hello-ec2
mkdir -p /opt/kinesis/scripts

# Add Kinesis Stream Directory where logs are delivered
mkdir -p /opt/kinesis/kinesis-demo-stream
#chown -R ssm-user:ssm-user /opt/kinesis/kinesis-demo-stream
#chown -R ssm-user:ssm-user /opt/kinesis
chmod -R 777 /opt/kinesis

echo "assumeyes=1" >> /etc/yum.conf

# Update all packages
sudo yum -y update

# Setup YUM install Kinesis Agent
sudo yum -y install aws-kinesis-agent

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

# Install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

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

# Start Stream at Start of the EC2
sudo chkconfig aws-kinesis-agent on
sudo service aws-kinesis-agent start