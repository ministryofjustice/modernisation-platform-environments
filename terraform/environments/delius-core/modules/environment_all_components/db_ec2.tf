##
# Some work started here to flesh out use of the mod platform-curated modernisation-platform-terraform-ec2-instance module
# Current commented out but planned to pick this back up very soon to move away from our
#   native ec2 instance (engineered as we were prototyping our delius core db AMIs/test instance)
#   to a module-based ec2 instance
##
module "db_ec2_primary_instance" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-ec2-instance?ref=v2.0.0"

  providers = {
    aws.core-vpc = aws.core-vpc # core-vpc-(environment) holds the networking for all accounts
  }

  name              = format("%s-%s-1", var.env_name, var.db_config.name) # delius-core-db-dev
  business_unit     = var.account_info.business_unit                      # hmpps
  application_name  = var.account_info.application_name                   # delius-core
  region            = var.account_info.region                             # eu-west-2
  environment       = var.account_info.mp_environment                     # equates to one of the 4 MP environment names, e.g. development
  availability_zone = "eu-west-2a"
  subnet_id         = var.account_config.data_subnet_a_id

  ami_name  = var.db_config.ami_name  # delius_core_ol_8_5_oracle_db_19c_patch_2023-06-12T12-32-07.259Z
  ami_owner = var.db_config.ami_owner # 
  instance = merge(var.db_config.instance, {
    vpc_security_group_ids = [aws_security_group.db_ec2_instance_sg.id]
    key_name               = aws_key_pair.environment_ec2_user_key_pair.key_name
  })

  user_data_raw = var.db_config.user_data_raw

  ebs_volumes_copy_all_from_ami = true
  ebs_volumes                   = var.db_config.ebs_volumes
  ebs_volume_config             = var.db_config.ebs_volume_config

  route53_records = var.db_config.route53_records

  instance_profile_policies = [
    # aws_iam_policy.db_ec2_instance_iam_assume_policy.arn,
    aws_iam_policy.business_unit_kms_key_access.arn,
    aws_iam_policy.core_shared_services_bucket_access.arn,
    aws_iam_policy.ec2_access_for_ansible.arn
  ]
  tags = merge(local.tags,
    { Database = format("%s-1", var.db_config.name) }
  )
}


# Pre-req - security group
resource "aws_security_group" "db_ec2_instance_sg" {
  name        = format("%s-sg-%s-ec2-instance", var.env_name, var.db_config.name, )
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
# data "aws_iam_policy_document" "db_ec2_instance_iam_assume_policy" {
#   statement {
#     effect = "Allow"
#     actions = [
#       "sts:AssumeRole"
#     ]
#     principals {
#       type        = "Service"
#       identifiers = ["ec2.amazonaws.com"]
#     }
#   }
# }

# resource "aws_iam_policy" "db_ec2_instance_iam_assume_policy" {
#   name   = "db_ec2_instance_iam_assume_policy"
#   path   = "/"
#   policy = data.aws_iam_policy_document.db_ec2_instance_iam_assume_policy.json
#   tags = merge(local.tags,
#     { Name = format("%s-%s-db_ec2_instance_iam_assume_policy", var.db_config.name, var.env_name) }
#   )
# }

# resource "aws_iam_role" "db_ec2_instance_iam_role" {
#   name               = "db_ec2_instance_iam_role"
#   assume_role_policy = data.aws_iam_policy_document.db_ec2_instance_iam_assume_policy.json
#   tags = merge(local.tags,
#     { Name = lower(format("sg-%s-%s-db_ec2_instance", var.account_info.application_name, var.env_name)) }
#   )
# }

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

# resource "aws_iam_role_policy" "business_unit_kms_key_access" {
#   name   = "business_unit_kms_key_access"
#   role   = aws_iam_role.db_ec2_instance_iam_role.name
#   policy = data.aws_iam_policy_document.business_unit_kms_key_access.json
# }

# resource "aws_iam_role_policy" "core_shared_services_bucket_access" {
#   name   = "core_shared_services_bucket_access"
#   role   = aws_iam_role.db_ec2_instance_iam_role.name
#   policy = data.aws_iam_policy_document.core_shared_services_bucket_access.json
# }

# resource "aws_iam_role_policy" "ec2_access" {
#   name   = "ec2_access"
#   role   = aws_iam_role.db_ec2_instance_iam_role.name
#   policy = data.aws_iam_policy_document.ec2_access_for_ansible.json
# }

# resource "aws_iam_role_policy_attachment" "db_ec2_instance_amazonssmmanagedinstancecore" {
#   role       = aws_iam_role.db_ec2_instance_iam_role.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
# }

# resource "aws_iam_instance_profile" "db_ec2_instanceprofile" {
#   name = "db_ec2_instance_iam_role"
#   role = aws_iam_role.db_ec2_instance_iam_role.name
# }
