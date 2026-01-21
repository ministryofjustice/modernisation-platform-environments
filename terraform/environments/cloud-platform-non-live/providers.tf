# Providers to assume cross-account role in each environment account
# These are only used when running from production workspace

provider "aws" {
  alias  = "cloud-platform-non-live-development"
  region = "eu-west-2"
  assume_role {
    role_arn = terraform.workspace == "cloud-platform-non-live-production" ? "arn:aws:iam::${local.environment_management.account_ids["cloud-platform-non-live-development"]}:role/cross-account-hosted-zones-read" : null
  }
}

provider "aws" {
  alias  = "cloud-platform-non-live-test"
  region = "eu-west-2"
  assume_role {
    role_arn = terraform.workspace == "cloud-platform-non-live-production" ? "arn:aws:iam::${local.environment_management.account_ids["cloud-platform-non-live-test"]}:role/cross-account-hosted-zones-read" : null
  }
}

provider "aws" {
  alias  = "cloud-platform-non-live-preproduction"
  region = "eu-west-2"
  assume_role {
    role_arn = terraform.workspace == "cloud-platform-non-live-production" ? "arn:aws:iam::${local.environment_management.account_ids["cloud-platform-non-live-preproduction"]}:role/cross-account-hosted-zones-read" : null
  }
}