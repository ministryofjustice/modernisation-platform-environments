# Stand-ins for the network root's platform locals and VPC. run_pdc_tenant_tests.py copies the real locals.tf and
# observability_platform.tf next to this file in a disposable directory; never initialise the live backend.
terraform {
  required_version = "~> 1.0"
  required_providers {
    aws = {
      version = "~> 6.0, != 6.57.0"
      source  = "hashicorp/aws"
    }
  }
}

locals {
  environment_management = {
    account_ids = {
      observability-platform-development = "000000000001"
      observability-platform-production  = "000000000002"
    }
  }
  tags = { application = "cloud-platform" }
}

module "cluster_vpc" {
  source = "./cluster-vpc"
}
