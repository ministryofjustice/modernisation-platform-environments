module "ds" {
  source = "./modules/directory-service"

  project_name = local.project_name
  tags         = merge(local.tags, { Name = "AD Management Server" })

  ds_managed_ad_directory_name = "i2n.com"
  ds_managed_ad_short_name     = "i2n"
  management_keypair_name      = "ad_management_server"

  ds_managed_ad_vpc_id     = data.aws_vpc.shared.id
  ds_managed_ad_subnet_ids = [data.aws_subnet.private_subnets_a.id, data.aws_subnet.private_subnets_b.id]
  vpc_cidr_block           = data.aws_vpc.shared.cidr_block
  management_subnet_id     = local.private_subnet_list[0].id
}
