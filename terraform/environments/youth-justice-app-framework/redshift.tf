#import {
#  to = module.redshift.aws_redshiftserverless_namespace.default
#  id = "yjfa-development-test"
#}

#import {
#  to = module.redshift.aws_redshiftserverless_workgroup.default
#  id = "yjaf-development-test"
#}



module "redshift" {
  source = "./modules/redshift"

   project_name     = local.project_name
   environment_name = local.environment_name
   tags             = local.tags

   #Network details
   vpc_id           = data.aws_vpc.shared.id
   database_subnets = local.data_subnet_list[*].id

  rds_secret_rotation_arn = module.aurora.app_rotated_postgres_secret_arn
   
  
 
  depends_on = [ module.aurora, module.s3]
}
