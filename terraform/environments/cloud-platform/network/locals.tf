locals {
  bu_accounts = jsondecode(file("${path.module}/../accounts.json"))

  mp_environments = concat(
    [
      "cloud-platform-development",
      "cloud-platform-preproduction",
      "cloud-platform-live"
    ],
    local.bu_accounts.accounts
  )

  workspace_environment = element(reverse(split("-", terraform.workspace)), 0)
  cluster_environment   = contains(local.mp_environments, terraform.workspace) ? local.workspace_environment : "development_cluster"
  cp_vpc_name           = terraform.workspace

  vpc_cidr = {
    cloud-platform-development = {
      primary   = "10.195.32.0/20"
      secondary = "100.66.0.0/16"
    }
    cloud-platform-preproduction = {
      primary   = "10.195.16.0/20"
      secondary = "100.65.0.0/16"
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
  }

  vpc_flow_log_cloudwatch_log_group_name_prefix       = "/aws/vpc-flow-log/"
  vpc_flow_log_cloudwatch_log_group_name_suffix       = local.cp_vpc_name
  vpc_flow_log_cloudwatch_log_group_retention_in_days = 400
  vpc_flow_log_max_aggregation_interval               = 60

}
