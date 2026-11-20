# GitHub OIDC role used by laa-mlra-application "Manage MLRA ASG" workflow to scale the MLRA EC2 ASG.
# The OIDC provider is created by MP bootstrapping, we only need to create the role.

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

locals {
  application_name = var.app_name
  tags             = var.tags_common
  environment      = var.environment
}

module "github_actions_asg_oidc_role" {
  source              = "github.com/ministryofjustice/modernisation-platform-github-oidc-role?ref=b40748ec162b446f8f8d282f767a85b6501fd192" # v4.0.0
  github_repositories = ["ministryofjustice/laa-mlra-application"]
  subject_claim       = "repo:ministryofjustice/laa-mlra-application:environment:${local.environment}"
  role_name           = "${local.application_name}-asg-manage-oidc"
  policy_arns         = []
  policy_jsons        = [data.aws_iam_policy_document.github_actions_asg_oidc_policy.json]
  tags                = merge({ "Name" = "${local.application_name}-asg-manage-oidc" }, local.tags)
}

data "aws_iam_policy_document" "github_actions_asg_oidc_policy" {
  # The shutdown flow must drain the ECS service before the ASG can safely shrink; the
  # AL2023 autoscaling group and ECS capacity provider both enforce instance protection.
  statement {
    sid       = "UpdateMlraAsg"
    effect    = "Allow"
    actions   = ["autoscaling:UpdateAutoScalingGroup"]
    resources = ["arn:aws:autoscaling:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:autoScalingGroup:*:autoScalingGroupName/${local.application_name}-ec2-*"]
  }

  statement {
    sid       = "ReleaseMlraAsgProtection"
    effect    = "Allow"
    actions   = ["autoscaling:SetInstanceProtection"]
    resources = ["arn:aws:autoscaling:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:autoScalingGroup:*:autoScalingGroupName/${local.application_name}-ec2-*"]
  }

  statement {
    sid     = "ManageMlraEcsService"
    effect  = "Allow"
    actions = ["ecs:DescribeClusters", "ecs:DescribeServices", "ecs:UpdateService"]
    resources = [
      "arn:aws:ecs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:cluster/${local.application_name}",
      "arn:aws:ecs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:service/${local.application_name}/*"
    ]
  }

  # Describe actions do not support resource-level permissions
  statement {
    sid       = "DescribeAsg"
    effect    = "Allow"
    actions   = ["autoscaling:DescribeAutoScalingGroups"]
    resources = ["*"]
  }
}
