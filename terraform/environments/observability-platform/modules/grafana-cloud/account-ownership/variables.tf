variable "accounts" {
  description = "Already-onboarded AWS account names."
  type        = set(string)
}

variable "modernisation_platform_account_names" {
  description = "Account names listed in the Modernisation Platform account inventory."
  type        = set(string)
}

variable "nonmp_account_names" {
  description = "Account names managed outside the Modernisation Platform inventory."
  type        = set(string)
}

variable "enabled" {
  description = "Whether to resolve account ownership for this environment."
  type        = bool
}
