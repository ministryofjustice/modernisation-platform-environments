module "ds" {
  source = "./modules/directory-service"

  project_name = local.project_name
  environment  = local.environment
  tags         = merge(local.tags, { Name = "AD Management Server" })

  ad_management_instance_count = local.application_data.accounts[local.environment].ad_management_instance_count


  ds_managed_ad_directory_name = "i2n.com"
  ds_managed_ad_short_name     = "i2n"
  management_keypair_name      = "ad_management_server"
  ds_managed_ad_secret_key     = module.kms.key_arn

  ds_managed_ad_vpc_id = data.aws_vpc.shared.id
  private_subnet_ids   = [data.aws_subnet.private_subnets_a.id, data.aws_subnet.private_subnets_b.id, data.aws_subnet.private_subnets_c.id]
  vpc_cidr_block       = data.aws_vpc.shared.cidr_block

  rds_cluster_security_group_id = module.aurora.rds_cluster_security_group_id

  depends_on = [module.aurora]
}
