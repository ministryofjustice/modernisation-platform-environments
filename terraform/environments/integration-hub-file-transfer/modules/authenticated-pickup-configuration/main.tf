variable "environment" { type = string }

locals {
  # Add only approved mappings. Prefixes are full clean-bucket prefixes ending in /.
  # Do not store webhook credentials here. See the component README for onboarding.
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
    condition     = length(local.recipients_by_environment[var.environment]) == 0
    error_message = "Activation blocked: the managed portal uses presigned downloads. Integrate and test an organisation-SSO streaming download endpoint before enabling recipients."
  }
  precondition {
    condition = alltrue([for id, recipient in local.recipients_by_environment[var.environment] :
      can(regex("^[a-z0-9]+(-[a-z0-9]+)*$", id)) &&
      can(regex("^[^/*?]+(/[^*?]*)?/$", recipient.prefix)) &&
      length(recipient.principals) > 0 &&
      alltrue([for principal in values(recipient.principals) :
        contains(["USER", "GROUP"], principal.type) && length(principal.id) > 0
      ])
    ])
    error_message = "Recipients need a safe ID, a non-root literal prefix ending in /, and explicit Identity Center users/groups."
  }
}
