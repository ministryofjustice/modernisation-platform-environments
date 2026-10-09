locals {
  build_image_state_machine_name = "${local.application_name}-build-app-image"

  core_shared_services_account_id = local.environment_management.account_ids["core-shared-services-production"]
  aws_region                      = data.aws_region.current.region
  aws_dns_suffix                  = data.aws_partition.current.dns_suffix

  ecr_repository_uri                    = "${local.core_shared_services_account_id}.dkr.ecr.${local.aws_region}.${local.aws_dns_suffix}/${local.application_data.accounts[local.environment].ecr_repository_name}"
  forge_runtime_base_ecr_repository_uri = "${local.core_shared_services_account_id}.dkr.ecr.${local.aws_region}.${local.aws_dns_suffix}/${local.application_data.accounts[local.environment].forge_runtime_base_ecr_repository_name}"

  build_image_steps = [
    {
      name        = "build_prototype_image"
      type        = "script_runner"
      script_path = "scripts/prototype-image-build/build-prototype-image.py"
      shell_type  = "python3"
      variables = [
        { name = "S3_BUCKET", value = aws_s3_bucket.staging_bucket.id },
        { name = "S3_FOLDER", path = "$.s3_folder" },
        { name = "S3_FILE", path = "$.s3_file" },
        { name = "ECR_REPOSITORY_URI", value = local.ecr_repository_uri },
        { name = "IMAGE_TAG", path = "States.ArrayGetItem(States.StringSplit($.s3_file, '.'), 0)" },
        { name = "AWS_REGION", value = local.aws_region },
        { name = "FORGE_RUNTIME_BASE_ECR_REPOSITORY_URI", value = local.forge_runtime_base_ecr_repository_uri },
      ]
      result_path     = "$.image_build_task"
      timeout_seconds = 3600
    }
  ]
}

module "step_functions_build_image" {
  source = "../modules/step_function_builder"

  name               = local.build_image_state_machine_name
  steps              = local.build_image_steps
  execution_role_arn = aws_iam_role.step_functions_common.arn
  script_runner = {
    cluster_arn            = aws_ecs_cluster.script_runner.arn
    task_definition_family = local.script_runner_task_definition_family
    container_name         = "script-runner"
    subnets                = data.terraform_remote_state.justice_eng_ai.outputs.private_subnet_ids
    security_groups        = [aws_security_group.script_runner_task.id]
    assign_public_ip       = "DISABLED"
    execution_role_arn     = aws_iam_role.script_runner_ecs_execution.arn
    task_role_arn          = aws_iam_role.script_runner_ecs_task.arn
  }
  tags = local.tags

  depends_on = [
    aws_ecs_task_definition.script_runner,
    aws_iam_role_policy.step_functions_common,
    aws_iam_role_policy_attachment.script_runner_ecs_task,
    aws_iam_role_policy_attachment.script_runner_ecs_execution,
  ]
}
