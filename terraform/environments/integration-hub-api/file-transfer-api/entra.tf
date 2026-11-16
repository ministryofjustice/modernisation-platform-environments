# No default tenant/application identities: an incomplete configuration must not deploy.
locals {
  entra_tenant_id           = try(local.application_configuration.entra.tenant_id, "")
  entra_api_audience        = try(local.application_configuration.entra.api_audience, "")
  entra_application_clients = try(local.application_configuration.entra.application_clients, {})
}

resource "terraform_data" "entra_configuration" {
  input = {
    tenant_id           = local.entra_tenant_id
    api_audience        = local.entra_api_audience
    application_clients = local.entra_application_clients
  }
  lifecycle {
    precondition {
      condition = alltrue([
        for id in [local.entra_tenant_id, local.entra_api_audience] :
        can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", id)) && id != "00000000-0000-0000-0000-000000000000"
      ])
      error_message = "Configure the approved Entra tenant_id and v2 API application ID as api_audience before deploying."
    }
    precondition {
      condition = length(local.entra_application_clients) > 0 && alltrue([
        for app_id, clients in local.entra_application_clients :
        can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", app_id)) &&
        app_id != local.entra_api_audience &&
        length(clients) > 0 && alltrue([
          for client in clients : contains(keys(local.transfer_clients), client) && client != "*"
        ])
      ])
      error_message = "Map distinct Entra consumer application IDs to explicit configured transfer client IDs. Wildcard grants are not supported."
    }
  }
}
