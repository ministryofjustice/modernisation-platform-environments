#### This file can be used to store locals specific to the member account ####

locals {
  ses_iam_user    = try(local.application_data.accounts[local.environment].ses_iam_user, null)
  ses_secret_name = try(local.application_data.accounts[local.environment].ses_secret_name, null)
}
