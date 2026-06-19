locals {
  role_name = "data-platform-observability"
  
  # Trusted role ARNs - these will be the Cloud Platform IRSA roles for your Grafana pods
  # You'll need to update these with the actual role ARNs from your Cloud Platform namespaces
  trusted_role_arns = [
    # Development namespace IRSA role
    # Format: arn:aws:iam::754256621582:role/cloud-platform-irsa-<hash>-live
    # You can get this from: kubectl get serviceaccount -n data-platform-monitoring-development -o yaml
    # "arn:aws:iam::754256621582:role/cloud-platform-irsa-XXXXXXXX-live", 
    
    # Production namespace IRSA role (when created)
    # "arn:aws:iam::754256621582:role/cloud-platform-irsa-YYYYYYYY-live"
  ]
}

module "iam_role" {
  #checkov:skip=CKV_TF_1:Module is from Terraform registry
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "6.1.0"

  name            = local.role_name
  use_name_prefix = false

  trust_policy_permissions = {
    TrustedRoles = {
      actions = [
        "sts:AssumeRole",
        "sts:TagSession"
      ]
      principals = [{
        type        = "AWS"
        identifiers = local.trusted_role_arns
      }]
    }
  }

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "cloudwatch_read_only_access" {
  count = var.enable_cloudwatch_read_only_access ? 1 : 0

  role       = module.iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "amazon_prometheus_query_access" {
  count = var.enable_amazon_prometheus_query_access ? 1 : 0

  role       = module.iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonPrometheusQueryAccess"
}

resource "aws_iam_role_policy_attachment" "aws_xray_read_only_access" {
  count = var.enable_aws_xray_read_only_access ? 1 : 0

  role       = module.iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXrayReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "additional_policies" {
  for_each = { for k, v in var.additional_policies : k => v }

  role       = module.iam_role.name
  policy_arn = each.value
}
