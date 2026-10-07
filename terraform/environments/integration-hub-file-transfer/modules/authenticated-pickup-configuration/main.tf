variable "environment" { type = string }

module "transfer_identity" {
  source = "../transfer-web-app-identity-configuration"
}

locals {
  # Add only approved prefix-to-group mappings. Webhooks live in Secrets Manager.
  # Group names refer to the existing Transfer web app assignment catalogue.
  recipients_by_environment = {
    development   = {}
    test          = {}
    preproduction = {}
    production    = {}
  }
}

output "recipients" {
  value = local.recipients_by_environment[var.environment]
  precondition {
    condition = alltrue([for id, recipient in local.recipients_by_environment[var.environment] :
      can(regex("^[a-z0-9]+(-[a-z0-9]+)*$", id)) &&
      can(regex("^[^/*?]+(/[^*?]*)?/$", recipient.prefix)) &&
      length(recipient.groups) > 0 &&
      alltrue([for group in recipient.groups : contains(keys(module.transfer_identity.groups), group)])
    ])
    error_message = "Recipients require a safe ID, a literal non-root clean prefix ending in /, and explicitly assigned Transfer web app groups."
  }
}

output "assigned_groups" {
  value = module.transfer_identity.groups
}
