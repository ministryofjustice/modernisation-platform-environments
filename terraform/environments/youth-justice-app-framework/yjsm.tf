
# YJSM EC2 Instance


module "yjsm" {
  source  = "./modules/yjsm"

  #Network details
  vpc_id                  = data.aws_vpc.shared.id
  subnet_id               = element([for s in local.private_subnet_list : s if s.availability_zone == "eu-west-2a"], 0)  # Forces ZONE A
  vpc_security_group_ids  = [module.yjsm.security_group_id]

  project_name = local.project_name
  environment  = local.environment
  tags         = local.tags

}

  