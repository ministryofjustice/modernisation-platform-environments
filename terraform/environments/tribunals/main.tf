module "lands_chamber" {
  source                 = "./modules/lands_chamber"
  application_name       = "lands_chamber"
  environment            = local.environment
  db_instance_identifier = local.application_data.accounts[local.environment].db_identifier
 
}