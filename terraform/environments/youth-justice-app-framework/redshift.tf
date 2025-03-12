module "redshift" {
  source = "./modules/redshift"

   project_name = local.project_name
   environment  = local.environment
   tags         = local.tags

   #Network details
   vpc_id           = data.aws_vpc.shared.id
   database_subnets = local.data_subnet_list[*].id

  rds_secret_rotation_arn = module.aurora.app_rotated_postgres_secret_arn
   
  postgres_security_group_id = module.aurora.rds_cluster_security_group_id

  kms_key_arn =  module.kms.key_arn

# [TODO] Replace the role below with the equicelent in the new environment
 # data_science_role = "arn:aws:iam::066012302209:role/data_science"
 
  depends_on = [ module.aurora, module.s3 ]
}
