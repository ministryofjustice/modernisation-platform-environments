
# YJSM EC2 Instance


module "yjsm" {
  source  = "./modules/yjsm"

  #Network details
  vpc_id                  = data.aws_vpc.shared.id
  subnet_id = one(tolist([for s in local.private_subnet_list : s.id if s.availability_zone == "eu-west-2a"]))



  project_name    = local.project_name
  environment     = local.environment
  tags            = local.tags

}

  