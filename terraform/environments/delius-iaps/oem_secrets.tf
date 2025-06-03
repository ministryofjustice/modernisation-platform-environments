
# Get the map of oem agent registration secret from the oem account
data "aws_secretsmanager_secret" "oem_agent_password" {
  provider = aws.hmpps-oem
  name     = "oem_agent_password"
}

data "aws_secretsmanager_secret_version" "oem_agent_password" {
  provider = aws.hmpps-oem
  secret_id = "arn:aws:secretsmanager:eu-west-2:${local.oem_account_id}:secret:/oracle/oem/shared-passwords"
}

locals {
  oem_agent_password = jsondecode(data.aws_secretsmanager_secret_version.oem_agent_password.secret_string)["agentreg"]
}

