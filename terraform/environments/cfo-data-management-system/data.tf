#### This file can be used to store data specific to the member account ####

# Shared MoJ IP address ranges used for ALB ingress rules
module "ip_addresses" {
  source = "../../modules/ip_addresses"
}

# Look up the RDS security group created by the MP RDS module (module outputs.tf is empty)
data "aws_security_group" "rds" {
  name   = "${local.application_name_short}-${local.environment}-rds"
  vpc_id = data.aws_vpc.shared.id

  depends_on = [module.rds]
}

# Look up the RDS instance to retrieve its endpoint and master user secret ARN
data "aws_db_instance" "rds" {
  db_instance_identifier = "${local.application_name_short}-${local.environment}-rds"

  depends_on = [module.rds]
}

# Look up the RDS master password secret created by the MP RDS module.
# The module appends a random hex suffix to the name, so we filter by prefix.
data "aws_secretsmanager_secrets" "rds-password" {
  filter {
    name   = "name"
    values = ["${local.application_name_short}-${local.environment}-rds-master-password"]
  }

  depends_on = [module.rds]
}

data "aws_secretsmanager_secret_version" "rds-master-password" {
  secret_id = tolist(data.aws_secretsmanager_secrets.rds-password.arns)[0]
}

# CloudFront managed prefix list restricts visualiser ALB ingress to CloudFront edge nodes only
data "aws_ec2_managed_prefix_list" "cloudfront" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}
