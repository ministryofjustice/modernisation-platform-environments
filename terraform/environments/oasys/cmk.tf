#------------------------------------------------------------------------------
# Customer Managed Key for AMI sharing
# Only created in Test account currently as AMIs encrypted using this key
# should be shared with Production account, hence Prod account requires permissions
# to use this key
#------------------------------------------------------------------------------


resource "aws_kms_grant" "image-builder-shared-cmk-grant" {
  name              = "image-builder-shared-cmk-grant"
  key_id            = module.environment.kms_keys["ebs"].arn
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
  key_id            = module.environment.kms_keys["ebs"].arn
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