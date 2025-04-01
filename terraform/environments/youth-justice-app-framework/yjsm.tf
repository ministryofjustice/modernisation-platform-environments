
# YJSM EC2 Instance


module "yjsm" {
  source = "./modules/yjsm"

  #Network details
  vpc_id    = data.aws_vpc.shared.id
  subnet_id = one(tolist([for s in local.private_subnet_list : s.id if s.availability_zone == "eu-west-2a"]))

  # Assigning private IP based on environment
  private_ip = lookup(
    {
      development     = "10.26.144.61"
      test            = "10.26.152.172"
      preproduction   = "10.27.144.83"
      # Add more environments when IP is known
    },
    local.environment,
    null # Default to null, allowing AWS to auto-assign an IP
  )

  ami = lookup(
    {
      development   = "ami-0165ab84499655148"
      preproduction = "ami-04ee6bb49367c4dd9"
      # Add more environments when AMIs are known
    },
    local.environment,
    "ami-01426769db5cd0a43" # Default AMI
  )

  project_name = local.project_name
  environment  = local.environment
  tags         = local.tags

  # Security Group IDs
  ecs_service_internal_sg_id    = module.ecs.ecs_service_internal_sg_id
  ecs_service_external_sg_id    = module.ecs.ecs_service_external_sg_id
  esb_service_sg_id             = module.esb.esb_security_group_id
  rds_cluster_security_group_id = module.aurora.rds_cluster_security_group_id
  alb_security_group_id         = module.internal_alb.alb_security_group_id
  #Keep until prod images are done
  tableau_sg_id                 = module.tableau.tableau_sg_id
}