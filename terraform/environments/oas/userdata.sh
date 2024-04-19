#!/bin/bash

cd /tmp
yum -y install sshpass
yum -y install jq
sudo yum -y install xorg-x11-xauth
sudo yum -y install xclock xterm
sudo yum -y install nvme-cli

hostnamectl set-hostname oas

sed -i '2s/.*/search laa-development.modernisation-platform.service.justice.gov.uk eu-west-2.compute.internal/' /etc/resolv.conf

yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
systemctl start amazon-ssm-agent
systemctl enable amazon-ssm-agent
systemctl stop firewalld
systemctl disable firewalld

declare -A MOUNTS=(
    [/dev/sdb]="/oracle/software"
    [/dev/sdc]="/stage"
)

EFSTAB="/etc/fstab"

# Assuming ebsnvme-id is a custom script to map NVMe device to EBS volume
declare -A NVMES=()
for n in /dev/nvme*n1; do
    D=$(ebsnvme-id "${n}" | grep -v 'Volume ID')
    if [[ -n ${D} ]]; then
        if [[ ${D} =~ /dev ]]; then
            NVMES[${D}]=${n}
        else
            NVMES[/dev/${D}]=${n}
        fi
    fi
done

for M in "${!MOUNTS[@]}"; do
    L=${MOUNTS[${M}]}
    N=${NVMES[${M}]}
    if [[ -n ${N} ]]; then
        FS_DIR="${L}"
        if ! mountpoint -q "${FS_DIR}"; then
            mkfs.ext4 "${M}"
            mkdir -p "${FS_DIR}"
            echo "${M} ${FS_DIR} ext4 defaults 0 0" >> "${EFSTAB}"
            mount "${M}" "${FS_DIR}"
        else
            echo "${FS_DIR} is already mounted:"
            mount | grep "${FS_DIR}"
        fi
    fi
done

mount -a

chown oracle:dba /oracle/software
chown oracle:dba /stage
chmod -R 777 /stage
chmod -R 777 /oracle/software
dd if=/dev/zero of=/root/myswapfile bs=1M count=1024
chmod 600 /root/myswapfile
mkswap /root/myswapfile
swapon /root/myswapfile
echo "/root/myswapfile swap swap defaults 0 0" >> /etc/fstab

ntp_config(){
    local RHEL=$(cat /etc/redhat-release | cut -d. -f1 | awk '{print $NF}')
    local SOURCE=169.254.169.123

    NtpD(){
        local CONF=/etc/ntp.conf
        sed -i 's/server \S/#server \S/g' ${CONF} && \
        sed -i "20i\server ${SOURCE} prefer iburst" ${CONF}
        /etc/init.d/ntpd status >/dev/null 2>&1 \
            && /etc/init.d/ntpd restart || /etc/init.d/ntpd start
        ntpq -p
    }
    ChronyD(){
        local CONF=/etc/chrony.conf
        sed -i 's/server \S/#server \S/g' ${CONF} && \
        sed -i "7i\server ${SOURCE} prefer iburst" ${CONF}
        systemctl status chronyd >/dev/null 2>&1 \
            && systemctl restart chronyd || systemctl start chronyd
        chronyc sources
    }
    case ${RHEL} in
        5)
            NtpD
            ;;
        7)
            ChronyD
            ;;
    esac
}

# Retrieve instance ID and store it in a file
aws_instance_id=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
echo -n "${aws_instance_id}" > /tmp/instance_id.txt

# Read instance ID from the file
INSTANCE_ID=$(cat /tmp/instance_id.txt)

enable_ebs_udev(){
    curl -s https://raw.githubusercontent.com/aws/amazon-ec2-utils/master/ebsnvme-id > /sbin/ebsnvme-id
    curl -s https://raw.githubusercontent.com/aws/amazon-ec2-utils/master/ec2nvme-nsid > /sbin/ec2nvme-nsid
    sed -i '/^import argparse/i from __future__ import print_function' /sbin/ebsnvme-id
    chmod +x /sbin/ebsnvme-id
    chmod +x /sbin/ec2nvme-nsid

    curl -s https://raw.githubusercontent.com/aws/amazon-ec2-utils/master/70-ec2-nvme-devices.rules > /etc/udev/rules.d/70-ec2-nvme-devices.rules

    udevadm control --reload-rules && udevadm trigger && udevadm settle
}

# Configure CloudWatch Agent
configure_cwagent(){
    yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
    yum install -y collectd
    cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'EOL'
    {
        "metrics": {
            "append_dimensions": {
                "ImageId": "\${ec2_image_id}",
                "InstanceId": "\${aws:InstanceId}",
                "InstanceType": "\${ec2_instance_type}"
            },
            "metrics_collected": {
                "collectd": {
                    "metrics_aggregation_interval": 60
                },
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
                        "*"
                    ],
                    "drop_device": true,
                    "ignore_file_system_types": [
                        "tmpfs",
                        "devtmpfs",
                        "sysfs",
                        "fuse.s3fs",
                        "nfs4"
                    ]
                },
                "diskio": {
                    "measurement": [
                        "io_time",
                        "write_bytes",
                        "read_bytes",
                        "writes",
                        "reads"
                    ],
                    "metrics_collection_interval": 60,
                    "resources": [
                        "*"
                    ]
                },
                "mem": {
                    "measurement": [
                        "mem_used_percent"
                    ],
                    "metrics_collection_interval": 60
                },
                "net": {
                    "measurement": [
                        "net_drop_in",
                        "net_drop_out",
                        "net_err_in",
                        "net_err_out"
                    ],
                    "metrics_collection_interval": 60
                },
                "netstat": {
                    "measurement": [
                        "tcp_established",
                        "tcp_time_wait"
                    ],
                    "metrics_collection_interval": 60
                },
                "statsd": {
                    "metrics_aggregation_interval": 60,
                    "metrics_collection_interval": 60,
                    "service_address": ":8125"
                },
                "swap": {
                    "measurement": [
                        "swap_used_percent"
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
                            "file_path": "/oracle/software/product/Middleware/oas_home/oas_domain/bi/servers/bi_server1/logs/bi_server1.log",
                            "log_group_name": "${application_name}-bi_server1"
                        },
                        {
                            "file_path": "/oracle/software/product/Middleware/oas_home/oas_domain/bi/servers/bi_server1/logs/bi_server1-diagnostic.log",
                            "log_group_name": "${application_name}-bi_server1-diagnostic"
                        },
                        {
                            "file_path": "/oracle/software/product/Middleware/oas_home/oas_domain/bi/servers/bi_server1/logs/jbips.log",
                            "log_group_name": "${application_name}-jbips"
                        }
                    ]
                }
            }
        }
    }
EOL
}

# Restart CloudWatch Agent
restart_cwagent(){
    amazon-cloudwatch-agent-ctl -a stop
    amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s
}

# Call the functions
get_nvme_device
mount_volumes
ntp_config
enable_ebs_udev
configure_cwagent
restart_cwagent