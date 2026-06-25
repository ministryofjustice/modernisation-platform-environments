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

# CloudFront managed prefix list restricts visualiser ALB ingress to CloudFront edge nodes only
data "aws_ec2_managed_prefix_list" "cloudfront" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}
