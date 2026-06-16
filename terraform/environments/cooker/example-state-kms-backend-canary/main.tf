# Temporary member-side state write canary for validating the real Modernisation Platform state bucket.
resource "terraform_data" "example_state_kms_backend_canary" {
  input = {
    purpose   = "validate cooker can write Terraform state to the real Modernisation Platform state bucket"
    workspace = terraform.workspace
  }
}
