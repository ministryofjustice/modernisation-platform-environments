module "rds_export" {
  source = "github.com/ministryofjustice/terraform-rds-export?ref=04916a52ce20590674198fc48456dad95d7dee75"

  # Replace the kms_key_arn, name, vpc_id and (database_subnet_ids in a list)
  kms_key_arn = aws_kms_key.sns_kms.arn
  name = "cafm"
  vpc_id = module.vpc.vpc_id
  database_subnet_ids = module.vpc.private_subnets

  tags = {
    business-unit = "Property"
    application   = local.application_name
    is-production = "false"
    owner         = "shanmugapriya.basker@justice.gov.uk"
  }
}


module "endpoints" {
  # Commit has for v5.21.0
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-vpc//modules/vpc-endpoints?ref=507193ee659f6f0ecdd4a75107e59e2a6c1ac3cc"

  vpc_id                     = module.vpc.vpc_id
  create_security_group      = true
  security_group_description = "Managed by Terraform"
  security_group_tags        = { Name : "eu-west-1-dev" }
  security_group_rules = {
    ingress_https = {
      description = "HTTPS from VPC"
      cidr_blocks = [module.vpc.vpc_cidr_block]
    }
  }
  endpoints = {

    s3 = {
      service_type    = "Gateway" # gateway endpoint
      service         = "s3"
      route_table_ids = module.vpc.private_route_table_ids
      tags            = { Name = "s3-eu-west-1-dev" }
    }

    secrets_manager = {
      service             = "secretsmanager"
      service_type        = "Interface"
      subnet_ids          = module.vpc.private_subnets
      private_dns_enabled = true
      tags                = { Name = "secretsmanager-eu-west-1-dev" }
    }
  }

  tags = {Name = "${local.application_name}-s3-secrets-endpoint"}

}