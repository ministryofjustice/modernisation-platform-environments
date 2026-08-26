## Pre-reqs - IAM role, attachment for SSM usage and instance profile
#data "aws_iam_policy_document" "db_ec2_instance_iam_assume_policy" {
#  statement {
#    effect = "Allow"
#    actions = [
#      "sts:AssumeRole"
#    ]
#    principals {
#      type        = "Service"
#      identifiers = ["ec2.amazonaws.com"]
#    }
#  }
#}
#
#
#resource "aws_iam_role" "db_ec2_instance_iam_role" {
#  name               = lower(format("%s-delius-db-ec2_instance", var.env_name))
#  assume_role_policy = data.aws_iam_policy_document.db_ec2_instance_iam_assume_policy.json
#  tags = merge(local.tags,
#    { Name = lower(format("%s-delius-db-ec2_instance", var.env_name)) }
#  )
#}
#
#data "aws_iam_policy_document" "business_unit_kms_key_access" {
#  statement {
#    effect = "Allow"
#    actions = [
#      "kms:Encrypt",
#      "kms:Decrypt",
#      "kms:ReEncrypt*",
#      "kms:GenerateDataKey*",
#      "kms:DescribeKey",
#      "kms:CreateGrant",
#      "kms:ListGrants",
#      "kms:RevokeGrant"
#    ]
#    resources = [
#      var.account_config.kms_keys.general_shared
#    ]
#  }
#}
#
#resource "aws_iam_policy" "business_unit_kms_key_access" {
#  name   = format("%s-delius-db-business_unit_kms_key_access_policy", var.env_name)
#  path   = "/"
#  policy = data.aws_iam_policy_document.business_unit_kms_key_access.json
#  tags = merge(local.tags,
#    { Name = format("%s-delius-db-business_unit_kms_key_access_policy", var.env_name) }
#  )
#}
#
#data "aws_iam_policy_document" "core_shared_services_bucket_access" {
#  statement {
#    effect = "Allow"
#    actions = [
#      "s3:ListBucket",
#      "s3:GetObject"
#    ]
#    resources = [
#      "arn:aws:s3:::mod-platform-image-artefact-bucket20230203091453221500000001/*",
#      "arn:aws:s3:::mod-platform-image-artefact-bucket20230203091453221500000001"
#    ]
#  }
#}
#
#resource "aws_iam_policy" "core_shared_services_bucket_access" {
#  name   = format("%s-delius-db-core_shared_services_bucket_access_policy", var.env_name)
#  path   = "/"
#  policy = data.aws_iam_policy_document.core_shared_services_bucket_access.json
#  tags = merge(local.tags,
#    { Name = format("%s-delius-db-core_shared_services_bucket_access_policy", var.env_name) }
#  )
#}
#
#data "aws_iam_policy_document" "ec2_access_for_ansible" {
#  statement {
#    effect = "Allow"
#    actions = [
#      "ec2:DescribeTags",
#      "ec2:DescribeInstances",
#      "ec2:DescribeVolumes"
#    ]
#    resources = ["*"]
#  }
#}
#
#data "aws_iam_policy_document" "allow_access_to_ssm_parameter_store" {
#  statement {
#    sid    = "AllowAccessToSsmParameterStore"
#    effect = "Allow"
#    actions = [
#      "ssm:PutParameter"
#    ]
#    resources = ["*"]
#  }
#}
#
#resource "aws_iam_policy" "allow_access_to_ssm_parameter_store" {
#  name   = format("%s-delius-db-allow_access_to_ssm_parameter_store", var.env_name)
#  path   = "/"
#  policy = data.aws_iam_policy_document.allow_access_to_ssm_parameter_store.json
#  tags = merge(local.tags,
#    { Name = format("%s-delius-db-ec2_access_for_ansible", var.env_name) }
#  )
#}
#
#resource "aws_iam_role_policy_attachment" "allow_access_to_ssm_parameter_store" {
#  role       = aws_iam_role.db_ec2_instance_iam_role.name
#  policy_arn = aws_iam_policy.allow_access_to_ssm_parameter_store.arn
#}
#
#resource "aws_iam_policy" "ec2_access_for_ansible" {
#  name   = format("%s-delius-db-ec2_access_for_ansible", var.env_name)
#  path   = "/"
#  policy = data.aws_iam_policy_document.ec2_access_for_ansible.json
#  tags = merge(local.tags,
#    { Name = format("%s-delius-db-ec2_access_for_ansible", var.env_name) }
#  )
#}
#
#resource "aws_iam_role_policy" "business_unit_kms_key_access" {
#  name   = "business_unit_kms_key_access"
#  role   = aws_iam_role.db_ec2_instance_iam_role.name
#  policy = data.aws_iam_policy_document.business_unit_kms_key_access.json
#}
#
#resource "aws_iam_role_policy" "core_shared_services_bucket_access" {
#  name   = "core_shared_services_bucket_access"
#  role   = aws_iam_role.db_ec2_instance_iam_role.name
#  policy = data.aws_iam_policy_document.core_shared_services_bucket_access.json
#}
#
#resource "aws_iam_role_policy" "ec2_access" {
#  name   = "ec2_access"
#  role   = aws_iam_role.db_ec2_instance_iam_role.name
#  policy = data.aws_iam_policy_document.ec2_access_for_ansible.json
#}
#
#resource "aws_iam_role_policy_attachment" "db_ec2_instance_amazonssmmanagedinstancecore" {
#  role       = aws_iam_role.db_ec2_instance_iam_role.name
#  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
#}
#
#resource "aws_iam_instance_profile" "db_ec2_instanceprofile" {
#  name = format("%s-delius-db-ec2_instance_iam_role", var.env_name)
#  role = aws_iam_role.db_ec2_instance_iam_role.name
#}