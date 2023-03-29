#------------------------------------------------------------------------------
# Customer Managed Key for AMI sharing
# Only created in Test account currently as AMIs encrypted using this key
# should be shared with Production account, hence Prod account requires permissions
# to use this key
#------------------------------------------------------------------------------


data "aws_kms_key" "ebs_hmpps" { key_id = "arn:aws:kms:${local.region}:${local.environment_management.account_ids["core-shared-services-production"]}:alias/ebs-${local.business_unit}" }

resource "aws_kms_grant" "image-builder-shared-cmk-grant" {
  name              = "image-builder-shared-cmk-grant"
  key_id            = data.aws_kms_key.ebs_hmpps.arn
  grantee_principal = "arn:aws:iam::${local.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"
  operations = [
    "Encrypt",
    "Decrypt",
    "ReEncryptFrom",
    "GenerateDataKey",
    "GenerateDataKeyWithoutPlaintext",
    "DescribeKey",
    "CreateGrant"
  ]
}


resource "aws_kms_grant" "ssm-start-stop-shared-cmk-grant" {
  count             = local.environment == "test" ? 1 : 0
  name              = "image-builder-shared-cmk-grant"
  key_id            = data.aws_kms_key.ebs_hmpps.arn
  grantee_principal = aws_iam_role.ssm_ec2_start_stop.arn
  operations = [
    "Encrypt",
    "Decrypt",
    "ReEncryptFrom",
    "GenerateDataKey",
    "GenerateDataKeyWithoutPlaintext",
    "DescribeKey",
    "CreateGrant"
  ]
}

