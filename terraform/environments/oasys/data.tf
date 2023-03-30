
data "aws_iam_policy_document" "user-s3-access" {
  statement {
    sid = "user-s3-access"
    actions = [
      # "s3:GetObject",
      # "s3:PutObject",
      # "s3:PutObjectAcl",
      # "s3:ListBucket"
      "s3:*"
    ]
    resources = ["${module.s3-bucket.bucket.arn}/*",
    module.s3-bucket.bucket.arn, ]
  }
}


data "aws_iam_policy_document" "shared_image_builder_cmk_policy" {
  statement {
    effect = "Allow"
    actions = ["kms:Encrypt",
      "kms:Decrypt",
      "kms:Encrypt",
      "kms:ReEncrypt*",
      "kms:ReEncryptFrom",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
      "kms:CreateGrant"
    ]
    # these can be ignored as this policy is being applied to a specific key resource. ["*"] in this case refers to this key
    #tfsec:ignore:aws-iam-no-policy-wildcards
    #checkov:skip=CKV_AWS_111: "Ensure IAM policies does not allow write access without constraints"
    #checkov:skip=CKV_AWS_109: "Ensure IAM policies does not allow permissions management / resource exposure without constraints"
    resources = ["*"]
    principals {
      type = "AWS"
      identifiers = ["arn:aws:iam::${local.account_id}:root",
        "arn:aws:iam::${local.environment_management.account_ids["core-shared-services-production"]}:root",
        "arn:aws:iam::${local.environment_management.account_ids["oasys-development"]}:root",
        "arn:aws:iam::${local.environment_management.account_ids["oasys-preproduction"]}:root",
        "arn:aws:iam::${local.environment_management.account_ids["oasys-production"]}:root",
        "arn:aws:iam::${local.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"
      ]
    }
  }
  statement {
    effect = "Allow"
    actions = [
      "kms:Create*",
      "kms:Describe*",
      "kms:Enable*",
      "kms:List*",
      "kms:Put*",
      "kms:Update*",
      "kms:Revoke*",
      "kms:Disable*",
      "kms:Get*",
      "kms:Delete*",
      "kms:ScheduleKeyDeletion",
      "kms:CancelKeyDeletion"
    ]
    # these can be ignored as this policy is being applied to a specific key resource. ["*"] in this case refers to this key
    #tfsec:ignore:aws-iam-no-policy-wildcards
    #checkov:skip=CKV_AWS_111: "Ensure IAM policies does not allow write access without constraints"
    #checkov:skip=CKV_AWS_109: "Ensure IAM policies does not allow permissions management / resource exposure without constraints"
    resources = ["*"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.account_id}:root"]
    }
  }
}

data "aws_kms_key" "ebs_hmpps" { key_id = "arn:aws:kms:${local.region}:${local.environment_management.account_ids["core-shared-services-production"]}:alias/ebs-${local.business_unit}" }

data "aws_iam_policy_document" "ssm_ec2_start_stop_kms" {
  statement {
    sid    = "manageSharedAMIsEncryptedEBSVolumes"
    effect = "Allow"
    #tfsec:ignore:aws-iam-no-policy-wildcards
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:ReEncryptFrom",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
      "kms:CreateGrant",
      "kms:ListGrants",
      "kms:RevokeGrant"
    ]
    # we have a legacy CMK that's used in production that will be retired but in the meantime requires permissions
    resources = [data.aws_kms_key.ebs_hmpps.arn]
  }

  statement {
    sid    = "modifyAautoscalingGroupProcesses"
    effect = "Allow"

    actions = [
      "autoscaling:SuspendProcesses",
      "autoscaling:ResumeProcesses",
      "autoscaling:DescribeAutoScalingGroups",
    ]
    #this role manages all the autoscaling groups in an account
    #checkov:skip=CKV_AWS_111: "Ensure IAM policies does not allow write access without constraints"
    #checkov:skip=CKV_AWS_109: "Ensure IAM policies does not allow permissions management / resource exposure without constraints"
    resources = ["*"] #tfsec:ignore:aws-iam-no-policy-wildcards
  }
}