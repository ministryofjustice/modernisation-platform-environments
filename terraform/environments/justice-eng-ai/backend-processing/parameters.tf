locals {
  script_runner_container_image_tag_parameter_name = "/modernisation-platform-ai-builder-core/script-runner/container-image-tag"
}

resource "aws_ssm_parameter" "script_runner_container_image_tag" {
  #checkov:skip=CKV_AWS_337:This is a non-sensitive image tag.
  #checkov:skip=CKV2_AWS_34:This is a non-sensitive image tag, so a SecureString/CMK is not warranted.
  name  = local.script_runner_container_image_tag_parameter_name
  type  = "String"
  value = "script-runner-0000000000000000000000000000000000000000"
  tags  = local.tags

  lifecycle {
    ignore_changes = [value]
  }
}

data "aws_ssm_parameter" "script_runner_container_image_tag" {
  # The workflow owns the live value; Terraform creates the parameter once.
  name = local.script_runner_container_image_tag_parameter_name

  depends_on = [aws_ssm_parameter.script_runner_container_image_tag]
}

data "aws_iam_role" "modernisation_platform_oidc_cicd" {
  name = "modernisation-platform-oidc-cicd"
}

resource "aws_iam_role_policy" "script_runner_container_image_tag" {
  name = "script-runner-container-image-tag"
  role = data.aws_iam_role.modernisation_platform_oidc_cicd.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ReadWriteScriptRunnerContainerImageTag"
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:PutParameter"
        ]
        Resource = aws_ssm_parameter.script_runner_container_image_tag.arn
      },
      {
        Sid    = "RegisterScriptRunnerTaskDefinition"
        Effect = "Allow"
        Action = [
          "ecs:DescribeTaskDefinition",
          "ecs:RegisterTaskDefinition",
          "ecs:TagResource",
        ]
        Resource = "arn:${data.aws_partition.current.partition}:ecs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:task-definition/${local.script_runner_task_definition_family}:*"
      },
      {
        Sid      = "PassScriptRunnerTaskRoles"
        Effect   = "Allow"
        Action   = ["iam:PassRole"]
        Resource = [aws_iam_role.script_runner_ecs_execution.arn, aws_iam_role.script_runner_ecs_task.arn]
      }
    ]
  })
}
