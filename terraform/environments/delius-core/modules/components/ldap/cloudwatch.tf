resource "aws_cloudwatch_log_group" "ldap_test" {
  name              = "/ecs/ldap_${var.env_name}"
  retention_in_days = 5
}
