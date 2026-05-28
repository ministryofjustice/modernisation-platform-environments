#### This file can be used to store locals specific to the member account ####
locals {
  first-cidr              = "10.202.0.0/20"
  second-cidr             = "10.200.0.0/20"
  third-cidr              = "10.200.16.0/20"
  prd-cidr                = "10.200.16.0/20"
  aws_region              = "eu-west-2"
  nonprod_workspaces_cidr = "10.200.0.0/20"
  prod_workspaces_cidr    = "10.200.16.0/20"
  redc_cidr               = "172.16.0.0/20"
  atos_cidr               = "10.0.0.0/8"

  # Temp local variable for environments where we wish to build out the EBS to be transfered to EFS
  ebs_conditional = ["testing", "preproduction", "production"]

  lb_enable_deletion_protection  = local.application_data.accounts[local.environment].lb_enable_deletion_protection
  efs_enable_deletion_protection = local.application_data.accounts[local.environment].efs_enable_deletion_protection
}
