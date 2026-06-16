variable "modernisation_platform_organisation_unit_id" {
  description = "Modernisation Platform OU ID used to mirror the production state bucket KMS key policy."
  type        = string
}

variable "canary_writer_account_id" {
  description = "Member account ID allowed to write canary Terraform backend state into the example test bucket."
  type        = string
}
