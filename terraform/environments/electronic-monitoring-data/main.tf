#module "capita" {
#  source = "./modules/landing_zone/"
#
#  supplier = "capita"
#
#  user_accounts = [
#    # Developer access.
#    # local.sftp_account_dev,
#
#    # Accounts for each system to be migrated.
#    # local.sftp_account_capita_specials_mailbox,
#    # local.sftp_account_capita_alcohol_monitoring,
#    # local.sftp_account_capita_blob_storage,
#    # local.sftp_account_capita_forms_and_subject_id,
#
#    # Test account for supplier.
#    # local.sftp_account_capita_test,
#  ]
#
#  data_store_bucket = aws_s3_bucket.data_store
#
#  account_id = data.aws_caller_identity.current.account_id
#
#  vpc_id     = data.aws_vpc.shared.id
#  subnet_ids = [data.aws_subnet.public_subnets_b.id]
#
#  local_tags = local.tags
#}

#module "civica" {
#  source = "./modules/landing_zone/"
#
#  supplier = "civica"
#
#  user_accounts = [
#    # Developer access.
#    # local.sftp_account_dev,
#
#    # Test account for supplier.
#    # local.sftp_account_civica_test,
#
#    # Accounts for each system to be migrated.
#    # local.sftp_account_civica_orca,
#  ]
#
#  data_store_bucket = aws_s3_bucket.data_store
#
#  account_id = data.aws_caller_identity.current.account_id
#
#  vpc_id     = data.aws_vpc.shared.id
#  subnet_ids = [data.aws_subnet.public_subnets_b.id]
#
#  local_tags = local.tags
#}

module "g4s" {
  source = "./modules/landing_zone/"

  supplier = "g4s"

  user_accounts = [
    # Developer access.
    # local.sftp_account_dev,

    # Test account for supplier.
    # local.sftp_account_g4s_test,

    # Accounts for each system to be migrated.
    # local.sftp_account_g4s_atrium,
    local.sftp_account_g4s_atrium_unstructured,
    # local.sftp_account_g4s_cap_dw,
    # local.sftp_account_g4s_integrity,
    # local.sftp_account_g4s_telephony,
    # local.sftp_account_g4s_fep,
    # local.sftp_account_g4s_tasking,
    # local.sftp_account_g4s_subject_history,
    # local.sftp_account_g4s_atv,
    # local.sftp_account_g4s_emsys_mvp,
    # local.sftp_account_g4s_emsys_tpims,
    local.sftp_account_g4s_x_drive,
  ]

  data_store_bucket = aws_s3_bucket.data_store

  account_id = data.aws_caller_identity.current.account_id

  vpc_id     = data.aws_vpc.shared.id
  subnet_ids = [data.aws_subnet.public_subnets_b.id]

  local_tags = local.tags
}

data "aws_caller_identity" "current_acct_id" {}

output "account_id" {
  value = data.aws_caller_identity.current.account_id
}

output "account_suffix" {
  value = local.is-production ? "production" : "development"
}