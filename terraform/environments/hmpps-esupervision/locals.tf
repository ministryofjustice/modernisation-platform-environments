locals {
  rekog_s3_bucket_name = "${terraform.workspace}-rekognition-uploads"
  rekog_logs_s3_bucket_name = "${local.rekog_s3_bucket_name}-logs"

  # prefix for all log objects in the access logs bucket
  rekog_logs_prefix = "logs"

  developer_role_suffix = lookup(local.application_data.accounts[local.environment], "developer_role_suffix", null)
  developer_role_principals = (local.developer_role_suffix == null ?
    {} :
    {
      "Developer" : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-reserved/sso.amazonaws.com/eu-west-2/AWSReservedSSO_modernisation-platform-developer_${local.developer_role_suffix}"
    }
  )

  service_account_principals     = lookup(local.application_data.accounts[local.environment], "service_account_roles", {})
  allowed_assume_role_principals = merge(local.developer_role_principals, local.service_account_principals)
}