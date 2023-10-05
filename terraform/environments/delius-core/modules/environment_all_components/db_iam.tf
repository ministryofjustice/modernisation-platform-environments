# Pre-reqs - IAM role, attachment for SSM usage and instance profile
data "aws_iam_policy_document" "db_ec2_instance_iam_assume_policy" {
  count = contains(var.components_to_exclude, "db") ? 0 : 1
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


resource "aws_iam_role" "db_ec2_instance_iam_role" {
  count              = contains(var.components_to_exclude, "db") ? 0 : 1
  name               = lower(format("%s-%s-ec2_instance", var.env_name, var.db_config.name))
  assume_role_policy = data.aws_iam_policy_document.db_ec2_instance_iam_assume_policy[0].json
  tags = merge(local.tags,
    { Name = lower(format("%s-%s-ec2_instance", var.env_name, var.db_config.name)) }
  )
}

data "aws_iam_policy_document" "business_unit_kms_key_access" {
  count = contains(var.components_to_exclude, "db") ? 0 : 1
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
  count  = contains(var.components_to_exclude, "db") ? 0 : 1
  name   = format("%s-%s-business_unit_kms_key_access_policy", var.env_name, var.db_config.name)
  path   = "/"
  policy = data.aws_iam_policy_document.business_unit_kms_key_access[0].json
  tags = merge(local.tags,
    { Name = format("%s-%s-business_unit_kms_key_access_policy", var.env_name, var.db_config.name) }
  )
}

data "aws_iam_policy_document" "core_shared_services_bucket_access" {
  count = contains(var.components_to_exclude, "db") ? 0 : 1
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
  count  = contains(var.components_to_exclude, "db") ? 0 : 1
  name   = format("%s-%s-core_shared_services_bucket_access_policy", var.env_name, var.db_config.name)
  path   = "/"
  policy = data.aws_iam_policy_document.core_shared_services_bucket_access[0].json
  tags = merge(local.tags,
    { Name = format("%s-%s-core_shared_services_bucket_access_policy", var.env_name, var.db_config.name) }
  )
}

data "aws_iam_policy_document" "ec2_access_for_ansible" {
  count = contains(var.components_to_exclude, "db") ? 0 : 1
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
  count  = contains(var.components_to_exclude, "db") ? 0 : 1
  name   = format("%s-%s-ec2_access_for_ansible", var.env_name, var.db_config.name)
  path   = "/"
  policy = data.aws_iam_policy_document.ec2_access_for_ansible[0].json
  tags = merge(local.tags,
    { Name = format("%s-%s-ec2_access_for_ansible", var.env_name, var.db_config.name) }
  )
}

resource "aws_iam_role_policy" "business_unit_kms_key_access" {
  count  = contains(var.components_to_exclude, "db") ? 0 : 1
  name   = "business_unit_kms_key_access"
  role   = aws_iam_role.db_ec2_instance_iam_role[0].name
  policy = data.aws_iam_policy_document.business_unit_kms_key_access[0].json
}

resource "aws_iam_role_policy" "core_shared_services_bucket_access" {
  count  = contains(var.components_to_exclude, "db") ? 0 : 1
  name   = "core_shared_services_bucket_access"
  role   = aws_iam_role.db_ec2_instance_iam_role[0].name
  policy = data.aws_iam_policy_document.core_shared_services_bucket_access[0].json
}

resource "aws_iam_role_policy" "ec2_access" {
  count  = contains(var.components_to_exclude, "db") ? 0 : 1
  name   = "ec2_access"
  role   = aws_iam_role.db_ec2_instance_iam_role[0].name
  policy = data.aws_iam_policy_document.ec2_access_for_ansible[0].json
}

resource "aws_iam_role_policy_attachment" "db_ec2_instance_amazonssmmanagedinstancecore" {
  count      = contains(var.components_to_exclude, "db") ? 0 : 1
  role       = aws_iam_role.db_ec2_instance_iam_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "db_ec2_instanceprofile" {
  count = contains(var.components_to_exclude, "db") ? 0 : 1
  name  = format("%s-%s-ec2_instance_iam_role", var.env_name, var.db_config.name)
  role  = aws_iam_role.db_ec2_instance_iam_role[0].name
}
