#### This file can be used to store locals specific to the member account ####

locals {
  ses_iam_user    = local.application_data.accounts[local.environment].ses_iam_user
  ses_secret_name = local.application_data.accounts[local.environment].ses_secret_name
}
