locals {
  #if envinment is dev set to dev, prod set to prod, preprod set to preprod
  datadog_integration_external_id = {
    "production"    = "c915c3254375451ca61c8d37d8b195f7"
    "preproduction" = "4922b1f38e48496a87f8994c568d2155"
    "development"   = "a43e2b2de71041889dbb5d2cd8170356"
    "test"          = ""
  }
}

#create a log group for the user journey logs
resource "aws_cloudwatch_log_group" "userjourney_log_group" {
  name              = "yjaf-${local.environment}/user-journey"
  retention_in_days = 400
  kms_key_id        = module.kms.key_arn
  tags              = local.tags
}

module "datadog" {
  source                          = "./modules/datadog"
  project_name                    = local.project_name
  datadog_integration_external_id = local.datadog_integration_external_id[local.environment]
  tags                            = local.tags
  kms_key_arn                     = module.kms.key_arn
  kms_key_id                      = module.kms.key_id
  environment                     = local.environment
  aws_account_id                  = data.aws_caller_identity.current.account_id

  #ECS
  enable_datadog_agent_apm   = local.application_data.accounts[local.environment].enable_datadog_agent_apm
  ecs_cluster_arn            = module.ecs.ecs_cluster_arn
  ecs_subnet_ids             = local.private_subnet_list[*].id
  ecs_security_group_id      = module.ecs.ecs_service_internal_sg_id
  ecs_task_iam_role_name     = module.ecs.ecs_task_role_name
  ecs_task_iam_role_arn      = module.ecs.ecs_task_role_arn
  ecs_task_exec_iam_role_arn = module.ecs.ecs_task_execution_role_arn

  depends_on = [aws_cloudwatch_log_group.userjourney_log_group]
}
