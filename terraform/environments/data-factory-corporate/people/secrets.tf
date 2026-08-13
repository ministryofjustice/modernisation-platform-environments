resource "aws_secretsmanager_secret" "external_account" {
  #checkov:skip=CKV2_AWS_57: "Secret holds a static external AWS account ID — rotation not applicable"
  name        = "external-aws-account"
  description = "AWS account permitted to assume the external role"
  kms_key_id = module.sherlock_kms_key.key_arn

  tags = {
    Environment = terraform.workspace
    Application = "data-factory-corporate"
    Component   = "people"
    Infrastructure = "sherlock-secret-id"
  }
}

module "sherlock_kms_key" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-kms.git//?ref=496d8bd559afebb43b78af0034ec74d8b32378ca"

  aliases = ["sherlock-landing"]
}