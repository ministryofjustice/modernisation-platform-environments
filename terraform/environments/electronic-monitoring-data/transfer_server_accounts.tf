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
