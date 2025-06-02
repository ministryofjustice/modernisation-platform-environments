module "tableau_cert" {
  source = "./modules/dns/certs"

  project_name = local.project_name

  r53_zone_id    = module.public_dns_zone.aws_route53_zone_id
  domain_name    = "${local.application_data.accounts[local.environment].tableau_website_name}.${local.application_data.accounts[local.environment].domain_name}"
  validate_certs = local.application_data.accounts[local.environment].validate_certs

  tags = local.tags
}


module "tableau" {
  source = "./modules/tableau"

  # count = 0

  project_name = local.project_name
  # tags         = merge(local.tags, { Name = "AD Management Server" })

  environment = local.environment
  test_mode   = local.test_mode

  #Network details
  vpc_id            = data.aws_vpc.shared.id
  tableau_subnet_id = local.private_subnet_list[0].id
  alb_subnet_ids    = local.public_subnet_list[*].id


  # Tableau ec2 instance details
  instance_type = "m5.4xlarge"


  # ALB Details
  certificate_arn      = module.tableau_cert.domain_cert_arn
  r53_zone_id          = module.public_dns_zone.aws_route53_zone_id
  tableau_website_name = local.application_data.accounts[local.environment].tableau_website_name


  # Security Group IDs
  postgresql_sg_id        = module.aurora.rds_cluster_security_group_id
  redshift_sg_id          = module.redshift.security_group_id
  directory_service_sg_id = module.ds.directory_service_sg_id
  management_server_sg_id = module.ds.management_server_sg_id
  yjsm_sg_id              = module.yjsm.yjsm_security_group_id
  esb_sg_id               = module.esb.esb_security_group_id

  datadog_api_key_arn   = module.datadog.datadog_api_key_arn
  availability_schedule = ""
  patch_schedule        = ""

  kms_key_arn = module.kms.key_arn


  depends_on = [module.tableau_cert, module.aurora, module.redshift, module.ds]
}
