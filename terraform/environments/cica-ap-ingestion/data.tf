data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_canonical_user_id" "current" {}

data "aws_iam_roles" "aws_sso_modernisation_platform_data_eng" {
  name_regex  = "AWSReservedSSO_modernisation-platform-data-eng_.*"
  path_prefix = "/aws-reserved/sso.amazonaws.com/"
}

data "aws_iam_role" "aws_sso_modernisation_platform_data_eng" {
  name = one(data.aws_iam_roles.aws_sso_modernisation_platform_data_eng.names)
}

data "aws_secretsmanager_secret" "environment_management" {
  provider = aws.modernisation-platform
  name     = "environment_management"
}


data "template_file" "table-mappings" {
  template = file("${path.module}/config/${var.short_name}-table-mappings.json.tpl")

  vars = {
    input_schema = var.rename_rule_source_schema
    output_space = var.rename_rule_output_space
  }
}

