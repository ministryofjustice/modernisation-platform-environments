# ------------------------------------------------------------------------------
# Landing-bucket supplier IAM user outputs
# ------------------------------------------------------------------------------

output "secret_arn" {
  description = (
    "Secrets Manager secret ARN for the supplier IAM user credentials"
  )

  value = module.secrets_manager.secret_arn
}