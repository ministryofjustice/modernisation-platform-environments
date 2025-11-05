module "redshift" {
  source = "./modules/redshift"

  project_name = local.project_name
  environment  = local.environment

  tags = local.tags

  # Network details
  vpc_id           = data.aws_vpc.shared.id
  database_subnets = local.data_subnet_list[*].id

  rds_redshift_secret_arns = [module.aurora.rds_redshift_secret_arn, module.aurora.rds_postgres_secret_arn]

  postgres_security_group_id = module.aurora.rds_cluster_security_group_id
  management_server_sg_id    = module.ds.management_server_sg_id


  kms_key_arn = module.kms.key_arn

  vpc_cidr = data.aws_vpc.shared.cidr_block

  data_science_role  = "arn:aws:iam::${local.account_id}:role/${local.yjb_data_scientist_role_name}"
  reports_admin_role = "arn:aws:iam::${local.account_id}:role/${local.reports_admin_role_name}"

  depends_on = [module.aurora, module.s3]
}
