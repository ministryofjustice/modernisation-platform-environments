module "nextcloud" {
  source = "../components/nextcloud"

  providers = {
    aws.core-network-services = aws.core-network-services
    aws.core-vpc              = aws.core-vpc
    aws                       = aws
  }

  env_name      = "dev"
  platform_vars = var.platform_vars

  account_config = var.account_config
  account_info   = var.account_info

  bastion_sg_id = module.bastion_linux.bastion_security_group

  tags = var.tags
}

# resource "aws_security_group_rule" "efs_ingress_nextcloud" {
#   type                     = "egress"
#   from_port                = 2049
#   to_port                  = 2049
#   protocol                 = "tcp"
#   source_security_group_id = module.nextcloud_efs.sg_id
#   security_group_id        = module.nextcloud_service.service_security_group_id
# }

# resource "aws_secretsmanager_secret" "nextcloud_admin_password" {
#   name = "nextcloud-admin-password"
# }

# resource "aws_secretsmanager_secret_version" "nextcloud_admin_password" {
#   secret_id     = aws_secretsmanager_secret.nextcloud_admin_password.id
#   secret_string = random_password.nextcloud_admin_password.result
# }

# resource "random_password" "nextcloud_admin_password" {
#   length  = 32
#   special = true
# }
