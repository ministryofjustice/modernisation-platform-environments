# ESB EC2 Instance


module "esb" {
  source = "./modules/esb"

  #Network details
  vpc_id    = data.aws_vpc.shared.id
  subnet_id = one(tolist([for s in local.private_subnet_list : s.id if s.availability_zone == "eu-west-2a"]))

  # Assigning private IP based on environment
  private_ip = lookup(
    {
      development   = "10.26.144.217"
      test          = "10.26.152.88"
      preproduction = "10.27.144.238"
      production    = "10.27.152.38"
      # Add more environments when IP is known
    },
    local.environment,
    null # Default to null, allowing AWS to auto-assign an IP
  )

  # Choose the AMI, defaulting to the default AMI if not found(doesnt work try and fix)
  ami = lookup(
    {
      development   = "ami-0cc0dad47bc769c08"
      test          = "ami-0ada811b153e02322"
      preproduction = "ami-04a6fa2443473cfd5"
      production    = "ami-0b14bd01e84f3e0a5"

      # Add more environments when AMIs are known
    },
    local.environment,
    "ami-01426769db5cd0a43" # Default AMI
  )

  project_name = local.project_name
  environment  = local.environment
  tags         = local.tags

  yjsm_service_sg_id         = module.yjsm.yjsm_security_group_id
  ecs_service_internal_sg_id = module.ecs.ecs_service_internal_sg_id
  ecs_service_external_sg_id = module.ecs.ecs_service_external_sg_id
  alb_security_group_id      = module.internal_alb.alb_security_group_id
  mgmt_instance_sg_id        = module.ds.management_server_sg_id
  tableau_sg_id              = module.tableau.tableau_sg_id

}
