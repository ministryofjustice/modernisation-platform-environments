locals {
  prototype_deployment_enabled = local.is-development || local.is-production
  prototype_deployment = local.prototype_deployment_enabled ? {
    cluster_arn            = data.aws_ecs_cluster.prototype_deployment[0].arn
    vpc_id                 = data.aws_vpc.vpc.id
    private_subnet_ids     = data.aws_subnets.private.ids
    ecs_security_group_id  = data.aws_security_group.prototype_deployment[0].id
    load_balancer_arn      = data.aws_lb.prototype_deployment[0].arn
    listener_arn           = data.aws_lb_listener.prototype_deployment[0].arn
    hosted_zone_id         = data.aws_route53_zone.prototype_deployment[0].zone_id
    domain_name            = local.is-production ? "ai-builder.modernisation-platform.service.justice.gov.uk" : "ai-builder-dev.modernisation-platform.service.justice.gov.uk"
    load_balancer_dns_name = data.aws_lb.prototype_deployment[0].dns_name
    } : {
    cluster_arn            = ""
    vpc_id                 = ""
    private_subnet_ids     = []
    ecs_security_group_id  = ""
    load_balancer_arn      = ""
    listener_arn           = ""
    hosted_zone_id         = ""
    domain_name            = ""
    load_balancer_dns_name = ""
  }
  prototype_deployment_state_machine_name = "${local.application_name}-deploy-prototype"
  prototype_deployment_variables = [
    { name = "IMAGE_URI", path = "States.Format('{}:{}-{}', '${aws_ecr_repository.user_applications.repository_url}', $.package_identity.AppID, $.package_identity.BuildID)" },
    { name = "REQUEST_ID", path = "$.package_identity.AppID" },
    { name = "BASE_PATH", path = "$.image_build_task.index_html_path" },
    { name = "AWS_REGION", value = data.aws_region.current.region },
    { name = "TASK_EXECUTION_ROLE_ARN", value = aws_iam_role.script_runner_ecs_execution.arn },
    { name = "TASK_ROLE_ARN", value = aws_iam_role.prototype_app_task.arn },
    { name = "ECS_CLUSTER_ARN", value = local.prototype_deployment.cluster_arn },
    { name = "VPC_ID", value = local.prototype_deployment.vpc_id },
    { name = "PRIVATE_SUBNET_IDS", value = jsonencode(local.prototype_deployment.private_subnet_ids) },
    { name = "ECS_SECURITY_GROUP_ID", value = local.prototype_deployment.ecs_security_group_id },
    { name = "LOAD_BALANCER_ARN", value = local.prototype_deployment.load_balancer_arn },
    { name = "LISTENER_ARN", value = local.prototype_deployment.listener_arn },
    { name = "HOSTED_ZONE_ID", value = local.prototype_deployment.hosted_zone_id },
    { name = "PROTOTYPE_DOMAIN", value = local.prototype_deployment.domain_name },
    { name = "CNAME_TARGET", value = local.prototype_deployment.load_balancer_dns_name },
  ]
  prototype_deployment_stage_inputs = {
    table           = []
    task_definition = []
    target_group    = []
    listener_rule   = [{ name = "TARGET_GROUP_ARN", path = "$.target_group.target_group_arn" }]
    service = [
      { name = "TARGET_GROUP_ARN", path = "$.target_group.target_group_arn" },
      { name = "TASK_DEFINITION_ARN", path = "$.task_definition.task_definition_arn" },
    ]
    dns = []
  }
  prototype_deployment_steps = [for stage in ["table", "task_definition", "target_group", "listener_rule", "service", "dns"] : {
    name        = "deploy_${stage}"
    type        = "script_runner"
    script_path = "scripts/deployment/prototype_deployment.py"
    shell_type  = "python3"
    variables = concat(
      local.prototype_deployment_variables,
      [{ name = "DEPLOYMENT_STAGE", value = stage }],
      local.prototype_deployment_stage_inputs[stage],
    )
    result_path     = "$.${stage}"
    outputs         = true
    timeout_seconds = stage == "service" ? 1500 : 900
    retry = [{
      ErrorEquals     = ["States.TaskFailed"]
      IntervalSeconds = 15
      BackoffRate     = 2
      MaxAttempts     = local.step_function_retry_attempts
    }]
  }]
}

module "step_functions_deploy_prototype" {
  count  = local.prototype_deployment_enabled ? 1 : 0
  source = "../modules/step_function_builder"

  step_function_retry_attempts = local.step_function_retry_attempts
  name                         = local.prototype_deployment_state_machine_name
  steps                        = local.prototype_deployment_steps
  execution_role_arn           = aws_iam_role.step_functions_common.arn
  script_runner = {
    cluster_arn            = aws_ecs_cluster.script_runner.arn
    task_definition_family = local.script_runner_fargate_task_definition_family
    container_name         = "script-runner"
    subnets                = data.terraform_remote_state.justice_eng_ai.outputs.private_subnet_ids
    security_groups        = [aws_security_group.script_runner_task.id]
    assign_public_ip       = "DISABLED"
    execution_role_arn     = aws_iam_role.script_runner_ecs_execution.arn
    task_role_arn          = aws_iam_role.script_runner_ecs_task.arn
    launch_type            = "FARGATE"
  }
  tags = local.tags

  depends_on = [
    aws_iam_role_policy.step_functions_common,
    aws_iam_role_policy_attachment.script_runner_ecs_task,
    aws_iam_role_policy_attachment.script_runner_ecs_execution,
    aws_ecs_task_definition.script_runner_fargate,
  ]
}