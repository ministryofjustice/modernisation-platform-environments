locals {
  instance_userdata = <<EOF
#!/bin/bash
cd /tmp
yum -y install sshpass
yum -y install jq

hostnamectl set-hostname ${local.application_name}.${local.application_data.accounts[local.environment].hostname}

yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
sudo systemctl start amazon-ssm-agent
sudo systemctl enable amazon-ssm-agent
sudo systemctl stop firewalld
sudo systemctl disable firewalld

mkfs.ext4 /dev/sdb
mkdir -p /oracle/software
echo "/dev/sdb /oracle/software ext4 defaults 0 0" >> /etc/fstab
mount -a

chown oracle:dba /oracle/software
chown oracle:dba /stage
chmod -R 777 /stage
chmod -R 644 /oracle/software
dd if=/dev/zero of=/root/myswapfile bs=1M count=1024
chmod 600 /root/myswapfile
mkswap /root/myswapfile
swapon /root/myswapfile
echo "/root/myswapfile swap swap defaults 0 0" >> /etc/fstab

ntp_config(){
    local RHEL=\$(cat /etc/redhat-release | cut -d. -f1 | awk '{print \$NF}')
    local SOURCE=169.254.169.123

    NtpD(){
        local CONF=/etc/ntp.conf
        sed -i 's/server \S/#server \S/g' \$CONF && \\
        sed -i "20i\\server \$SOURCE prefer iburst" \$CONF
        /etc/init.d/ntpd status >/dev/null 2>&1 \\
            && /etc/init.d/ntpd restart || /etc/init.d/ntpd start
        ntpq -p
    }
    ChronyD(){
        local CONF=/etc/chrony.conf
        sed -i 's/server \S/#server \S/g' \$CONF && \\
        sed -i "7i\\server \$SOURCE prefer iburst" \$CONF
        systemctl status chronyd >/dev/null 2>&1 \\
            && systemctl restart chronyd || systemctl start chronyd
        chronyc sources
    }
    case \$RHEL in
        5)
            NtpD
            ;;
        7)
            ChronyD
            ;;
    esac
}

# Retrieve instance ID and store it in a file
aws_instance_id=\$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
echo -n "\$aws_instance_id" > /tmp/instance_id.txt

# Read instance ID from the file
INSTANCE_ID=\$(cat /tmp/instance_id.txt)

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
                "ImageId": "\${local.application_data.accounts[local.environment].ec2amiid}",
                "InstanceId": "\${INSTANCE_ID}",
                "InstanceType": "\${local.application_data.accounts[local.environment].ec2instancetype}"
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
                            "log_group_name": "${local.application_name}-bi_server1"
                        },
                        {
                            "file_path": "/oracle/software/product/Middleware/oas_home/oas_domain/bi/servers/bi_server1/logs/bi_server1-diagnostic.log",
                            "log_group_name": "${local.application_name}-bi_server1-diagnostic"
                        },
                        {
                            "file_path": "/oracle/software/product/Middleware/oas_home/oas_domain/bi/servers/bi_server1/logs/jbips.log",
                            "log_group_name": "${local.application_name}-jbips"
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
ntp_config
enable_ebs_udev
configure_cwagent
restart_cwagent

EOF
}

resource "aws_instance" "oas_app_instance" {
  ami                         = local.application_data.accounts[local.environment].ec2amiid
  associate_public_ip_address = false
  availability_zone           = "eu-west-2a"
  ebs_optimized               = true
  instance_type               = local.application_data.accounts[local.environment].ec2instancetype
  vpc_security_group_ids      = [aws_security_group.ec2.id]
  monitoring                  = true
  subnet_id                   = data.aws_subnet.private_subnets_a.id
  iam_instance_profile        = aws_iam_instance_profile.ec2_instance_profile.id
  user_data_base64            = base64encode(local.instance_userdata)

  root_block_device {
    delete_on_termination = false
    encrypted             = true # TODO Confirm if encrypted volumes can work for OAS, as it looks like in MP they must be encrypted
    volume_size           = 40
    volume_type           = "gp2"
    tags = merge(
      local.tags,
      { "Name" = "${local.application_name}-root-volume" },
    )
  }

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name} Apps Server" },
    { "instance-scheduling" = "skip-scheduling" },
    { "snapshot-with-daily-7-day-retention" = "yes" }
  )
}

