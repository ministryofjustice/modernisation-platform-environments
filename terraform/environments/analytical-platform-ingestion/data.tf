data "aws_availability_zones" "available" {}

data "aws_prefix_list" "s3" {
  name = "com.amazonaws.eu-west-2.s3"

  depends_on = [module.isolated_vpc_endpoints]
}

data "aws_secretsmanager_secret_version" "slack_token" {
  secret_id = aws_secretsmanager_secret.slack_token.id
}

data "aws_secretsmanager_secret_version" "govuk_notify_api_key" {
  secret_id = aws_secretsmanager_secret.govuk_notify_api_key.id
}

data "aws_secretsmanager_secret_version" "govuk_notify_templates" {
  secret_id = aws_secretsmanager_secret.govuk_notify_templates.id
}

data "aws_ami" "datasync" {
  most_recent = true

  owners = ["633936118553"] # Amazon

  filter {
    name   = "name"
    values = ["aws-datasync-*"]
  }
}
