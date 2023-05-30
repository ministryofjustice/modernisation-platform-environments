module "transport" {
  source                 = "./modules/transport"
  application_name       = "${local.project}-transport-${local.environment}"
  environment            = local.environment
  db_instance_identifier = local.application_data.accounts[local.environment].identifier

  tags = merge(
    local.all_tags,
    {
      Name          = "${local.project}-transport-${local.environment}"
    }
  )
}