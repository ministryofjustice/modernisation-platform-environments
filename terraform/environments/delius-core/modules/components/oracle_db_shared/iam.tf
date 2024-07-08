##############################################
# IAM Instance Profile
##############################################
#resource "aws_iam_instance_profile" "db_ec2_instanceprofile" {
#  name = format("%s-delius-db-ec2_instance_iam_role", var.env_name)
#  role = aws_iam_role.db_ec2_instance_iam_role.name
#}


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


#resource "aws_iam_role" "db_ec2_instance_iam_role" {
#  name               = lower(format("%s-delius-db-ec2_instance", var.env_name))
#  assume_role_policy = data.aws_iam_policy_document.db_ec2_instance_iam_assume_policy.json
#  tags = merge(var.tags,
#    { Name = lower(format("%s-delius-db-ec2_instance", var.env_name)) }
#  )
#}

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
  name   = "${var.env_name}-${var.db_suffix}-business-unit-kms-key-access-policy"
  path   = "/"
  policy = data.aws_iam_policy_document.business_unit_kms_key_access.json
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
  name   = "${var.env_name}-${var.db_suffix}-core-shared-services-bucket-access-policy"
  path   = "/"
  policy = data.aws_iam_policy_document.core_shared_services_bucket_access.json
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
  name   = "${var.account_info.application_name}-${var.env_name}-${var.db_suffix}-ssm-parameter-store-access"
  path   = "/"
  policy = data.aws_iam_policy_document.allow_access_to_ssm_parameter_store.json
}
#
#resource "aws_iam_role_policy_attachment" "allow_access_to_ssm_parameter_store" {
#  role       = aws_iam_role.db_ec2_instance_iam_role.name
#  policy_arn = aws_iam_policy.allow_access_to_ssm_parameter_store.arn
#}

resource "aws_iam_policy" "ec2_access_for_ansible" {
  name   = "${var.account_info.application_name}-${var.env_name}-${var.db_suffix}-ansible-ec2-access"
  path   = "/"
  policy = data.aws_iam_policy_document.ec2_access_for_ansible.json
}

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

#resource "aws_iam_role_policy_attachment" "db_ec2_instance_amazonssmmanagedinstancecore" {
#  role       = aws_iam_role.db_ec2_instance_iam_role.name
#  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
#}

# Policy document for both Oracle database DBA and application secrets

data "aws_iam_policy_document" "db_access_to_secrets_manager" {
  statement {
    sid = "DbAccessToSecretsManager"
    actions = [
      "secretsmanager:Describe*",
      "secretsmanager:Get*",
      "secretsmanager:ListSecret*",
      "secretsmanager:Put*",
      "secretsmanager:RestoreSecret",
      "secretsmanager:Update*"
    ]
    effect = "Allow"
    resources = [
      aws_secretsmanager_secret.database_dba_passwords.arn,
      aws_secretsmanager_secret.database_application_passwords.arn,
    ]
  }
}

# Policy to allow access to both Oracle database DBA and application secrets

resource "aws_iam_policy" "db_access_to_secrets_manager" {
  name   = "${var.account_info.application_name}-${var.env_name}-${var.db_suffix}-secrets-manager-access"
  policy = data.aws_iam_policy_document.db_access_to_secrets_manager.json
}


