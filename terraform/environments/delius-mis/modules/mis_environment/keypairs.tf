resource "aws_key_pair" "ec2_user_key_pair" {
  key_name   = "${var.env_name}-${var.app_name}-${var.env_name}-ec2-user-key-pair"
  public_key = var.environment_config.ec2_user_ssh_key
  tags       = var.tags
}
