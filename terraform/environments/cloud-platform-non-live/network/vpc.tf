module "vpc" {
  version = "6.5.1"  
  source = "terraform-aws-modules/vpc/aws"

  name = "cloud-platform-non-live-vpc-development"
  cidr = "10.0.0.0/16"

  azs             = ["eu-west-2a", "eu-west-2b", "eu-west-2c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = true
  one_nat_gateway_per_az = true
  create_multiple_public_route_tables = true

  tags = {
    Terraform = "true"
    Environment = "dev"
  }
}