resource "aws_security_group" "ec2" {
  name        = local.application_name
  description = "OAS DB Server Security Group"
  vpc_id      = data.aws_vpc.shared.id

  ingress {
    description = "access to the admin server"
    from_port   = 9500
    to_port     = 9500
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.shared.cidr_block] #!ImportValue env-VpcCidr
  }
  ingress {
    description = "Access to the admin server from workspace"
    from_port   = 9500
    to_port     = 9500
    protocol    = "tcp"
    cidr_blocks = [local.application_data.accounts[local.environment].managementcidr] #!ImportValue env-ManagementCIDR
  }
  ingress {
    description = "Access to the managed server"
    from_port   = 9502
    to_port     = 9502
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.shared.cidr_block] #!ImportValue env-VpcCidr
  }
  ingress {
    description = "Access to the managed server from workspace"
    from_port   = 9502
    to_port     = 9502
    protocol    = "tcp"
    cidr_blocks = [local.application_data.accounts[local.environment].managementcidr] #!ImportValue env-ManagementCIDR
  }
  ingress {
    description = "Access to the managed server from laa development"
    from_port   = 9502
    to_port     = 9502
    protocol    = "tcp"
    cidr_blocks = [local.application_data.accounts[local.environment].inbound_cidr_lz] #!ImportValue env-ManagementCIDR
  }
  ingress {
    description = "Access to the managed server"
    from_port   = 9514
    to_port     = 9514
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.shared.cidr_block] #!ImportValue env-VpcCidr
  }
  ingress {
    description = "Access to the managed server from workspace"
    from_port   = 9514
    to_port     = 9514
    protocol    = "tcp"
    cidr_blocks = [local.application_data.accounts[local.environment].managementcidr] #!ImportValue env-ManagementCIDR
  }
  ingress {
    description = "Database connections to rds apex edw and mojfin"
    from_port   = 1521
    to_port     = 1521
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.shared.cidr_block] #!ImportValue env-VpcCidr
  }
  ingress {
    description = "LDAP Server Connection"
    from_port   = 1389
    to_port     = 1389
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.shared.cidr_block] #!ImportValue env-VpcCidr
  }
  ingress {
    description = "http access from LZ to oas-mp to test connectivity"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [local.application_data.accounts[local.environment].inbound_cidr_lz]
  }
  ingress {
    description = "http access from LZ to oas-mp to test connectivity"
    from_port   = 1389
    to_port     = 1389
    protocol    = "tcp"
    cidr_blocks = [local.application_data.accounts[local.environment].inbound_cidr_lz]
  }

  egress {
    description = "Allow AWS SSM Session Manager"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [local.application_data.accounts[local.environment].outbound_access_cidr]
  }
  egress {
    description = "access to the admin server"
    from_port   = 9500
    to_port     = 9500
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.shared.cidr_block] #!ImportValue env-VpcCidr
  }
  egress {
    description = "Access to the admin server from workspace"
    from_port   = 9500
    to_port     = 9500
    protocol    = "tcp"
    cidr_blocks = [local.application_data.accounts[local.environment].managementcidr] #!ImportValue env-ManagementCIDR
  }
  egress {
    description = "Access to the managed server"
    from_port   = 9502
    to_port     = 9502
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.shared.cidr_block] #!ImportValue env-VpcCidr
  }
  egress {
    description = "Access to the managed server from workspace"
    from_port   = 9502
    to_port     = 9502
    protocol    = "tcp"
    cidr_blocks = [local.application_data.accounts[local.environment].managementcidr] #!ImportValue env-ManagementCIDR
  }
  egress {
    description = "Access to the managed server"
    from_port   = 9514
    to_port     = 9514
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.shared.cidr_block] #!ImportValue env-VpcCidr
  }
  egress {
    description = "Access to the managed server from workspace"
    from_port   = 9514
    to_port     = 9514
    protocol    = "tcp"
    cidr_blocks = [local.application_data.accounts[local.environment].managementcidr] #!ImportValue env-ManagementCIDR
  }
  egress {
    description = "Database connections from rds apex edw and mojfin"
    from_port   = 1521
    to_port     = 1521
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.shared.cidr_block] #!ImportValue env-VpcCidr
  }
  egress {
    description = "LDAP Server Connection"
    from_port   = 1389
    to_port     = 1389
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.shared.cidr_block] #!ImportValue env-VpcCidr
  }
  egress {
    description = "Outbound internet access"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [local.application_data.accounts[local.environment].outbound_access_cidr]
  }
  egress {
    description = "http access from LZ to oas-mp to test connectivity"
    from_port   = 1389
    to_port     = 1389
    protocol    = "tcp"
    cidr_blocks = [local.application_data.accounts[local.environment].inbound_cidr_lz]
  }
  egress {
    description = "http access from LZ to oas-mp to test connectivity"
    from_port   = 1521
    to_port     = 1521
    protocol    = "tcp"
    cidr_blocks = [local.application_data.accounts[local.environment].inbound_cidr_lz]
  }
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "${local.application_name}-ec2-profile"
  role = aws_iam_role.ec2_instance_role.name
}

resource "aws_iam_role" "ec2_instance_role" {
  name                = "${local.application_name}-role"
  managed_policy_arns = ["arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"]
  assume_role_policy  = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "ec2.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy" "ec2_instance_policy" {
  #tfsec:ignore:aws-iam-no-policy-wildcards
  name = "${local.application_name}-ec2-policy"
  role = aws_iam_role.ec2_instance_role.id

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:Describe*",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "s3:ListBucket",
        ],
        Resource = [
          "arn:aws:s3:::modernisation-platform-software20230224000709766100000001",
          "arn:aws:s3:::modernisation-platform-software20230224000709766100000001/*",
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:PutObjectAcl",
        ],
        Resource = [
          "arn:aws:s3:::modernisation-platform-software20230224000709766100000001/*",
        ]
      }
    ]
  })
}

resource "aws_ebs_volume" "EC2ServerVolumeORAHOME" {
  availability_zone = "eu-west-2a"
  size              = local.application_data.accounts[local.environment].orahomesize
  type              = "gp3"
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  snapshot_id       = local.application_data.accounts[local.environment].orahome_snapshot

  lifecycle {
    ignore_changes = [kms_key_id]
  }

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-EC2ServerVolumeORAHOME" },
  )
}

resource "aws_volume_attachment" "oas_EC2ServerVolume01" {
  device_name = "/dev/sdb"
  volume_id   = aws_ebs_volume.EC2ServerVolumeORAHOME.id
  instance_id = aws_instance.oas_app_instance.id
}

resource "aws_route53_record" "oas-app" {
  provider = aws.core-vpc
  zone_id  = data.aws_route53_zone.inner.zone_id
  name     = "${local.application_name}.${data.aws_route53_zone.inner.name}"
  type     = "A"
  ttl      = 900
  records  = [aws_instance.oas_app_instance.private_ip]
}
