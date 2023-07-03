##
# Terraform to deploy an instance to test out a base Oracle AMI
##

# Pre-req - security group
resource "aws_security_group" "base_ami_test_instance_sg" {
  name        = "base-ami-test-instance-sg"
  description = "Controls access to base AMI instance"
  vpc_id      = data.aws_vpc.shared.id
  tags = merge(local.tags,
    { Name = lower(format("sg-%s-%s-base-ami-test-instance", local.application_name, local.environment)) }
  )
}

resource "aws_vpc_security_group_egress_rule" "base_ami_test_instance_https_out" {
  security_group_id = aws_security_group.base_ami_test_instance_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  description       = "Allow communication out on port 443, e.g. for SSM"
  tags = merge(local.tags,
    { Name = lower(format("sg-%s-%s-base-ami-test-instance", local.application_name, local.environment)) }
  )
}

# Pre-req - IAM role, attachment for SSM usage and instance profile
data "aws_iam_policy_document" "base_ami_test_instance_iam_assume_policy" {
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

resource "aws_iam_role" "base_ami_test_instance_iam_role" {
  name               = "base_ami_test_instance_iam_role"
  assume_role_policy = data.aws_iam_policy_document.base_ami_test_instance_iam_assume_policy.json
  tags = merge(local.tags,
    { Name = lower(format("sg-%s-%s-base-ami-test-instance", local.application_name, local.environment)) }
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
      data.aws_kms_key.general_shared.arn
    ]
  }
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

resource "aws_iam_role_policy" "business_unit_kms_key_access" {
  name   = "business_unit_kms_key_access"
  role   = aws_iam_role.base_ami_test_instance_iam_role.name
  policy = data.aws_iam_policy_document.business_unit_kms_key_access.json
}

resource "aws_iam_role_policy" "core_shared_services_bucket_access" {
  name   = "core_shared_services_bucket_access"
  role   = aws_iam_role.base_ami_test_instance_iam_role.name
  policy = data.aws_iam_policy_document.core_shared_services_bucket_access.json
}

resource "aws_iam_role_policy" "ec2_access" {
  name   = "ec2_access"
  role   = aws_iam_role.base_ami_test_instance_iam_role.name
  policy = data.aws_iam_policy_document.ec2_access_for_ansible.json
}

resource "aws_iam_role_policy_attachment" "base_ami_test_instance_amazonssmmanagedinstancecore" {
  role       = aws_iam_role.base_ami_test_instance_iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "base_ami_test_instance_profile" {
  name = "base_ami_test_instance_iam_role"
  role = aws_iam_role.base_ami_test_instance_iam_role.name
}

# Pre-req - Derive latest AMI
data "aws_ami" "aws_ami_base_ol" {
  most_recent = true
  owners      = [local.environment_management.account_ids["core-shared-services-production"]]
  name_regex  = "^delius_core_ol_8_5_oracle_db_19c_"
}

data "template_file" "userdata" {
  template = file("${path.module}/templates/userdata.sh.tftpl")

  vars = {
    branch               = "main"
    ansible_repo         = "modernisation-platform-configuration-management"
    ansible_repo_basedir = "ansible"
    ansible_args         = "oracle_19c_install"
  }
}

resource "aws_instance" "base_ami_test_instance" {
  #checkov:skip=CKV2_AWS_41:"IAM role is not implemented for this example EC2. SSH/AWS keys are not used either."
  # Specify the instance type and ami to be used
  instance_type = "r6i.xlarge"
  ami           = data.aws_ami.aws_ami_base_ol.id
  # ami = "ami-0e3dd4f4b84ef84f5" # AL2 amzn2-ami-hvm-2.0.20230418.0-x86_64-gp2
  vpc_security_group_ids      = [aws_security_group.base_ami_test_instance_sg.id]
  subnet_id                   = data.aws_subnet.private_subnets_a.id
  iam_instance_profile        = aws_iam_instance_profile.base_ami_test_instance_profile.name
  associate_public_ip_address = false
  monitoring                  = false
  ebs_optimized               = true

  user_data = data.template_file.userdata.rendered

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
    { Name = lower(format("ec2-%s-%s-base-ami-test-instance", local.application_name, local.environment)) },
    { server-type = "delius_core_db" }
  )
}

