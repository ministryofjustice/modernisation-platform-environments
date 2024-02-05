module "capita" {
  source = "./modules/landing_zone/"

  supplier = "capita"

  user_accounts = [
    local.sftp_account_capita,
    local.sftp_account_dev,
  ]

  data_store_bucket = aws_s3_bucket.data_store

  account_id = data.aws_caller_identity.current.account_id

  vpc_id     = data.aws_vpc.shared.id
  subnet_ids = [data.aws_subnet.public_subnets_b.id]
}

module "civica" {
  source = "./modules/landing_zone/"

  supplier = "civica"

  user_accounts = [
    local.sftp_account_civica,
    local.sftp_account_dev,
  ]

  data_store_bucket = aws_s3_bucket.data_store

  account_id = data.aws_caller_identity.current.account_id

  vpc_id     = data.aws_vpc.shared.id
  subnet_ids = [data.aws_subnet.public_subnets_b.id]
}

module "g4s" {
  source = "./modules/landing_zone/"

  supplier = "g4s"

  user_accounts = [
    local.sftp_account_g4s,
    local.sftp_account_dev,
  ]

  data_store_bucket = aws_s3_bucket.data_store

  account_id = data.aws_caller_identity.current.account_id

  vpc_id     = data.aws_vpc.shared.id
  subnet_ids = [data.aws_subnet.public_subnets_b.id]
}
