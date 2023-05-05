# AWS Managed KMS keys

data "aws_kms_alias" "sns" {
  name = "alias/aws/sns"
}

data "aws_kms_key" "sns" {
  key_id = "alias/aws/sns"
}

data "aws_iam_policy_document" "sprinkler_ebs_encryption_policy_doc" {
  # Allow root users full management access to key
  statement {
    effect = "Allow"
    actions = [
      "kms:*"
    ]

    resources = ["*"] # Represents the key to which this policy is attached

    # AWS should add the AWS account by default but adding here for visibility
    principals {
      type        = "AWS"
      identifiers = [data.aws_caller_identity.current.account_id] #
    }
  }

  # Allow all mod platform account to use this key so that they can launch ec2 instances based on AMIs backed by encrypted snapshots
  statement {
    effect = "Allow"
    actions = [
      "kms:DescribeKey",
      "kms:ReEncrypt*",
      "kms:CreateGrant",
      "kms:Decrypt"
    ]

    resources = ["*"]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    condition {
      test     = "ForAnyValue:StringLike"
      variable = "aws:PrincipalOrgPaths"
      values = [
        "${data.aws_organizations_organization.root_account.id}/*/${local.environment_management.modernisation_platform_organisation_unit_id}/*"
      ]
    }
  }
}