module "capita" {
  source = "./modules/landing_zone/"
  create_server = local.switch_on_server_capita && (local.is-production || local.is-development) ? 1 : 0

  supplier = "capita"

  user_accounts = [
    # Developer access.
    # local.sftp_account_dev,

    # Test account for supplier.
    # local.sftp_account_capita_test,

    # Accounts for each system to be migrated.
    # local.sftp_account_capita_alcohol_monitoring,
    # local.sftp_account_capita_blob_storage,
    # local.sftp_account_capita_forms_and_subject_id,
  ]

  data_store_bucket = aws_s3_bucket.data_store

  account_id = data.aws_caller_identity.current.account_id

  vpc_id     = data.aws_vpc.shared.id
  subnet_ids = [data.aws_subnet.public_subnets_b.id]
}

module "civica" {
  source = "./modules/landing_zone/"
  create_server = local.switch_on_server_civica && (local.is-production || local.is-development) ? 1 : 0

  supplier = "civica"

  user_accounts = [
    # Developer access.
    # local.sftp_account_dev,

    # Test account for supplier.
    # local.sftp_account_civica_test,

    # Accounts for each system to be migrated.
    # local.sftp_account_civica_orca,
  ]

  data_store_bucket = aws_s3_bucket.data_store

  account_id = data.aws_caller_identity.current.account_id

  vpc_id     = data.aws_vpc.shared.id
  subnet_ids = [data.aws_subnet.public_subnets_b.id]
}

module "g4s" {
  source = "./modules/landing_zone/"
  create_server = local.switch_on_server_g4s && (local.is-production || local.is-development) ? 1 : 0

  supplier = "g4s"

  user_accounts = [
    # Developer access.
    local.sftp_account_dev,

    # Test account for supplier.
    local.sftp_account_g4s_test,

    # Accounts for each system to be migrated.
    local.sftp_account_g4s_atrium,
    local.sftp_account_g4s_cap_dw,
    # local.sftp_account_g4s_integrity,
    # local.sftp_account_g4s_telephony,
    # local.sftp_account_g4s_fep,
    # local.sftp_account_g4s_tasking,
    # local.sftp_account_g4s_subject_history,
    # local.sftp_account_g4s_atv,
    # local.sftp_account_g4s_emsys_mvp,
    # local.sftp_account_g4s_emsys_tpims,
  ]

  data_store_bucket = aws_s3_bucket.data_store

  account_id = data.aws_caller_identity.current.account_id

  vpc_id     = data.aws_vpc.shared.id
  subnet_ids = [data.aws_subnet.public_subnets_b.id]
}