data "aws_iam_policy_document" "instance_ssm" {
  statement {
    sid    = "SSMManagedSSM"
    effect = "Allow"
    actions = [
      "ssm:DescribeAssociation",
      "ssm:GetDeployablePatchSnapshotForInstance",
      "ssm:GetDocument",
      "ssm:DescribeDocument",
      "ssm:GetManifest",
      "ssm:ListAssociations",
      "ssm:ListInstanceAssociations",
      "ssm:PutInventory",
      "ssm:PutComplianceItems",
      "ssm:PutConfigurePackageResult",
      "ssm:UpdateAssociationStatus",
      "ssm:UpdateInstanceAssociationStatus",
      "ssm:UpdateInstanceInformation",
      "ssm:GetParameter*"
    ]
    resources = [
      "*"
    ]
  }

  statement {
    sid    = "SSMManagedSSMMessages"
    effect = "Allow"
    actions = [
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "SSMManagedEC2Messages"
    effect = "Allow"
    actions = [
      "ec2messages:AcknowledgeMessage",
      "ec2messages:DeleteMessage",
      "ec2messages:FailMessage",
      "ec2messages:GetEndpoint",
      "ec2messages:GetMessages",
      "ec2messages:SendReply"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "instance_ssm" {
  name   = "${var.account_info.application_name}-${var.env_name}-${var.db_suffix}-ssm-access"
  policy = data.aws_iam_policy_document.instance_ssm.json
}

# new IAM role OEM setup to allow ec2s to access secrets manager and kms keys
# resource "aws_iam_role" "EC2OracleEnterpriseManagementSecretsRole" {
#   name = "EC2OracleEnterpriseManagementSecretsRole-${var.env_name}-${var.db_suffix}"

#   assume_role_policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Effect": "Allow",
#       "Principal": {
#         "AWS": "*"
#       },
#       "Action": "sts:AssumeRole",
#       "Condition": {
#         "ForAnyValue:ArnLike": {
#           "aws:PrincipalArn": "arn:aws:iam::${var.account_info.id}:role/instance-role-${var.account_info.application_name}-${var.env_name}-${var.db_suffix}-*"
#         }
#       }
#     }
#   ]
# }
# EOF
# }

# resource "aws_iam_role_policy_attachment" "allow_kms_keys_access" {
#   role       = aws_iam_role.EC2OracleEnterpriseManagementSecretsRole.name
#   policy_arn = aws_iam_policy.business_unit_kms_key_access.arn
# }

# data "aws_iam_policy_document" "OracleEnterpriseManagementSecretsPolicyDocument" {
#   statement {
#     sid    = "OracleEnterpriseManagementSecretsPolicyDocument"
#     effect = "Allow"
#     actions = [
#       "secretsmanager:GetSecretValue"
#     ]
#     resources = [
#       "arn:aws:secretsmanager:*:*:secret:/oracle/database/EMREP/shared-*",
#       "arn:aws:secretsmanager:*:*:secret:/oracle/database/*RCVCAT/shared-*",
#       "arn:aws:secretsmanager:*:*:secret:/oracle/oem/shared-*"
#     ]
#   }
# }

# resource "aws_iam_policy" "OracleEnterpriseManagementSecretsPolicy" {
#   name   = "OracleEnterpriseManagementSecretsPolicy-${var.env_name}-${var.db_suffix}"
#   policy = data.aws_iam_policy_document.OracleEnterpriseManagementSecretsPolicyDocument.json
# }

# resource "aws_iam_role_policy_attachment" "OracleEnterpriseManagementSecretsPolicy" {
#   role       = aws_iam_role.EC2OracleEnterpriseManagementSecretsRole.name
#   policy_arn = aws_iam_policy.OracleEnterpriseManagementSecretsPolicy.arn
# }



# new IAM role OEM setup to allow DMS to access secrets manager and kms keys
resource "aws_iam_role" "DMSSecretsManagerAccessRole" {
  name = "DMSSecretsManagerAccessRole"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
         "Service": ["dms.eu-west-2.amazonaws.com"]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "dms_allow_kms_keys_access" {
  role       = aws_iam_role.DMSSecretsManagerAccessRole.name
  policy_arn = aws_iam_policy.business_unit_kms_key_access.arn
}

data "aws_iam_policy_document" "DMSSecretsManagerAccessRolePolicyDocument" {
  statement {
    sid    = "DMSSecretsManagerAccessRolePolicyDocument"
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue"
    ]
    resources = [
      "arn:aws:secretsmanager:*:*:secret:dms_audit_endpoint_source-*",
      "arn:aws:secretsmanager:*:*:secret:dms_audit_endpoint_target-*",
      "arn:aws:secretsmanager:*:${local.delius_account_id}:secret:delius-core-${var.env_name}-oracle-db-application-passwords*"

    ]
  }
}

resource "aws_iam_policy" "DMSSecretsManagerAccessRolePolicy" {
  name   = "DMSSecretsManagerAccessRolePolicy"
  policy = data.aws_iam_policy_document.DMSSecretsManagerAccessRolePolicyDocument.json
}

resource "aws_iam_role_policy_attachment" "DMSSecretsManagerAccessRolePolicy" {
  role       = aws_iam_role.DMSSecretsManagerAccessRole.name
  policy_arn = aws_iam_policy.DMSSecretsManagerAccessRolePolicy.arn
}

