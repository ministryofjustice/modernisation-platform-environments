module "xsiam" {

  source            = "./modules/xsiam"
  project_name      = local.project_name
  tags              = local.tags
  kms_key_arn       = module.kms.key_arn
  kms_key_id        = module.kms.key_id
  environment       = local.environment
  aws_account_id    = data.aws_caller_identity.current.account_id
  depends_on        = [aws_cloudwatch_log_group.userjourney_log_group]
  ds_log_group_name = module.ds.cloudwatch_log_group_name

}