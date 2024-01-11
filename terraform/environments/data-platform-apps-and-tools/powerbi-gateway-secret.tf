resource "aws_secretsmanager_secret" "powerbi_gateway_reg_credentials" {
  name = "${local.environment_configuration.powerbi_gateway_ec2.instance_name}-credentials"
}
