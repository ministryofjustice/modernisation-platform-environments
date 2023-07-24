# Pre-req - security group
resource "aws_security_group" "onprem_gateway" {
  name        = "onprem-gateway"
  description = "Controls access onprem gateway instance"
  vpc_id      = data.aws_vpc.shared.id
  tags = merge(local.tags,
    { Name = lower(local.on_prem_dgw_name) }
  )
}

resource "aws_vpc_security_group_egress_rule" "onprem_gateway_https_out" {
  security_group_id = aws_security_group.onprem_gateway.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  description       = "Allow communication out on port 443, e.g. for SSM"
  tags = merge(local.tags,
    { Name = lower(local.on_prem_dgw_name) }
  )
}

resource "aws_vpc_security_group_egress_rule" "onprem_gateway_http_out" {
  security_group_id = aws_security_group.onprem_gateway.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  description       = "Allow communication out on port 80"
  tags = merge(local.tags,
    { Name = lower(local.on_prem_dgw_name) }
  )
}

resource "aws_vpc_security_group_egress_rule" "onprem_gateway_rds_out" {
  security_group_id = aws_security_group.onprem_gateway.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 1433
  to_port           = 1433
  ip_protocol       = "tcp"
  description       = "Allow communication out to RDS"
  tags = merge(local.tags,
    { Name = lower(local.on_prem_dgw_name) }
  )
}

# Pre-req - IAM role, attachment for SSM usage and instance profile
data "aws_iam_policy_document" "onprem_gateway" {
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

resource "aws_iam_role" "onprem_gateway" {
  name               = "onprem_gateway"
  assume_role_policy = data.aws_iam_policy_document.onprem_gateway.json
  tags = merge(local.tags,
    { Name = lower(local.on_prem_dgw_name) }
  )
}

resource "aws_iam_role_policy_attachment" "onprem_gateway_amazonssmmanagedinstancecore" {
  role       = aws_iam_role.onprem_gateway.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "onprem_gateway" {
  name = "onprem_gateway"
  role = aws_iam_role.onprem_gateway.name
}

# Get latest Windows Server 2019 AMI
data "aws_ami" "onprem_gateway_windows" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["Windows_Server-2019-English-Full-Base*"]
  }
}

data "template_file" "userdata" {
  template = file("${path.module}/onprem_gateway_userdata.tftpl")

  vars = {
  }
}

resource "aws_instance" "onprem_gateway" {
  #checkov:skip=CKV2_AWS_41:"IAM role is not implemented for this example EC2. SSH/AWS keys are not used either."
  # Specify the instance type and ami to be used (this is the Amazon free tier option)
  instance_type               = "t3.small"
  ami                         = data.aws_ami.onprem_gateway_windows.id
  vpc_security_group_ids      = [aws_security_group.onprem_gateway.id]
  subnet_id                   = data.aws_subnet.private_subnets_a.id
  iam_instance_profile        = aws_iam_instance_profile.onprem_gateway.name
  associate_public_ip_address = false
  monitoring                  = false
  ebs_optimized               = false
  user_data                   = data.template_file.userdata.rendered

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  tags = merge(local.tags,
    { Name = lower(local.on_prem_dgw_name) }
  )
}
