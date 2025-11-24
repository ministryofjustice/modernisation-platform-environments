module "buddi" {
  source = "./modules/landing_zone/"
  count  = local.is-production ? 1 : 0

  supplier = "buddi"

  user_accounts = [
    # Developer access.
    local.sftp_account_dev,

    # Test account for supplier.
    local.sftp_account_buddi_test,

    # Accounts for each system to be migrated.
    local.sftp_account_buddi_live,
  ]

  data_store_bucket = module.s3-data-bucket.bucket

  account_id = data.aws_caller_identity.current.account_id

  vpc_id     = data.aws_vpc.shared.id
  subnet_ids = [data.aws_subnet.public_subnets_b.id]
  providers = {
    aws = aws
  }
  local_tags = local.tags
}

module "civica" {
  source = "./modules/landing_zone/"
  count  = local.is-production ? 1 : 0

  supplier = "civica"

  user_accounts = [
    # Developer access.
    local.sftp_account_dev,

    # Test account for supplier.
    # local.sftp_account_civica_test,

    # Accounts for each system to be migrated.
    local.sftp_account_civica_orca,
  ]

  data_store_bucket = module.s3-data-bucket.bucket

  account_id = data.aws_caller_identity.current.account_id

  vpc_id     = data.aws_vpc.shared.id
  subnet_ids = [data.aws_subnet.public_subnets_b.id]
  providers = {
    aws = aws
  }
  local_tags = local.tags
}

module "g4s" {
  source = "./modules/landing_zone/"
  count  = local.is-production ? 1 : 0

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
    local.sftp_account_g4s_telephony,
    local.sftp_account_g4s_fep,
    local.sftp_account_g4s_tasking,
    local.sftp_account_g4s_subject_history,
    local.sftp_account_g4s_atv,
    # local.sftp_account_g4s_emsys_mvp,
    local.sftp_account_g4s_emsys_tpims,
    # local.sftp_account_g4s_x_drive,
    local.sftp_account_g4s_lcm_archive,
    local.sftp_account_g4s_lcm,
    # local.sftp_account_g4s_gps,
    # local.sftp_account_g4s_centurion,
  ]

  data_store_bucket = module.s3-data-bucket.bucket

  account_id = data.aws_caller_identity.current.account_id

  vpc_id     = data.aws_vpc.shared.id
  subnet_ids = [data.aws_subnet.public_subnets_b.id]
  providers = {
    aws = aws
  }

  local_tags = local.tags

}
