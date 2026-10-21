# Run with the Terraform version being checked:
#   terraform init -backend=false && TF_WORKSPACE=cloud-platform-development terraform test
# Providers are mocked to keep plan-time validation independent of AWS and Kubernetes.

mock_provider "aws" {
  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":\"sts:AssumeRole\",\"Resource\":\"*\"}]}"
    }
  }
}
mock_provider "aws" { alias = "original-session" }
mock_provider "aws" { alias = "modernisation-platform" }
mock_provider "aws" { alias = "core-vpc" }
mock_provider "aws" { alias = "us-east-1" }
mock_provider "aws" { alias = "sso-readonly" }
mock_provider "aws" { alias = "shared-configuration-access" }
mock_provider "kubernetes" {}
mock_provider "helm" {}
mock_provider "kubectl" {}
mock_provider "dns" {}
mock_provider "external" {}
mock_provider "http" {
  mock_data "http" {
    defaults = {
      response_body = "{\"tags\":{}}"
    }
  }
}

override_data {
  target = data.terraform_remote_state.core_network_services
  values = {
    outputs = {}
  }
}

override_data {
  target = data.aws_secretsmanager_secret_version.environment_management
  values = {
    secret_string = "{\"account_ids\":{\"cloud-platform-development\":\"111111111111\",\"cloud-platform-nonlive\":\"222222222222\",\"cloud-platform-live\":\"333333333333\",\"core-network-services-production\":\"444444444444\",\"core-shared-services-production\":\"555555555555\",\"container-platform-octo-nonlive\":\"777777777777\",\"container-platform-octo-live\":\"777777777777\",\"container-platform-laa-nonlive\":\"777777777777\",\"container-platform-laa-live\":\"777777777777\",\"container-platform-hmpps-nonlive\":\"777777777777\",\"container-platform-hmpps-live\":\"777777777777\",\"container-platform-cd-nonlive\":\"777777777777\",\"container-platform-cd-live\":\"777777777777\"},\"aws_organizations_root_account_id\":\"666666666666\"}"
  }
}

override_data {
  target = data.aws_ssm_parameter.modernisation_platform_account_id
  values = {
    value = "777777777777"
  }
}

override_data {
  target = data.aws_caller_identity.original_session
  values = {
    account_id = "888888888888"
    arn        = "arn:aws:sts::888888888888:assumed-role/AdministratorAccess/test"
  }
}

override_data {
  target = data.aws_caller_identity.current
  values = {
    account_id = "888888888888"
    arn        = "arn:aws:sts::888888888888:assumed-role/AdministratorAccess/test"
  }
}

override_data {
  target = data.aws_caller_identity.modernisation_platform
  values = {
    account_id = "777777777777"
    arn        = "arn:aws:sts::777777777777:assumed-role/modernisation-account-limited-read-member-access/test"
  }
}

override_data {
  target = data.aws_iam_session_context.whoami
  values = {
    issuer_arn = "arn:aws:iam::888888888888:role/AdministratorAccess"
  }
}

override_data {
  target = data.aws_eks_cluster.cluster
  values = {
    compute_config = [{
      enabled       = true
      node_pools    = ["general-purpose"]
      node_role_arn = "arn:aws:iam::888888888888:role/cluster-node"
    }]
    endpoint = "https://mock.eks.amazonaws.com"
    certificate_authority = [{
      data = "Y2VydGlmaWNhdGU="
    }]
    tags = {}
  }
}

run "configuration_plans" {
  command = plan

  assert {
    condition     = local.cluster_environment == "development_cluster"
    error_message = "The development workspace should use development cluster configuration."
  }

  assert {
    condition     = local.node_role_name == "cluster-node"
    error_message = "The node role name should be derived from the EKS cluster configuration."
  }

  assert {
    condition     = length(local.bu_appprojects) == 8
    error_message = "All configured business-unit AppProjects should be generated."
  }
}
