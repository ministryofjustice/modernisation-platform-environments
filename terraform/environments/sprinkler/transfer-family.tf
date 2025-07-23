resource "awscc_transfer_web_app" "this" {
  identity_provider_details = {
    instance_arn = var.identity_provider_instance_arn
    role = var.identity_provider_role_arn
  }
}