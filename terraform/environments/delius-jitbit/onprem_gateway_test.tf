# Pre-req - security group
resource "aws_security_group" "onprem_gateway_test_sg" {
  name        = "onprem-gateway-test-sg"
  description = "Controls access onprem gateway instance"
  vpc_id      = data.aws_vpc.shared.id
  tags = merge(local.tags,
    { Name = lower(format("sg-%s-%s-onprem-gateway-test", local.application_name, local.environment)) }
  )
}

resource "aws_vpc_security_group_egress_rule" "onprem_gateway_test_https_out" {
  security_group_id = aws_security_group.onprem_gateway_test_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  description       = "Allow communication out on port 443, e.g. for SSM"
  tags = merge(local.tags,
    { Name = lower(format("sg-%s-%s-onprem-gateway-test", local.application_name, local.environment)) }
  )
}

resource "aws_vpc_security_group_egress_rule" "onprem_gateway_test_http_out" {
  security_group_id = aws_security_group.onprem_gateway_test_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  description       = "Allow communication out on port 80"
  tags = merge(local.tags,
    { Name = lower(format("sg-%s-%s-onprem-gateway", local.application_name, local.environment)) }
  )
}

resource "aws_vpc_security_group_egress_rule" "onprem_gateway_test_rds_out" {
  security_group_id = aws_security_group.onprem_gateway_test_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 1433
  to_port           = 1433
  ip_protocol       = "tcp"
  description       = "Allow communication out to RDS"
  tags = merge(local.tags,
    { Name = lower(format("sg-%s-%s-onprem-gateway", local.application_name, local.environment)) }
  )
}

# Pre-req - IAM role, attachment for SSM usage and instance profile
data "aws_iam_policy_document" "onprem_gateway_test_iam_assume_policy" {
  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "onprem_gateway_test_iam_role" {
  name               = "onprem_gateway_test_iam_role"
  assume_role_policy = data.aws_iam_policy_document.onprem_gateway_test_iam_assume_policy.json
  tags = merge(local.tags,
    { Name = lower(format("sg-%s-%s-onprem-gateway-test", local.application_name, local.environment)) }
  )
}

resource "aws_iam_role_policy_attachment" "onprem_gateway_test_amazonssmmanagedinstancecore" {
  role       = aws_iam_role.onprem_gateway_test_iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "onprem_gateway_test_profile" {
  name = "onprem_gateway_test_iam_role"
  role = aws_iam_role.onprem_gateway_test_iam_role.name
}

# Get latest Windows Server 2019 AMI
data "aws_ami" "onprem_gateway_test_windows" {
  most_recent = true
  owners      = [local.environment_management.account_ids["core-shared-services-production"]]
  filter {
    name   = "name"
    values = ["mp_WindowsServer2022*"]
  }
}

resource "aws_instance" "onprem_gateway_test" {
  #checkov:skip=CKV2_AWS_41:"IAM role is not implemented for this example EC2. SSH/AWS keys are not used either."
  # Specify the instance type and ami to be used (this is the Amazon free tier option)
  instance_type               = "t3.medium"
  ami                         = data.aws_ami.onprem_gateway_test_windows.id
  vpc_security_group_ids      = [aws_security_group.onprem_gateway_test_sg.id]
  subnet_id                   = data.aws_subnet.private_subnets_a.id
  iam_instance_profile        = aws_iam_instance_profile.onprem_gateway_test_profile.name
  associate_public_ip_address = false
  monitoring                  = false
  ebs_optimized               = false

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
  # Increase the volume size of the root volume
  # root_block_device {
  #   volume_type = "gp3"
  #   volume_size = 30
  #   encrypted   = true
  # }
  tags = merge(local.tags,
    { Name = lower(format("ec2-%s-%s-onprem-gateway-test", local.application_name, local.environment)) }
  )

  root_block_device {
    delete_on_termination = true
    encrypted             = true
    kms_key_id            = data.aws_kms_key.ebs_encryption_cmk.arn
    volume_size           = 30
    volume_type           = "gp2"
  }
}

data "aws_kms_key" "ebs_encryption_cmk" {
  key_id = "arn:aws:kms:eu-west-2:${local.environment_management.account_ids["core-shared-services-production"]}:alias/ebs-encryption-key"
}
