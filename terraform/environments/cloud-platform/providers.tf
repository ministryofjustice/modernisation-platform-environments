# commented out as we dont currently have permission to attach policies to the github-actions role
# Providers to assume cross-account role in each environment account
# These are only used when running from production workspace
# provider "aws" {
#   alias  = "cloud-platform-development"
#   region = "eu-west-2"
#   assume_role {
#     role_arn = terraform.workspace == "cloud-platform-live" ? "arn:aws:iam::${local.environment_management.account_ids["cloud-platform-development"]}:role/cross-account-hosted-zones-read" : null
#   }
# }

# provider "aws" {
#   alias  = "cloud-platform-non-live-test"
#   region = "eu-west-2"
#   assume_role {
#     role_arn = terraform.workspace == "cloud-platform-non-live-production" ? "arn:aws:iam::${local.environment_management.account_ids["cloud-platform-non-live-test"]}:role/cross-account-hosted-zones-read" : null
#   }
# }

# provider "aws" {
#   alias  = "cloud-platform-preproduction"
#   region = "eu-west-2"
#   assume_role {
#     role_arn = terraform.workspace == "cloud-platform-live" ? "arn:aws:iam::${local.environment_management.account_ids["cloud-platform-preproduction"]}:role/cross-account-hosted-zones-read" : null
#   }
# }
