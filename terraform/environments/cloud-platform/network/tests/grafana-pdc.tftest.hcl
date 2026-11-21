# Run in each network workspace with TF_WORKSPACE=<workspace> terraform test.
mock_provider "aws" {
  mock_data "aws_availability_zones" {
    defaults = {
      names = ["eu-west-2a", "eu-west-2b", "eu-west-2c"]
    }
  }

  mock_data "aws_vpc_endpoint_service" {
    defaults = {
      availability_zones = ["eu-west-2b", "eu-west-2c"]
    }
  }
}

mock_provider "aws" {
  alias = "original-session"

  mock_data "aws_caller_identity" {
    defaults = {
      arn = "arn:aws:iam::123456789012:user/test"
    }
  }
}

mock_provider "aws" {
  alias = "modernisation-platform"

  mock_data "aws_secretsmanager_secret_version" {
    defaults = {
      secret_string = "{}"
    }
  }
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

override_module {
  target = module.cluster_vpc
  outputs = {
    vpc_id                  = "vpc-0123456789abcdef0"
    name                    = "test-vpc"
    azs                     = ["eu-west-2a", "eu-west-2b", "eu-west-2c"]
    private_subnets         = ["subnet-aaaaaaaa", "subnet-bbbbbbbb", "subnet-cccccccc"]
    private_route_table_ids = ["rtb-aaaaaaaa", "rtb-bbbbbbbb", "rtb-cccccccc"]
  }
}

run "workspace_endpoints" {
  command = plan

  assert {
    condition = length(aws_vpc_endpoint.grafana_pdc) == (
      contains([
        "cloud-platform-development",
        "cloud-platform-preproduction",
        "cloud-platform-nonlive",
        "container-platform-cd-nonlive",
        "container-platform-hmpps-nonlive",
        "container-platform-laa-nonlive",
        "container-platform-octo-nonlive",
      ], terraform.workspace) ? 2 : 0
    )
    error_message = "Only the seven approved non-production VPCs may have PDC endpoints."
  }

  assert {
    condition = alltrue([
      for endpoint in aws_vpc_endpoint.grafana_pdc :
      endpoint.vpc_id == "vpc-0123456789abcdef0" &&
      endpoint.vpc_endpoint_type == "Interface" &&
      endpoint.private_dns_enabled &&
      endpoint.subnet_ids == toset(["subnet-bbbbbbbb", "subnet-cccccccc"]) &&
      length(endpoint.security_group_ids) == 1
    ])
    error_message = "PDC endpoints must have private DNS, a dedicated security group and only service-supported local private subnets."
  }

  assert {
    condition = (
      length(aws_security_group.grafana_pdc) == length(aws_vpc_endpoint.grafana_pdc) &&
      length(aws_vpc_security_group_ingress_rule.grafana_pdc) == 2 * length(aws_vpc_endpoint.grafana_pdc) &&
      alltrue([
        for key, rule in aws_vpc_security_group_ingress_rule.grafana_pdc :
        rule.ip_protocol == "tcp" &&
        rule.from_port == (startswith(key, "api-") ? 443 : 22) &&
        rule.to_port == rule.from_port &&
        rule.cidr_ipv4 == local.vpc_cidr[terraform.workspace][endswith(key, "-primary") ? "primary" : "secondary"]
      ])
    )
    error_message = "Allow only API HTTPS or gateway SSH from this VPC's primary and pod CIDRs; live must have no PDC security resources."
  }
}

run "single_supported_az" {
  command = plan

  override_data {
    target = data.aws_vpc_endpoint_service.grafana_pdc
    values = {
      availability_zones = ["eu-west-2a"]
    }
  }

  assert {
    condition = alltrue([
      for endpoint in aws_vpc_endpoint.grafana_pdc :
      endpoint.subnet_ids == toset(["subnet-aaaaaaaa"])
    ])
    error_message = "Each service's advertised AZs must determine placement, not an assumed pair of AZs."
  }
}
