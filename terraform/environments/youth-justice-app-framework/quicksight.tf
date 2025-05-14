locals {
  quicksight_setup = local.application_data.accounts[local.environment].quicksight_setup
}

resource "aws_quicksight_account_subscription" "subscription" {
  count = var.quicksight_setup ? 0 : 1

  account_name                     = "${var.project_name}-${var.environment}-moj"
  edition                          = "ENTERPRISE"
  authentication_method            = "IAM_AND_QUICKSIGHT"
  notification_email               = var.notification_email
  
}


module "quicksight" {
  source = "./modules/quicksight"

  count = var.quicksight_setup ? 1 : 0

  project_name = local.project_name
  environment  = local.environment
  tags         = local.tags

  notification_email = "david.seekins@necsws.com" # For testing change later.

  vpc_id              = data.aws_vpc.shared.id

  database_subnet_ids = local.data_subnet_list[*].id

  postgresql_sg_id    = module.aurora.rds_cluster_security_group_id
  redshift_sg_id      = module.redshift.security_group_id

  redshift_host = module.redshift.address
  redshift_port = module.redshift.port
  redshift_quicksight_user_secret_arn = module.redshift.rds_quicksight_secret_arn

  postgres_host                       = module.aurora.rds_cluster_endpoint
  postgres_port                       = module.aurora.rds_cluster_port
  postgres_quicksight_user_secret_arn = module.aurora.rds_quicksight_secret_arn

  depends_on = [module.aurora, module.redshift]
 }