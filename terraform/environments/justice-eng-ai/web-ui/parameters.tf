locals {
  forge_container_image_tag_parameter_name = "/modernisation-platform-ai-builder-core/forge/container-image-tag"
}

# The deploy workflow owns the live value (deploy-ecs.yml writes the tag it
# deployed); Terraform creates the parameter once with the variable as the
# bootstrap value and then reads it, so Terraform-registered Forge task
# definitions carry the deployed image and never regress it.
resource "aws_ssm_parameter" "forge_container_image_tag" {
  #checkov:skip=CKV_AWS_337:This is a non-sensitive image tag.
  #checkov:skip=CKV2_AWS_34:This is a non-sensitive image tag, so a SecureString/CMK is not warranted.
  count = local.forge_internal ? 1 : 0

  name  = local.forge_container_image_tag_parameter_name
  type  = "String"
  value = var.forge_container_image_tag
  tags  = local.tags

  lifecycle {
    ignore_changes = [value]
  }
}

data "aws_ssm_parameter" "forge_container_image_tag" {
  count = local.forge_internal ? 1 : 0

  name = local.forge_container_image_tag_parameter_name

  depends_on = [aws_ssm_parameter.forge_container_image_tag]
}

data "aws_iam_role" "modernisation_platform_oidc_cicd" {
  name = "modernisation-platform-oidc-cicd"
}

resource "aws_iam_role_policy" "web_ui_cicd" {
  count = local.forge_internal ? 1 : 0

  name = "web-ui-cicd"
  role = data.aws_iam_role.modernisation_platform_oidc_cicd.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ReadWriteForgeContainerImageTag"
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:PutParameter"
        ]
        Resource = aws_ssm_parameter.forge_container_image_tag[0].arn
      }
    ]
  })
}
