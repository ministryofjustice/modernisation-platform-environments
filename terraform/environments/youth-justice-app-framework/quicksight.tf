
## Ensure that the s3 log bucket exists before attempting to create any other buckets.
module "quicksight" {
  source = "./modules/quicksight"

  project_name = local.project_name
  environment  = local.environment
  tags         = local.tags

  create_quicksight_subscription = local.application_data.accounts[local.environment].create_quicksight_subscription

  notification_email = "david.seekins@necsws.com" # For testing change later.

  vpc_id              = data.aws_vpc.shared.id

  database_subnet_ids = local.data_subnet_list[*].id

  postgresql_sg_id    = module.aurora.rds_cluster_security_group_id
  redshift_sg_id      = module.redshift.security_group_id

  redshift_host = module.redshift.address
  redshift_port = module.redshift.port

  postgres_host = module.aurora.rds_cluster_endpoint.address
  postgres_port = module.aurora.rds_cluster_endpoint.port
}