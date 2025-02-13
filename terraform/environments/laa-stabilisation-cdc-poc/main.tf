module "cwa-poc2-environment" {
  source = "./cwa-poc2"

  providers = {
    aws = aws
  }

  environment = local.environment
  application_data = local.application_data
  tags = local.tags
  route53_zone_external = data.aws_route53_zone.external.name
  route53_zone_external_id = data.aws_route53_zone.external.zone_id
  shared_ebs_kms_key_id = data.aws_kms_key.ebs_shared.key_id
  shared_vpc_id = data.aws_vpc.shared.id
  bastion_security_group    = module.bastion_linux.bastion_security_group
  
}