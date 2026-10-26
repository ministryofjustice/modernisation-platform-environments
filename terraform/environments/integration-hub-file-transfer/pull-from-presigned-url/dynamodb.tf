module "dynamodb_notifications" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source                             = "terraform-aws-modules/dynamodb-table/aws"
  version                            = "5.5.0"
  name                               = local.pattern_name
  hash_key                           = "id"
  attributes                         = [{ name = "id", type = "S" }]
  billing_mode                       = "PAY_PER_REQUEST"
  ttl_enabled                        = true
  ttl_attribute_name                 = "expiresAt"
  point_in_time_recovery_enabled     = true
  server_side_encryption_enabled     = true
  server_side_encryption_kms_key_arn = module.kms_notifications_pipeline.key_arn
  deletion_protection_enabled        = true
  tags                               = local.tags
}