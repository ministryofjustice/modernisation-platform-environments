/* module "rotate_system_root_password" {
  source = "./modules/ec2-rotate-root-password"

  application_name = local.application_name
  aws_account_id   = data.aws_caller_identity.current.account_id

  tags = local.tags
} */
