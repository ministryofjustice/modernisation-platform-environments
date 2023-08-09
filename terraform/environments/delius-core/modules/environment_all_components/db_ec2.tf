resource "aws_instance" "db_ec2_primary_instance" {
  #checkov:skip=CKV2_AWS_41:"IAM role is not implemented for this example EC2. SSH/AWS keys are not used either."
  instance_type               = "r6i.xlarge"
  ami                         = var.db_config.ami_name
  vpc_security_group_ids      = [aws_security_group.db_ec2_instance_sg.id]
  subnet_id                   = var.account_config.data_subnet_a_id
  iam_instance_profile        = aws_iam_instance_profile.db_ec2_instanceprofile.name
  associate_public_ip_address = false
  monitoring                  = false
  ebs_optimized               = true
  key_name                    = aws_key_pair.environment_ec2_user_key_pair.key_name
  user_data_base64            = var.db_config.user_data_raw

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
    { Name = lower(format("%s-%s-1", var.env_name, var.db_config.name)) },
    { server-type = "delius_core_db" },
    { database = format("%s-1", var.db_config.name) }
  )
}

# Pre-req - security group
resource "aws_security_group" "db_ec2_instance_sg" {
  name        = format("%s-sg-%s-ec2-instance", var.env_name, var.db_config.name)
  description = "Controls access to db ec2 instance"
  vpc_id      = var.account_info.vpc_id
  tags = merge(local.tags,
    { Name = lower(format("%s-sg-%s-ec2-instance", var.env_name, var.db_config.name)) }
  )
}

resource "aws_vpc_security_group_egress_rule" "db_ec2_instance_https_out" {
  security_group_id = aws_security_group.db_ec2_instance_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  description       = "Allow communication out on port 443, e.g. for SSM"
  tags = merge(local.tags,
    { Name = "https-out" }
  )
}

# Pre-req - IAM role, attachment for SSM usage and instance profile
data "aws_iam_policy_document" "db_ec2_instance_iam_assume_policy" {
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

# resource "aws_iam_policy" "db_ec2_instance_iam_assume_policy" {
#   name   = format("%s-%s-ec2_instance_iam_assume_policy", var.env_name, var.db_config.name)
#   path   = "/"
#   policy = data.aws_iam_policy_document.db_ec2_instance_iam_assume_policy.json
#   tags = merge(local.tags,
#     { Name = format("%s-%s-ec2_instance_iam_assume_policy", var.env_name, var.db_config.name) }
#   )
# }

resource "aws_iam_role" "db_ec2_instance_iam_role" {
  name               = lower(format("%s-%s-ec2_instance", var.env_name, var.db_config.name))
  assume_role_policy = data.aws_iam_policy_document.db_ec2_instance_iam_assume_policy.json
  tags = merge(local.tags,
    { Name = lower(format("%s-%s-ec2_instance", var.env_name, var.db_config.name)) }
  )
}

data "aws_iam_policy_document" "business_unit_kms_key_access" {
  statement {
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
      "kms:CreateGrant",
      "kms:ListGrants",
      "kms:RevokeGrant"
    ]
    resources = [
      var.account_config.general_shared_kms_key_arn
    ]
  }
}

resource "aws_iam_policy" "business_unit_kms_key_access" {
  name   = format("%s-%s-business_unit_kms_key_access_policy", var.env_name, var.db_config.name)
  path   = "/"
  policy = data.aws_iam_policy_document.business_unit_kms_key_access.json
  tags = merge(local.tags,
    { Name = format("%s-%s-business_unit_kms_key_access_policy", var.env_name, var.db_config.name) }
  )
}

data "aws_iam_policy_document" "core_shared_services_bucket_access" {
  statement {
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetObject"
    ]
    resources = [
      "arn:aws:s3:::mod-platform-image-artefact-bucket*/*",
      "arn:aws:s3:::mod-platform-image-artefact-bucket*"
    ]
  }
}

resource "aws_iam_policy" "core_shared_services_bucket_access" {
  name   = format("%s-%s-core_shared_services_bucket_access_policy", var.env_name, var.db_config.name)
  path   = "/"
  policy = data.aws_iam_policy_document.core_shared_services_bucket_access.json
  tags = merge(local.tags,
    { Name = format("%s-%s-core_shared_services_bucket_access_policy", var.env_name, var.db_config.name) }
  )
}

data "aws_iam_policy_document" "ec2_access_for_ansible" {
  statement {
    effect = "Allow"
    actions = [
      "ec2:DescribeTags",
      "ec2:DescribeInstances",
      "ec2:DescribeVolumes"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "ec2_access_for_ansible" {
  name   = format("%s-%s-ec2_access_for_ansible", var.env_name, var.db_config.name)
  path   = "/"
  policy = data.aws_iam_policy_document.ec2_access_for_ansible.json
  tags = merge(local.tags,
    { Name = format("%s-%s-ec2_access_for_ansible", var.env_name, var.db_config.name) }
  )
}

resource "aws_iam_role_policy" "business_unit_kms_key_access" {
  name   = "business_unit_kms_key_access"
  role   = aws_iam_role.db_ec2_instance_iam_role.name
  policy = data.aws_iam_policy_document.business_unit_kms_key_access.json
}

resource "aws_iam_role_policy" "core_shared_services_bucket_access" {
  name   = "core_shared_services_bucket_access"
  role   = aws_iam_role.db_ec2_instance_iam_role.name
  policy = data.aws_iam_policy_document.core_shared_services_bucket_access.json
}

resource "aws_iam_role_policy" "ec2_access" {
  name   = "ec2_access"
  role   = aws_iam_role.db_ec2_instance_iam_role.name
  policy = data.aws_iam_policy_document.ec2_access_for_ansible.json
}

resource "aws_iam_role_policy_attachment" "db_ec2_instance_amazonssmmanagedinstancecore" {
  role       = aws_iam_role.db_ec2_instance_iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "db_ec2_instanceprofile" {
  name = format("%s-%s-ec2_instance_iam_role", var.env_name, var.db_config.name)
  role = aws_iam_role.db_ec2_instance_iam_role.name
}
