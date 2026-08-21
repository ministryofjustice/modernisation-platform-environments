locals {
  deploy_workspaces = try(local.application_data.accounts[local.environment].deploy_workspaces, false)
}
