locals {
  bu_accounts = jsondecode(file("${path.module}/../accounts.json"))

  mp_environments = concat(
    [
      "cloud-platform-development",
      "cloud-platform-preproduction",
      "cloud-platform-nonlive",
      "cloud-platform-live"
    ],
    local.bu_accounts.accounts
  )

  workspace_environment = element(reverse(split("-", terraform.workspace)), 0)
  cluster_environment   = contains(local.mp_environments, terraform.workspace) ? local.workspace_environment : "development_cluster"
  cp_vpc_name           = terraform.workspace

  ## private_endpoint_mode: true = private-only cluster API, plus the SSM relay
  ## for engineer access. Set per VPC because the relay lives in this component.
  ## Published as a tag on the VPC (vpc.tf) and read by the cluster component,
  ## so both settings always come from this one value.
  ## BU spoke VPCs are not listed and default to false until opted in.
  private_endpoint_mode = lookup({
    cloud-platform-development   = false
    cloud-platform-preproduction = false
    cloud-platform-nonlive       = false
    cloud-platform-live          = false
  }, local.cp_vpc_name, false)

  vpc_cidr = {
    cloud-platform-development = {
      primary   = "10.195.32.0/20"
      secondary = "100.66.0.0/16"
    }
    cloud-platform-preproduction = {
      primary   = "10.195.16.0/20"
      secondary = "100.65.0.0/16"
    }
    cloud-platform-nonlive = {
      primary   = "10.195.192.0/20"
      secondary = "100.67.0.0/16"
    }
    cloud-platform-live = {
      primary   = "10.195.0.0/20"
      secondary = "100.64.0.0/16"
    }
    container-platform-octo-nonlive = {
      primary   = "10.195.48.0/20"
      secondary = "100.68.0.0/16"
    }
    container-platform-octo-live = {
      primary   = "10.41.0.0/20"
      secondary = "100.80.0.0/16"
    }
    container-platform-laa-nonlive = {
      primary   = "10.195.80.0/20"
      secondary = "100.70.0.0/16"
    }
    container-platform-laa-live = {
      primary   = "10.41.32.0/20"
      secondary = "100.82.0.0/16"
    }
    container-platform-hmpps-nonlive = {
      primary   = "10.195.64.0/20"
      secondary = "100.69.0.0/16"
    }
    container-platform-hmpps-live = {
      primary   = "10.41.16.0/20"
      secondary = "100.81.0.0/16"
    }
    container-platform-cd-nonlive = {
      primary   = "10.195.96.0/20"
      secondary = "100.71.0.0/16"
    }
    container-platform-cd-live = {
      primary   = "10.41.48.0/20"
      secondary = "100.83.0.0/16"
    }
  }

  vpc_flow_log_cloudwatch_log_group_name_prefix       = "/aws/vpc-flow-log/"
  vpc_flow_log_cloudwatch_log_group_name_suffix       = local.cp_vpc_name
  vpc_flow_log_cloudwatch_log_group_retention_in_days = 400
  vpc_flow_log_max_aggregation_interval               = 60

  vpc_gateway_endpoint_service_names = [
    "s3",      # S3
    "dynamodb" # DynamoDB
  ]

}
