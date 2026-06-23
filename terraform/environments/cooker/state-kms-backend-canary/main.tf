# Temporary member-side state write canary for validating the real Modernisation Platform state bucket.
variable "canary_run_id" {
  description = "Workflow run identifier used to force a canary state write."
  type        = string
}

resource "terraform_data" "state_kms_backend_canary" {
  input = {
    canary_run_id = var.canary_run_id
    purpose       = "validate cooker can write Terraform state to the real Modernisation Platform state bucket"
    workspace     = terraform.workspace
  }
}
