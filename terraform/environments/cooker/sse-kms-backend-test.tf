# Temporary state write canary for validating SSE-KMS backend init.
resource "terraform_data" "sse_kms_backend_test" {
  input = {
    purpose   = "validate Terraform state writes use the state bucket KMS key"
    workspace = terraform.workspace
  }
}
