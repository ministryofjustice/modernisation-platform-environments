locals {
  script_runner_container_image_tag_parameter_name = "/modernisation-platform-ai-builder-core/script-runner/container-image-tag"
}

resource "aws_ssm_parameter" "script_runner_container_image_tag" {
  #checkov:skip=CKV_AWS_337:This is a non-sensitive git commit SHA image tag.
  #checkov:skip=CKV2_AWS_34:This is a non-sensitive git commit SHA image tag, so a SecureString/CMK is not warranted.
  name  = local.script_runner_container_image_tag_parameter_name
  type  = "String"
  value = "0000000000000000000000000000000000000000"
  tags  = local.tags

  lifecycle {
    ignore_changes = [value]
  }
}

data "aws_ssm_parameter" "script_runner_container_image_tag" {
  # Wait for initial creation, then read the live workflow-written value rather
  # than the managed resource's value, whose changes Terraform ignores.
  name = local.script_runner_container_image_tag_parameter_name

  depends_on = [
    aws_ssm_parameter.script_runner_container_image_tag
  ]
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
      }
    ]
  })
}
