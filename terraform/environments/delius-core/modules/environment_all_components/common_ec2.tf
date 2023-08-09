# Create SSM parameter to hold parameter with value to be manually added
resource "aws_ssm_parameter" "ec2-user-ssh-key" {
  name        = format("/%s/ec2-user-ssh-key", var.env_name)
  type        = "SecureString"
  value       = "initial_value_to_be_changed"
  key_id      = var.account_config.general_shared_kms_key_arn
  description = format("ssh private key for ec2-user used for the %s environment", var.env_name)
  tags        = local.tags
}

resource "aws_key_pair" "environment_ec2_user_key_pair" {
  key_name   = format("%s-ec2-user-key-pair", var.env_name)
  public_key = var.environment_config.ec2_user_ssh_key
  tags       = local.tags
}
