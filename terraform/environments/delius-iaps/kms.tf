##
# Grant access to AWSServiceRoleForAutoScaling to use the shared HMPPS ebs KMS CMK that Image Builder uses to encrypt AMIs
# See https://docs.aws.amazon.com/autoscaling/ec2/userguide/key-policy-requirements-EBS-encryption.html#policy-example-cmk-cross-account-access for more info 
##

data "aws_kms_key" "hmpps_ebs_key" {
  # Look up the shared CMK in core-shared-services-production used to create AMIs
  key_id = "arn:aws:kms:${data.aws_region.current.name}:${local.environment_management.account_ids["core-shared-services-production"]}:alias/ebs-hmpps"
}

resource "aws_kms_grant" "image-builder-shared-hmpps-ebs-cmk-grant" {
  name              = "image-builder-shared-hmpps-ebs-cmk-grant"
  key_id            = data.aws_kms_key.hmpps_ebs_key.arn
  grantee_principal = "arn:aws:iam::${local.environment_management.account_ids[terraform.workspace]}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"
  operations = [
    "Encrypt",
    "Decrypt",
    "ReEncryptFrom",
    "GenerateDataKey",
    "GenerateDataKeyWithoutPlaintext",
    "DescribeKey",
    "CreateGrant"
  ]

  depends_on = [module.ec2_iaps_server]
}
