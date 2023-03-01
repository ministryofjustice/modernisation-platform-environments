locals {

  kms_grants_filter = flatten([
    var.options.enable_business_unit_kms_cmks ? ["business-unit-ebs-cmk-grant-for-autoscaling"] : []
  ])

  kms_grants = {
    business-unit-ebs-cmk-grant-for-autoscaling = {
      key_id            = var.environment.kms_keys["ebs"].arn
      grantee_principal = "arn:aws:iam::${var.environment.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"
      operations = [
        "Encrypt",
        "Decrypt",
        "ReEncryptFrom",
        "ReEncryptTo",
        "GenerateDataKey",
        "GenerateDataKeyWithoutPlaintext",
        "DescribeKey",
        "CreateGrant"
      ]
    }
  }

}
