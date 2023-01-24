locals {
  instance-userdata = <<EOF
#!/bin/bash
cd /tmp
yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
sudo systemctl start amazon-ssm-agent
sudo systemctl enable amazon-ssm-agent
EOF
}

resource "aws_instance" "oas_app_instance" {
  ami                         = local.application_data.accounts[local.environment].ec2amiid
  associate_public_ip_address = false
  availability_zone           = "eu-west-2a"
  ebs_optimized               = true
  instance_type               = local.application_data.accounts[local.environment].ec2instancetype
  security_groups             = [aws_security_group.ec2.id]
  monitoring                  = true
  subnet_id                   = data.aws_subnet.private_subnets_a.id
  # iam_instance_profile        = aws_iam_instance_profile.ec2_instance_profile.id
  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.id
  # user_data                 = file("user_data.sh")
  user_data_base64 = base64encode(local.instance-userdata)

  root_block_device {
    delete_on_termination = false
    encrypted             = false
    volume_size           = 40
    volume_type           = "gp2"
  }

  volume_tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-root-volume" },
  )

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name} Apps Server" },
  )
}

resource "aws_security_group" "ec2" {
  name        = local.application_name
  description = "OAS DB Server Security Group"
  vpc_id      = data.aws_vpc.shared.id

  ingress {
    description     = "Allow AWS SSM Session Manager"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [local.application_data.accounts[local.environment].ssm_interface_endpoint_security_group]
  }
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
    description = "Inbound internet access"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.shared.cidr_block] #!ImportValue env-VpcCidr
  }


  egress {
    description     = "Allow AWS SSM Session Manager"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [local.application_data.accounts[local.environment].ssm_interface_endpoint_security_group]
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
    cidr_blocks = [data.aws_vpc.shared.cidr_block] #!ImportValue env-VpcCidr
  }
  egress {
    description = "Outbound internet access"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [local.application_data.accounts[local.environment].outbound_access_cidr]
  }
}

# data "aws_iam_policy_document" "ec2_instance_policy" {
#   statement {
#     actions = ["sts:AssumeRole"]

#     principals {
#       type        = "Service"
#       identifiers = ["ec2.amazonaws.com"]
#     }
#   }
# }

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
    ]
  })
}

# resource "aws_iam_role_policy" "ec2_instance_policy" {
#   #tfsec:ignore:aws-iam-no-policy-wildcards
#   name   = "${local.application_name}-ec2-policy"
#   role   = aws_iam_role.ec2_instance_role.id
#   policy = data.aws_iam_policy_document.ec2_common_combined.json
# }

# data "aws_iam_policy_document" "ssm_custom" {
#   statement {
#     sid    = "CustomSsmPolicy"
#     effect = "Allow"
#     actions = [
#       "ssm:DescribeAssociation",
#       "ssm:DescribeDocument",
#       "ssm:GetDeployablePatchSnapshotForInstance",
#       "ssm:GetDocument",
#       "ssm:GetManifest",
#       "ssm:GetParameter",
#       "ssm:GetParameters",
#       "ssm:ListAssociations",
#       "ssm:ListInstanceAssociations",
#       "ssm:PutInventory",
#       "ssm:PutComplianceItems",
#       "ssm:PutConfigurePackageResult",
#       "ssm:UpdateAssociationStatus",
#       "ssm:UpdateInstanceAssociationStatus",
#       "ssm:UpdateInstanceInformation",
#       "ssmmessages:CreateControlChannel",
#       "ssmmessages:CreateDataChannel",
#       "ssmmessages:OpenControlChannel",
#       "ssmmessages:OpenDataChannel",
#       "ec2messages:AcknowledgeMessage",
#       "ec2messages:DeleteMessage",
#       "ec2messages:FailMessage",
#       "ec2messages:GetEndpoint",
#       "ec2messages:GetMessages",
#       "ec2messages:SendReply"
#     ]
#     # skipping these as policy is a scoped down version of Amazon provided AmazonSSMManagedInstanceCore managed policy.  Permissions required for SSM function

#     #checkov:skip=CKV_AWS_111: "Ensure IAM policies does not allow write access without constraints"
#     #checkov:skip=CKV_AWS_108: "Ensure IAM policies does not allow data exfiltration"
#     resources = ["*"] #tfsec:ignore:aws-iam-no-policy-wildcards
#   }
# }

# # combine ec2-common policy documents
# data "aws_iam_policy_document" "ec2_common_combined" {
#   source_policy_documents = [
#     data.aws_iam_policy_document.ssm_custom.json,
#     data.aws_iam_policy_document.ec2_instance_policy.json
#   ]
# }


resource "aws_ebs_volume" "EC2ServeVolume01" {
  availability_zone = "eu-west-2a"
  size              = local.application_data.accounts[local.environment].orahomesize
  type              = "gp3"
  encrypted         = false

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-EC2ServeVolume01" },
  )

  lifecycle {
    ignore_changes = [
      snapshot_id,
    ]
  }
}

resource "aws_volume_attachment" "oas_EC2ServeVolume01" {
  device_name = "/dev/sdb"
  volume_id   = aws_ebs_volume.EC2ServeVolume01.id
  instance_id = aws_instance.oas_app_instance.id
}

resource "aws_ebs_volume" "EC2ServeVolume02" {
  availability_zone = "eu-west-2a"
  size              = local.application_data.accounts[local.environment].stageesize
  type              = "gp3"
  encrypted         = false

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-EC2ServeVolume02" },
  )

  lifecycle {
    ignore_changes = [
      snapshot_id,
    ]
  }
}

resource "aws_volume_attachment" "oas_EC2ServeVolume02" {
  device_name = "/dev/sdc"
  volume_id   = aws_ebs_volume.EC2ServeVolume02.id
  instance_id = aws_instance.oas_app_instance.id
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.eu-west-2.s3"
}

resource "aws_vpc_endpoint_route_table_association" "s3_endpoint_route_table" {
  route_table_id  = data.aws_route_table.subnet_route_table.id
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
}

# data "aws_caller_identity" "current" {}

# resource "aws_vpc_endpoint_service" "s3_endpoint_service" {
#   acceptance_required        = false
#   allowed_principals         = [data.aws_caller_identity.current.arn]
#   gateway_load_balancer_arns = [aws_lb.example.arn]
# }

# resource "aws_vpc_endpoint" "s3_endpoint" {
#   service_name      = aws_vpc_endpoint_service.s3_endpoint_service
#   subnet_ids        = [aws_subnet.example.id]
#   vpc_endpoint_type = aws_vpc_endpoint_service.example.service_type
#   vpc_id            = aws_vpc.example.id
# }