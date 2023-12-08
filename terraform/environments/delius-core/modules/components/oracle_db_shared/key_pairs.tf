# Create SSM parameter to hold parameter with value to be manually added
resource "aws_ssm_parameter" "ec2_user_ssh_key" {
  name        = format("/%s/oracle_db/ec2-user-ssh-key", var.env_name)
  type        = "SecureString"
  value       = "initial_value_to_be_changed"
  key_id      = var.account_config.general_shared_kms_key_arn
  description = format("ssh private key for ec2-user used for the %s environment", var.env_name)
  tags        = var.tags

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_key_pair" "db_ec2_key_pair" {
  key_name   = format("%s-oracle-db-ec2-user-key-pair", var.env_name)
  public_key = var.environment_config.ec2_user_ssh_key
  tags       = var.tags
}
