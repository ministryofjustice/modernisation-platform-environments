#!/bin/bash
set -e

yum update -y
yum install -y rsyslog amazon-cloudwatch-agent

mkdir -p /var/log/remote-syslog
chmod 755 /var/log/remote-syslog

cat <<EOF >> /etc/rsyslog.conf
module(load="imudp")
input(type="imudp" port="514")
module(load="imtcp")
input(type="imtcp" port="514")

if \$programname == 'clamav' then /var/log/remote-syslog/clamav.log
if \$programname == 'ossec' then /var/log/remote-syslog/OSSecurity.log
if \$programname == 'systemd' then /var/log/remote-syslog/OSSystem.log

*.* /var/log/remote-syslog/general.log
EOF

systemctl enable rsyslog
systemctl restart rsyslog

mkdir -p /opt/aws/amazon-cloudwatch-agent/bin

cat <<EOF > /opt/aws/amazon-cloudwatch-agent/bin/config.json
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/remote-syslog/clamav.log",
            "log_group_name": "yjaf-juniper/clamav",
            "log_stream_name": "{instance_id}/clamav",
            "timestamp_format": "%b %d %H:%M:%S"
          },
          {
            "file_path": "/var/log/remote-syslog/OSSecurity.log",
            "log_group_name": "yjaf-juniper/OSSecurity",
            "log_stream_name": "{instance_id}/OSSecurity",
            "timestamp_format": "%b %d %H:%M:%S"
          },
          {
            "file_path": "/var/log/remote-syslog/OSSystem.log",
            "log_group_name": "yjaf-juniper/OSSystem",
            "log_stream_name": "{instance_id}/OSSystem",
            "timestamp_format": "%b %d %H:%M:%S"
          },
          {
            "file_path": "/var/log/remote-syslog/general.log",
            "log_group_name": "yjaf-juniper/rsyslog",
            "log_stream_name": "{instance_id}/rsyslog",
            "timestamp_format": "%b %d %H:%M:%S"
          }
        ]
      }
    }
  }
}
EOF

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -c file:/opt/aws/amazon-cloudwatch-agent/bin/config.json \
  -s