##############################################
# IAM Instance Profile
##############################################
resource "aws_iam_instance_profile" "db_ec2_instanceprofile" {
  name = format("%s-delius-db-ec2_instance_iam_role", var.env_name)
  role = aws_iam_role.db_ec2_instance_iam_role.name
}


# Pre-reqs - IAM role, attachment for SSM usage and instance profile
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


resource "aws_iam_role" "db_ec2_instance_iam_role" {
  name               = lower(format("%s-delius-db-ec2_instance", var.env_name))
  assume_role_policy = data.aws_iam_policy_document.db_ec2_instance_iam_assume_policy.json
  tags = merge(var.tags,
    { Name = lower(format("%s-delius-db-ec2_instance", var.env_name)) }
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
      var.account_config.kms_keys.general_shared,
    ]
  }
}

resource "aws_iam_policy" "business_unit_kms_key_access" {
  name   = format("%s-delius-db-business_unit_kms_key_access_policy", var.env_name)
  path   = "/"
  policy = data.aws_iam_policy_document.business_unit_kms_key_access.json
  tags = merge(var.tags,
    { Name = format("%s-delius-db-business_unit_kms_key_access_policy", var.env_name) }
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
      "arn:aws:s3:::mod-platform-image-artefact-bucket20230203091453221500000001/*",
      "arn:aws:s3:::mod-platform-image-artefact-bucket20230203091453221500000001"
    ]
  }
}

resource "aws_iam_policy" "core_shared_services_bucket_access" {
  name   = format("%s-delius-db-core_shared_services_bucket_access_policy", var.env_name)
  path   = "/"
  policy = data.aws_iam_policy_document.core_shared_services_bucket_access.json
  tags = merge(var.tags,
    { Name = format("%s-delius-db-core_shared_services_bucket_access_policy", var.env_name) }
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

data "aws_iam_policy_document" "allow_access_to_ssm_parameter_store" {
  statement {
    sid    = "AllowAccessToSsmParameterStore"
    effect = "Allow"
    actions = [
      "ssm:PutParameter"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "allow_access_to_ssm_parameter_store" {
  name   = format("%s-delius-db-allow_access_to_ssm_parameter_store", var.env_name)
  path   = "/"
  policy = data.aws_iam_policy_document.allow_access_to_ssm_parameter_store.json
  tags = merge(var.tags,
    { Name = format("%s-delius-db-ec2_access_for_ansible", var.env_name) }
  )
}

resource "aws_iam_role_policy_attachment" "allow_access_to_ssm_parameter_store" {
  role       = aws_iam_role.db_ec2_instance_iam_role.name
  policy_arn = aws_iam_policy.allow_access_to_ssm_parameter_store.arn
}

resource "aws_iam_policy" "ec2_access_for_ansible" {
  name   = format("%s-delius-db-ec2_access_for_ansible", var.env_name)
  path   = "/"
  policy = data.aws_iam_policy_document.ec2_access_for_ansible.json
  tags = merge(var.tags,
    { Name = format("%s-delius-db-ec2_access_for_ansible", var.env_name) }
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


data "aws_iam_policy_document" "db_access_to_secrets_manager" {
  statement {
    sid     = "DbAccessToSecretsManager"
    actions = [
      "secretsmanager:Get*",
      "secretsmanager:ListSecret*",
      "secretsmanager:Put*",
      "secretsmanager:RestoreSecret",
      "secretsmanager:Update*"
    ]
    effect   = "Allow"
    resources = [
      "${aws_secretsmanager_secret.delius_core_dba_passwords.arn}",
      "${aws_secretsmanager_secret.delius_core_application_passwords.arn}"
    ]
  }
}

resource "aws_iam_policy" "db_access_to_secrets_manager" {
  name   = "${var.env_name}-delius-db-allow-access-secrets-manager"
  policy = data.aws_iam_policy_document.db_access_to_secrets_manager.json
  tags   = merge(var.tags,
    { Name = "${var.env_name}-delius-db-ec2-access" }
  )
}

resource "aws_iam_role_policy_attachment" "db_access_to_secrets_manager" {
  role       = aws_iam_role.db_ec2_instance_iam_role.name
  policy_arn = aws_iam_policy.db_access_to_secrets_manager.arn
}

# new IAM role OEM setup to allow ec2s to access secrets manager and kms keys
resource "aws_iam_role" "db_ec2_oem_role" {
  name                  = "EC2OracleEnterpriseManagementSecretsRole"
  assume_role_policy    = data.aws_iam_policy_document.ec2_oem_assume_policy.json
}

data "aws_iam_policy_document" "ec2_oem_assume_policy" {
  statement {
    effect  = "Allow"
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "allow_new_role_secrets_manager" {
  role       = aws_iam_role.db_ec2_oem_role.name
  policy_arn = aws_iam_policy.db_access_to_secrets_manager.arn
}

resource "aws_iam_role_policy_attachment" "allow_kms_keys_access" {
  role       = aws_iam_role.db_ec2_oem_role.name
  policy_arn = aws_iam_policy.business_unit_kms_key_access.arn
}

# Define a custom IAM policy document to grant assume role permissions
data "aws_iam_policy_document" "ec2_oem_assume_role_policy_document" {
    statement {
      effect = "Allow"
      actions = [
        "sts:AssumeRole"
      ]

      resources = ["${aws_iam_role.db_ec2_oem_role.arn}"]
    }
}

# Create the IAM policy using the custom policy document
resource "aws_iam_policy" "ev2_oem_assume_role_policy" {
  name        = "AssumeRolePolicy"
  description = "Custom policy to grant assume role permissions to existing role to assume new OEM role"

  policy = data.aws_iam_policy_document.ec2_oem_assume_role_policy_document.json
}

# Attach a policy to the existing role granting assume role permissions for the new OEM role
resource "aws_iam_role_policy_attachment" "assume_role_policy_attachment" {
  policy_arn = aws_iam_policy.ev2_oem_assume_role_policy.arn
  role       = aws_iam_role.db_ec2_instance_iam_role.name
}