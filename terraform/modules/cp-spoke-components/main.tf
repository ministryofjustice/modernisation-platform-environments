###############################################################################
# CP Spoke Components Module
#
# Installs platform components on a spoke EKS cluster:
# - OPA Gatekeeper (policy engine)
# - AWS Load Balancer Controller (self-managed, for Gateway API)
# - WAF Web ACL (OWASP baseline)
###############################################################################

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.0"
    }
  }
}

data "aws_caller_identity" "current" {}

###############################################################################
# OPA Gatekeeper
###############################################################################

module "gatekeeper" {
  source = "github.com/ministryofjustice/container-platform-terraform-gatekeeper?ref=1.0.0"

  dryrun_map = {
    service_type                       = false
    warn_service_account_secret_delete = false
    user_ns_requires_psa_label         = false
    lock_priv_capabilities             = false
    warn_kubectl_create_sa             = false
  }

  constraint_violations_max_to_display = 25
  is_production                        = var.is_production
  environment_name                     = var.environment_name
  out_of_hours_alert                   = "false"
  controller_mem_limit                 = "1Gi"
  controller_mem_req                   = "512Mi"
  audit_mem_limit                      = "1Gi"
  audit_mem_req                        = "512Mi"
}

###############################################################################
# AWS Load Balancer Controller — Gateway API support
###############################################################################

resource "aws_iam_role" "lbc" {
  name = "${var.cluster_name}-aws-lbc"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "pods.eks.amazonaws.com" }
      Action    = ["sts:AssumeRole", "sts:TagSession"]
    }]
  })

  tags = merge(var.tags, { Name = "${var.cluster_name}-aws-lbc" })
}

resource "aws_iam_policy" "lbc" {
  name        = "${var.cluster_name}-aws-lbc"
  description = "AWS Load Balancer Controller policy (official v3.3.0)"
  policy      = file("${path.module}/lbc-iam-policy.json")

  tags = merge(var.tags, { Name = "${var.cluster_name}-aws-lbc" })
}

resource "aws_iam_role_policy_attachment" "lbc" {
  role       = aws_iam_role.lbc.name
  policy_arn = aws_iam_policy.lbc.arn
}

resource "aws_eks_pod_identity_association" "lbc" {
  cluster_name    = var.cluster_name
  namespace       = "kube-system"
  service_account = "aws-load-balancer-controller"
  role_arn        = aws_iam_role.lbc.arn
}

resource "helm_release" "aws_lbc" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = "3.3.0"
  namespace  = "kube-system"

  set {
    name  = "clusterName"
    value = var.cluster_name
  }

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "leaderElection.id"
    value = "aws-lbc-gateway-api-leader"
  }

  set {
    name  = "region"
    value = "eu-west-2"
  }

  set {
    name  = "vpcId"
    value = var.vpc_id
  }

  depends_on = [
    aws_eks_pod_identity_association.lbc,
  ]
}

###############################################################################
# WAF Web ACL — OWASP Top 10 baseline + Logging
###############################################################################

resource "aws_kms_key" "waf_logs" {
  description             = "KMS key for WAF log group encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "EnableRootAccountAccess"
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" }
        Action    = "kms:*"
        Resource  = "*"
      },
      {
        Sid       = "AllowCloudWatchLogs"
        Effect    = "Allow"
        Principal = { Service = "logs.eu-west-2.amazonaws.com" }
        Action = [
          "kms:Encrypt*",
          "kms:Decrypt*",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:Describe*"
        ]
        Resource = "*"
        Condition = {
          ArnLike = {
            "kms:EncryptionContext:aws:logs:arn" = "arn:aws:logs:eu-west-2:${data.aws_caller_identity.current.account_id}:log-group:aws-waf-logs-${var.cluster_name}"
          }
        }
      }
    ]
  })

  tags = merge(var.tags, { Name = "${var.cluster_name}-waf-logs-key" })
}

resource "aws_kms_alias" "waf_logs" {
  name          = "alias/${var.cluster_name}-waf-logs"
  target_key_id = aws_kms_key.waf_logs.key_id
}

resource "aws_cloudwatch_log_group" "waf" {
  name              = "aws-waf-logs-${var.cluster_name}"
  retention_in_days = 365
  kms_key_id        = aws_kms_key.waf_logs.arn

  tags = merge(var.tags, { Name = "${var.cluster_name}-waf-logs" })
}

resource "aws_wafv2_web_acl" "ingress" {
  name        = "${var.cluster_name}-ingress-waf"
  description = "WAF for cluster ingress ALBs with OWASP Top 10"
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "aws-managed-rules-common"
    priority = 1
    override_action {
      none {}
    }
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "common-rules"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "aws-managed-rules-known-bad-inputs"
    priority = 2
    override_action {
      none {}
    }
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "known-bad-inputs"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.cluster_name}-ingress-waf"
    sampled_requests_enabled   = true
  }

  tags = merge(var.tags, { Name = "${var.cluster_name}-ingress-waf" })
}

resource "aws_wafv2_web_acl_logging_configuration" "ingress" {
  log_destination_configs = [aws_cloudwatch_log_group.waf.arn]
  resource_arn            = aws_wafv2_web_acl.ingress.arn
}
