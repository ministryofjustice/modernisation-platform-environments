locals {
  account_name_pattern = "^([a-z0-9][a-z0-9-]*)-[a-z0-9]+$"
  account_definition_stems = {
    for account in var.accounts : account => regex(local.account_name_pattern, account)[0]
    if var.enabled && can(regex(local.account_name_pattern, account))
  }
  account_definitions = {
    for stem, definition in data.http.account_definition : stem => jsondecode(definition.response_body)
    if definition.status_code == 200
  }
  declared_account_names = {
    for stem, definition in local.account_definitions : stem => [
      for environment in definition.environments : "${stem}-${environment.name}"
    ]
  }
  account_applications = {
    for account, stem in local.account_definition_stems : account => try(local.account_definitions[stem].tags.application, null)
    if contains(lookup(local.declared_account_names, stem, []), account) && nonsensitive(
      contains(var.modernisation_platform_account_names, account) &&
      !contains(var.nonmp_account_names, account)
    )
  }
  team_by_account = {
    for account, application in local.account_applications : account => (
      application == "modernisation-platform" ? "modernisation-platform" :
      application == "cloud-platform" || try(startswith(application, "container-platform-"), false) ? "cloud-platform" : null
    )
  }
}

data "http" "account_definition" {
  for_each = toset(values(local.account_definition_stems))

  url = "https://raw.githubusercontent.com/ministryofjustice/modernisation-platform/main/environments/${each.key}.json"

  lifecycle {
    postcondition {
      condition     = contains([200, 404], self.status_code)
      error_message = "Could not read the Modernisation Platform account definition for ${each.key}."
    }
  }
}
