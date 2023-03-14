provider "aws" {
  region = "eu-west-1"
  alias  = "ireland_provider"
  assume_role {
    role_arn = "arn:aws:iam::${local.modernisation_platform_account_id}:role/modernisation-account-limited-read-member-access"
  }
}
