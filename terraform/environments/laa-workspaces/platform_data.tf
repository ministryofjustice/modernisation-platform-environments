# Current account data
data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

# VPC and subnet data
# NOTE: Shared VPC data sources commented out - this is an isolated account
# with its own VPC defined in new-vpc.tf

# data "aws_vpc" "shared" {
#   tags = {
#     "Name" = "${var.networking[0].business-unit}-${local.environment}"
#   }
# }

# data "aws_subnets" "shared-data" {
#   filter {
#     name   = "vpc-id"
#     values = [data.aws_vpc.shared.id]
#   }
#   tags = {
#     Name = "${var.networking[0].business-unit}-${local.environment}-${var.networking[0].set}-data*"
#   }
# }

# data "aws_subnets" "shared-private" {
#   filter {
#     name   = "vpc-id"
#     values = [data.aws_vpc.shared.id]
#   }
#   tags = {
#     Name = "${var.networking[0].business-unit}-${local.environment}-${var.networking[0].set}-private*"
#   }
# }

# data "aws_subnets" "shared-public" {
#   filter {
#     name   = "vpc-id"
#     values = [data.aws_vpc.shared.id]
#   }
#   tags = {
#     Name = "${var.networking[0].business-unit}-${local.environment}-${var.networking[0].set}-public*"
#   }
# }

# data "aws_subnet" "data_subnets_a" {
#   vpc_id = data.aws_vpc.shared.id
#   tags = {
#     "Name" = "${var.networking[0].business-unit}-${local.environment}-${var.networking[0].set}-data-${data.aws_region.current.region}a"
#   }
# }

# data "aws_subnet" "data_subnets_b" {
#   vpc_id = data.aws_vpc.shared.id
#   tags = {
#     "Name" = "${var.networking[0].business-unit}-${local.environment}-${var.networking[0].set}-data-${data.aws_region.current.region}b"
#   }
# }

# data "aws_subnet" "data_subnets_c" {
#   vpc_id = data.aws_vpc.shared.id
#   tags = {
#     "Name" = "${var.networking[0].business-unit}-${local.environment}-${var.networking[0].set}-data-${data.aws_region.current.region}c"
#   }
# }

# data "aws_subnet" "private_subnets_a" {
#   vpc_id = data.aws_vpc.shared.id
#   tags = {
#     "Name" = "${var.networking[0].business-unit}-${local.environment}-${var.networking[0].set}-private-${data.aws_region.current.region}a"
#   }
# }

# data "aws_subnet" "private_subnets_b" {
#   vpc_id = data.aws_vpc.shared.id
#   tags = {
#     "Name" = "${var.networking[0].business-unit}-${local.environment}-${var.networking[0].set}-private-${data.aws_region.current.region}b"
#   }
# }

# data "aws_subnet" "private_subnets_c" {
#   vpc_id = data.aws_vpc.shared.id
#   tags = {
#     "Name" = "${var.networking[0].business-unit}-${local.environment}-${var.networking[0].set}-private-${data.aws_region.current.region}c"
#   }
# }

# data "aws_subnet" "public_subnets_a" {
#   vpc_id = data.aws_vpc.shared.id
#   tags = {
#     Name = "${var.networking[0].business-unit}-${local.environment}-${var.networking[0].set}-public-${data.aws_region.current.region}a"
#   }
# }

# data "aws_subnet" "public_subnets_b" {
#   vpc_id = data.aws_vpc.shared.id
#   tags = {
#     Name = "${var.networking[0].business-unit}-${local.environment}-${var.networking[0].set}-public-${data.aws_region.current.region}b"
#   }
# }

# data "aws_subnet" "public_subnets_c" {
#   vpc_id = data.aws_vpc.shared.id
#   tags = {
#     Name = "${var.networking[0].business-unit}-${local.environment}-${var.networking[0].set}-public-${data.aws_region.current.region}c"
#   }
# }

# Route53 DNS data
# NOTE: Route53 zones commented out - no shared DNS zones for isolated account

# data "aws_route53_zone" "external" {
#   provider = aws.core-vpc
#
#   name         = "${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk."
#   private_zone = false
# }

# data "aws_route53_zone" "inner" {
#   provider = aws.core-vpc
#
#   name         = "${var.networking[0].business-unit}-${local.environment}.modernisation-platform.internal."
#   private_zone = true
# }

# data "aws_route53_zone" "network-services" {
#   provider = aws.core-network-services
#
#   name         = "modernisation-platform.service.justice.gov.uk."
#   private_zone = false
# }

# Shared KMS keys (per business unit)
# NOTE: Shared KMS keys not accessible from isolated account
# We create our own KMS key in new-kms.tf instead
# data "aws_kms_key" "general_shared" {
#   key_id = "arn:aws:kms:eu-west-2:${local.environment_management.account_ids["core-shared-services-production"]}:alias/general-${var.networking[0].business-unit}"
# }

# data "aws_kms_key" "ebs_shared" {
#   key_id = "arn:aws:kms:eu-west-2:${local.environment_management.account_ids["core-shared-services-production"]}:alias/ebs-${var.networking[0].business-unit}"
# }

# data "aws_kms_key" "rds_shared" {
#   key_id = "arn:aws:kms:eu-west-2:${local.environment_management.account_ids["core-shared-services-production"]}:alias/rds-${var.networking[0].business-unit}"
# }

# State for core-network-services resource information
data "terraform_remote_state" "core_network_services" {
  backend = "s3"
  config = {
    acl     = "bucket-owner-full-control"
    bucket  = "modernisation-platform-terraform-state"
    key     = "environments/accounts/core-network-services/core-network-services-production/terraform.tfstate"
    region  = "eu-west-2"
    encrypt = "true"
  }
}

# State for workspace-components (VPC and subnets)
data "terraform_remote_state" "workspace_components" {
  backend = "s3"
  config = {
    acl     = "bucket-owner-full-control"
    bucket  = "modernisation-platform-terraform-state"
    key     = "environments/members/laa-workspaces/workspace-components/${terraform.workspace}/terraform.tfstate"
    region  = "eu-west-2"
    encrypt = "true"
  }
}

data "aws_organizations_organization" "root_account" {}

# Retrieve information about the modernisation platform account
data "aws_caller_identity" "modernisation_platform" {
  provider = aws.modernisation-platform
}

# caller account information to instantiate aws.oidc provider
data "aws_caller_identity" "original_session" {
  provider = aws.original-session
}

data "aws_iam_session_context" "whoami" {
  provider = aws.original-session
  arn      = data.aws_caller_identity.original_session.arn
}

# Get the environments file from the main repository
data "http" "environments_file" {
  url = "https://raw.githubusercontent.com/ministryofjustice/modernisation-platform/main/environments/${local.application_name}.json"
}
