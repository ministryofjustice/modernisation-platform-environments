resource "aws_cloudwatch_log_group" "ldap_ecs" {
  name              = "/ecs/ldap_${var.env_name}"
  retention_in_days = 5
}

resource "aws_cloudwatch_log_group" "ldap_automation" {
  name              = "/ecs/ldap-automation_${var.env_name}"
  retention_in_days = 5
}