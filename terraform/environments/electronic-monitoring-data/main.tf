module "capita" {
  source = "./modules/landing_zone/"

  supplier = "capita"

  give_access         = true
  supplier_shh_key    = "ecdsa-sha2-nistp384 AAAAE2VjZHNhLXNoYTItbmlzdHAzODQAAAAIbmlzdHAzODQAAABhBIhggGYKbOk6BH7fpEs6JGRnMyLRK/9/tAMQOVYOZtehKTRcM5vGsJFRGjjm2wEan3/uYOuto0NoVkbRfIi0AIG6EWrp1gvHNQlUTtxQVp7rFeOnZAjVEE9xVUEgHhMNLw=="
  supplier_cidr_ipv4s = [
    "82.203.33.112/28",
    "82.203.33.128/28",
    "85.115.52.0/24",
    "85.115.53.0/24",
    "85.115.54.0/24"
  ]

  data_store_bucket = aws_s3_bucket.data_store

  kms_key_id = data.aws_kms_key.general_shared.arn

  account_id = data.aws_caller_identity.current.account_id

  vpc_id     = data.aws_vpc.shared.id
  subnet_ids = [data.aws_subnet.public_subnets_b.id]

  give_dev_access = true
  dev_ssh_keys    = local.developer_ssh_keys
  dev_cidr_ipv4s  = local.developer_cidr_ipv4s
}

module "civica" {
  source = "./modules/landing_zone/"

  supplier = "civica"

  give_access         = false
  supplier_shh_key    = null
  supplier_cidr_ipv4s = [
  ]

  data_store_bucket = aws_s3_bucket.data_store

  kms_key_id = data.aws_kms_key.general_shared.arn

  account_id = data.aws_caller_identity.current.account_id

  vpc_id     = data.aws_vpc.shared.id
  subnet_ids = [data.aws_subnet.public_subnets_b.id]

  give_dev_access = true
  dev_ssh_keys    = local.developer_ssh_keys
  dev_cidr_ipv4s  = local.developer_cidr_ipv4s
}

module "g4s" {
  source = "./modules/landing_zone/"

  supplier = "g4s"

  give_access         = false
  supplier_shh_key    = null
  supplier_cidr_ipv4s = [
  ]

  data_store_bucket = aws_s3_bucket.data_store

  kms_key_id = data.aws_kms_key.general_shared.arn

  account_id = data.aws_caller_identity.current.account_id

  vpc_id     = data.aws_vpc.shared.id
  subnet_ids = [data.aws_subnet.public_subnets_b.id]

  give_dev_access = true
  dev_ssh_keys    = local.developer_ssh_keys
  dev_cidr_ipv4s  = local.developer_cidr_ipv4s
}
