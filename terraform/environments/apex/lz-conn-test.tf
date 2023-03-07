locals {
  instance-userdata = <<EOF
#!/bin/bash
yum install -y httpd
systemctl start httpd
cat "{
	"agent": {
		"metrics_collection_interval": 60,
		"run_as_user": "root"
	},
	"metrics": {
		"aggregation_dimensions": [
			[
				"InstanceId"
			]
		],
		"append_dimensions": {
			"AutoScalingGroupName": "${aws:AutoScalingGroupName}",
			"ImageId": "${aws:ImageId}",
			"InstanceId": "${aws:InstanceId}",
			"InstanceType": "${aws:InstanceType}"
		},
		"metrics_collected": {
			"collectd": {
				"metrics_aggregation_interval": 60
			},
			"disk": {
				"measurement": [
					"used_percent"
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
			}
		}
	}
}" > /home/ec2-user/config.json
cat "0 8 * * * root systemctl start httpd" > /etc/cron.d/httpd_cron
EOF
}



module "ec2_instance" {
  source                 = "terraform-aws-modules/ec2-instance/aws"
  version                = "~> 4.0"
  name                   = "${local.environment}-landingzone-httptest"
  ami                    = "ami-06672d07f62285d1d"
  instance_type          = "t3a.small"
  vpc_security_group_ids = [module.httptest_sg.security_group_id]
  subnet_id              = data.aws_subnet.private_subnets_a.id
  user_data_base64       = base64encode(local.instance-userdata)
  iam_instance_profile   = aws_iam_instance_profile.instance_profile.id
  tags = {
    Name = "${local.environment}-landingzone-httptest"
    # Environment = "dev"
    Environment = local.environment
  }
}

resource "aws_iam_instance_profile" "instance_profile" {
  name = "SsmManagedInstanceProfile"
  role = aws_iam_role.ssm_managed_instance.name
}

resource "aws_iam_role" "ssm_managed_instance" {
  name                = "SsmManagedInstance"
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

module "httptest_sg" {
  source      = "terraform-aws-modules/security-group/aws"
  version     = "~> 4.0"
  name        = "landingzone-httptest-sg"
  description = "Security group for TG connectivity testing between LAA LZ & MP"
  vpc_id      = data.aws_vpc.shared.id
  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      description = "Outgoing"
      cidr_blocks = "0.0.0.0/0"
    }
  ]
  ingress_with_cidr_blocks = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      description = "HTTP"
      cidr_blocks = local.application_data.accounts[local.environment].shared_services_cidr
    },
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      description = "HTTP"
      cidr_blocks = local.application_data.accounts[local.environment].account_cidr
    }
  ]
}