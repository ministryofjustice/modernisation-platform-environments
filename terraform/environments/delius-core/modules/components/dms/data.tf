data "aws_region" "current" {}

data "aws_ec2_managed_prefix_list" "s3" {
  name = "com.amazonaws.${data.aws_region.current.region}.s3"
}

data "aws_prefix_list" "s3" {
  prefix_list_id = data.aws_ec2_managed_prefix_list.s3.id
}


# As of date of writing, the AWS_DMS_ENDPOINT resource does not support using Secrets Manager for
# ASM connectivity as Oracle-specific attributes are not available.
# A replacement resource, aws_dms_oracle_endpoint, is in development and the following should be replaced
# once that becomes available.
# In the meantime we cannot use Secrets for holding connection details since we have no place where we
# can define the ASM password.
# We are therefore restricted to using inline definition of endpoints.  NB: We assume the delius_audit_dms_pool
# password is the same for both the DB and ASM instances.
# Reference:  https://github.com/hashicorp/terraform-provider-aws/issues/23506
data "aws_secretsmanager_secret" "delius_core_application_passwords" {
  arn = var.database_application_passwords_secret_arn
}

data "aws_secretsmanager_secret_version" "delius_core_application_passwords" {
  secret_id = data.aws_secretsmanager_secret.delius_core_application_passwords.id
}

