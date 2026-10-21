# Offline plan-time unit tests. All providers are mocked, so no AWS credentials
# or network access are needed. Run against a specific Terraform version with:
#   terraform init -backend=false && terraform test
#
# These validate that the configuration (syntax, types, module wiring, provider
# schemas, locals and conditions) plans successfully under the Terraform
# version in use.

mock_provider "aws" {
  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Sid\":\"Mock\",\"Effect\":\"Allow\",\"Action\":\"sts:AssumeRole\",\"Resource\":\"*\"}]}"
    }
  }
  mock_data "aws_partition" {
    defaults = {
      partition          = "aws"
      dns_suffix         = "amazonaws.com"
      reverse_dns_prefix = "com.amazonaws"
    }
  }
  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "555555555555"
      arn        = "arn:aws:sts::555555555555:assumed-role/AdministratorAccess/test"
    }
  }
  mock_data "aws_iam_session_context" {
    defaults = {
      issuer_arn = "arn:aws:iam::555555555555:role/AdministratorAccess"
    }
  }
  mock_resource "aws_iam_role" {
    defaults = {
      arn = "arn:aws:iam::555555555555:role/mock"
    }
  }
  mock_resource "aws_iam_policy" {
    defaults = {
      arn = "arn:aws:iam::555555555555:policy/mock"
    }
  }
}
mock_provider "aws" {
  alias = "original-session"
}
mock_provider "aws" {
  alias = "modernisation-platform"
}
mock_provider "aws" {
  alias = "core-vpc"
}
mock_provider "aws" {
  alias = "us-east-1"
}
mock_provider "aws" {
  alias = "sso-readonly"
}
mock_provider "aws" {
  alias = "shared-configuration-access"
}
mock_provider "kubernetes" {}
mock_provider "helm" {}
mock_provider "null" {}
mock_provider "time" {}
mock_provider "tls" {}
mock_provider "dns" {}
mock_provider "external" {}
mock_provider "cloudinit" {}

mock_provider "http" {
  mock_data "http" {
    defaults = {
      response_body = "{\"tags\":{\"business-unit\":\"Platforms\",\"application\":\"cloud-platform\",\"owner\":\"test\"}}"
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
    secret_string = "{\"account_ids\":{\"cloud-platform-nonlive\":\"111111111111\",\"cloud-platform-live\":\"222222222222\",\"cloud-platform-development\":\"666666666666\"},\"aws_organizations_root_account_id\":\"333333333333\"}"
  }
}

override_data {
  target = data.aws_ssm_parameter.modernisation_platform_account_id
  values = {
    value = "444444444444"
  }
}

override_data {
  target = data.aws_caller_identity.original_session
  values = {
    account_id = "555555555555"
    arn        = "arn:aws:sts::555555555555:assumed-role/AdministratorAccess/test"
  }
}

override_data {
  target = data.aws_caller_identity.current
  values = {
    account_id = "555555555555"
    arn        = "arn:aws:sts::555555555555:assumed-role/AdministratorAccess/test"
  }
}

override_data {
  target = data.aws_iam_session_context.whoami
  values = {
    issuer_arn = "arn:aws:iam::555555555555:role/AdministratorAccess"
  }
}

override_data {
  target = data.aws_vpc.selected
  values = {
    id   = "vpc-12345678"
    tags = {}
  }
}

override_data {
  target = data.aws_subnets.private
  values = {
    ids = ["subnet-aaaaaaaa", "subnet-bbbbbbbb", "subnet-cccccccc"]
  }
}

override_data {
  target = data.aws_subnets.public
  values = {
    ids = ["subnet-dddddddd", "subnet-eeeeeeee", "subnet-ffffffff"]
  }
}

override_data {
  target = data.aws_iam_roles.platform_engineer_admin_sso_role
  values = {
    names = ["AWSReservedSSO_platform-engineer-admin_abcdef"]
  }
}

override_data {
  target = data.aws_ssoadmin_instances.this
  values = {
    arns               = ["arn:aws:sso:::instance/ssoins-0000000000000000"]
    identity_store_ids = ["d-0000000000"]
  }
}

override_data {
  target = data.aws_identitystore_groups.all
  values = {
    groups = [
      { display_name = "office-of-the-cto", group_id = "00000000-0000-0000-0000-000000000001" },
      { display_name = "laa", group_id = "00000000-0000-0000-0000-000000000002" },
      { display_name = "hmpps-developers", group_id = "00000000-0000-0000-0000-000000000003" },
      { display_name = "central-digital", group_id = "00000000-0000-0000-0000-000000000004" },
    ]
  }
}

override_data {
  target = data.aws_eks_cluster_auth.cluster
  values = {
    token = "mock-token"
  }
}

variables {
  networking = [
    {
      business-unit = ""
      set           = ""
      application   = "cloud-platform"
    }
  ]
  created_by = "unit-test"
}

run "plan_default_cluster" {
  command = plan

  assert {
    condition     = local.cluster_environment == "development_cluster"
    error_message = "A non-standard workspace should resolve to the development_cluster environment configuration."
  }

  assert {
    condition     = local.enable_argocd == false
    error_message = "Argo CD should be disabled by default on a non-hub cluster."
  }
}

run "plan_with_argocd_enabled" {
  command = plan

  variables {
    enable_argocd = true
  }

  assert {
    condition     = local.enable_argocd == true
    error_message = "enable_argocd should be honoured for ephemeral hub clusters."
  }
}

run "rejects_empty_created_by" {
  command = plan

  variables {
    created_by = "  "
  }

  expect_failures = [var.created_by]
}
