data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

data "aws_subnet" "private_az_a" {
  tags = {
    Name = "${local.vpc_name}-${local.environment}-${local.subnet_set}-private-${local.region}a"
  }
}

resource "aws_security_group" "ppud_data_transfer" {
  description = "Security group for the ppud data transer instance"
  name        = "data-transfer-${local.application_name}"
  vpc_id      = local.vpc_id
}

resource "aws_security_group_rule" "ppud_data_transfer_http_egress" {
  security_group_id = aws_security_group.ppud_data_transfer.id

  description = "ppud_data_transfer_http_egress"
  type        = "egress"
  from_port   = "80"
  to_port     = "80"
  protocol    = "TCP"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "ppud_data_transfer_https_egress" {
  security_group_id = aws_security_group.ppud_data_transfer.id

  description = "ppud_data_transfer_https_egress"
  type        = "egress"
  from_port   = "443"
  to_port     = "443"
  protocol    = "TCP"
  cidr_blocks = ["0.0.0.0/0"]
}

data "aws_iam_policy_document" "ppud_data_transfer_assume_policy_document" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ppud_data_transfer_role" {
  name               = "data-transfer-${local.application_name}"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.ppud_data_transfer_assume_policy_document.json

  tags = merge(
    local.tags,
    {
      Name = "data-transfer-${local.application_name}"
    }
  )
}

#wildcards permissible read access to specific buckets
#tfsec:ignore:aws-iam-no-policy-wildcards
data "aws_iam_policy_document" "ppud_data_transfer_ssm_s3_policy_document" {

  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject"
    ]
    resources = [
      "arn:aws:s3:::aws-ssm-${local.region}/*",
      "arn:aws:s3:::aws-windows-downloads-${local.region}/*",
      "arn:aws:s3:::amazon-ssm-${local.region}/*",
      "arn:aws:s3:::amazon-ssm-packages-${local.region}/*",
      "arn:aws:s3:::${local.region}-birdwatcher-prod/*",
      "arn:aws:s3:::aws-ssm-distributor-file-${local.region}/*",
      "arn:aws:s3:::aws-ssm-document-attachments-${local.region}/*",
      "arn:aws:s3:::patch-baseline-snapshot-${local.region}/*"
    ]
  }
}

resource "aws_iam_policy" "ppud_data_transfer_ssm_s3_policy" {
  name   = "ppud_data_transfer_ssm_s3"
  policy = data.aws_iam_policy_document.ppud_data_transfer_ssm_s3_policy_document.json
}

resource "aws_iam_role_policy_attachment" "ppud_data_transfer_host_ssm_s3" {
  policy_arn = aws_iam_policy.ppud_data_transfer_ssm_s3_policy.arn
  role       = aws_iam_role.ppud_data_transfer_role.name
}

resource "aws_iam_instance_profile" "ppud_data_transfer_profile" {
  name = "data-transfer-${local.application_name}-ec2-profile"
  role = aws_iam_role.ppud_data_transfer_role.name
  path = "/"
}

resource "aws_key_pair" "doakley" {
  key_name   = "doakley"
  public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEU5QgCe9tiwCmZxZIx0E6n9It3Xb9oO5bu30rGRv9Vm darren.oakley@digital.justice.gov.uk"
}

resource "aws_instance" "ppud_data_transfer" {
  instance_type               = "t3.micro"
  ami                         = data.aws_ami.ubuntu.id
  vpc_security_group_ids      = [aws_security_group.ppud_data_transfer.id]
  monitoring                  = true
  associate_public_ip_address = false
  ebs_optimized               = true
  subnet_id                   = data.aws_subnet.private_az_a.id
  key_name                    = aws_key_pair.doakley.key_name

  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  root_block_device {
    encrypted   = true
    volume_size = 100
    volume_type = "standard"
    tags = {
      Name = "root-block-device-data-transfer-${local.application_name}"
    }
  }

  tags = merge(
    local.tags,
    {
      Name = "data-transfer-${local.application_name}"
    }
  )
}
