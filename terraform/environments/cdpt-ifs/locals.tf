#### This file can be used to store locals specific to the member account ####
locals {

ecr_url = "${local.environment_management.account_ids["core-shared-services-production"]}.dkr.ecr.eu-west-2.amazonaws.com/cdpt-ifs-ecr-repo"

}