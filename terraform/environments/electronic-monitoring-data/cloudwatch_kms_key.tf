data "aws_iam_policy_document" "cloudwatch_log_group_key" {
    #checkov:skip=CKV_AWS_7
    statement {
        sid = "Enable IAM User Permissions"
        effect = "Allow"
        actions = ["kms:*"]
        resources = ["*"]
        principals {
            type        = "AWS"
            identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]            
        }
    }
    statement {
        sid = "Allow CloudWatch Logs use of the key"
        effect = "Allow"
        actions = [
            "kms:Encrypt*",
            "kms:Decrypt*",
            "kms:ReEncrypt*",
            "kms:GenerateDataKey*",
            "kms:DescribeKey"
        ]
        resources = ["*"]
        principals {
            type = "Service"
            identifiers = ["logs.${data.aws_region.current.name}.amazonaws.com"]
        }
    }
}

resource "aws_kms_key" "cloudwatch_log_group_key" {
  description = "KMS key for CloudWatch log group encryption"
  policy = data.aws_iam_policy_document.cloudwatch_log_group_key
}
