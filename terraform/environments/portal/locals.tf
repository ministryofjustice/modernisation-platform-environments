#### This file can be used to store locals specific to the member account ####
locals {
  ami-id = "ami-00dae97434cc155f6"
  oim_ami-id = "ami-013d0d5e3de018001"
  first-cidr = "10.202.0.0/20"
  second-cidr= "10.200.0.0/20"
  third-cidr                      = "10.200.16.0/20"
  prd-cidr                        = "10.200.16.0/20"
  aws_region                      = "eu-west-2"
  nonprod_workspaces_cidr         = "10.200.0.0/20"
  prod_workspaces_cidr            = "10.200.16.0/20"
  redc_cidr                       = "172.16.0.0/20"
  atos_cidr                       = "10.0.0.0/8"
  portal_hosted_zone              = data.aws_route53_zone.external.name

}
  

