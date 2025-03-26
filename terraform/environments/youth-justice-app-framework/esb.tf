# ESB EC2 Instance


module "esb" {
  source  = "./modules/esb"

  #Network details
  vpc_id                  = data.aws_vpc.shared.id
  subnet_id = one(tolist([for s in local.private_subnet_list : s.id if s.availability_zone == "eu-west-2a"]))

  # Assigning private IP based on environment
  private_ip = lookup(
    {
      development = "10.26.144.217"
      test        = "10.26.152.88"
      # Add more environments when IP is known
    },
    local.environment,
    null # Default to null, allowing AWS to auto-assign an IP
  )

  ami = lookup(
    {
      development = "ami-0fc27ddcf3e4e76af"
      # Add more environments when AMIs are known
    },
    local.environment,
    "ami-01426769db5cd0a43" # Default AMI
  )

  project_name    = local.project_name
  environment     = local.environment
  tags            = local.tags

  yjsm_service_sg_id             = module.yjsm.yjsm_security_group_id

}