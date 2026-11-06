locals {
  notify_state_machine_name = "${local.application_name}-notify"

  notify_builder_url = "https://${local.application_data.accounts[local.environment].builder_hostname}"

  notify_steps = [
    {
      name        = "send_notification"
      type        = "script_runner"
      script_path = "scripts/notification/send_notification.py"
      shell_type  = "python3"
      variables = [
        { name = "TEMPLATE_ID", value = local.application_data.accounts[local.environment].notify_template_id },
        { name = "USER_EMAIL", path = "$.latest.UserName" },
        { name = "CC_EMAIL", value = "ModernisationPlatform-gg@justice.gov.uk" },
        { name = "EMAIL_SUBJECT", value = "Your application has been built and deployed" },
        { name = "EMAIL_BODY_FILE", value = "scripts/notification/email-body.md" },
        {
          # Braces are escaped for States.Format; builder_url comes from Terraform.
          # The input is the deploy_prototype child's final state, passed on by the root.
          name = "EMAIL_VARS"
          path = "States.Format('\\{\"endpoint_url\":\"{}\",\"app_id\":\"{}\",\"build_id\":\"{}\",\"builder_url\":\"${local.notify_builder_url}\"\\}', $.dns.url, ${local.script_runner_app_id_path}, $.latest.BuildID)"
        },
      ]
      result_path     = "$.notify_task"
      timeout_seconds = 300
    },
    {
      # AWS Chatbot delivers the job completion topic to Slack.
      name        = "send_slack_alert"
      type        = "script_runner"
      script_path = "scripts/notification/send_slack_alert.py"
      shell_type  = "python3"
      variables = [
        { name = "TOPIC_ARN", value = aws_sns_topic.job_completion.arn },
        { name = "AWS_REGION", value = local.aws_region },
        { name = "USER_EMAIL", path = "$.latest.UserName" },
        { name = "APP_ID", path = local.script_runner_app_id_path },
        { name = "BUILD_ID", path = "$.latest.BuildID" },
        { name = "APP_URL", path = "$.dns.url" },
      ]
      result_path     = "$.slack_task"
      timeout_seconds = 300
    }
  ]
}

module "step_functions_notify" {
  source = "../modules/step_function_builder"

  step_function_retry_attempts = local.step_function_retry_attempts

  name               = local.notify_state_machine_name
  steps              = local.notify_steps
  execution_role_arn = aws_iam_role.step_functions_common.arn
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
