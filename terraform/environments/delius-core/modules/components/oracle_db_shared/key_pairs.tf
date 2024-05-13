# Create SSM parameter to hold parameter with value to be manually added
resource "aws_ssm_parameter" "ec2_user_ssh_key" {
  name        = "/${var.env_name}/oracle-${var.db_suffix}/ec2-user-ssh-key"
  type        = "SecureString"
  value       = "initial_value_to_be_changed"
  key_id      = var.account_config.kms_keys.general_shared
  description = "ssh private key for ec2-user used for the ${var.db_suffix}"
  tags        = var.tags

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_key_pair" "db_ec2_key_pair" {
  key_name   = "${var.env_name}-oracle-${var.db_suffix}-ec2-user-key-pair"
  public_key = var.environment_config.ec2_user_ssh_key
  tags       = var.tags
}
