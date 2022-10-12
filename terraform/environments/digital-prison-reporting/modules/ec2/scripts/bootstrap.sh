#!/bin/bash -xe
# send script output to /tmp so we can debug boot failures
exec > /tmp/userdata.log 2>&1

echo test of user_data | sudo tee /tmp/user_data.log

# Setup Required Directories
touch /tmp/hello-ec2
mkdir -p /opt/kinesis/scripts

# Add Kinesis Stream Directory where logs are delivered
mkdir -p /opt/kinesis/kinesis-demo-stream
chown -R 775 /opt/kinesis/kinesis-demo-stream

# Update all packages
yum -y update

# Setup YUM install Kinesis Agent
sudo yum install –y aws-kinesis-agent

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
          "kinesisStream":"dpr-kinesis-demo-stream-development"
       },
       {
          "filePattern":"/opt/kinesis/kinesis-demo-stream/test.log",
          "kinesisStream":"dpr-kinesis-demo-stream-development"
       }, 
       {
          "filePattern": "/opt/kinesis/kinesis-demo-stream/firehose-stream.log",
          "deliveryStream": "yourfirehosedeliverystream" 
       }
    ]
 }
EOF

# Start Stream at Start of the EC2
sudo chkconfig aws-kinesis-agent on