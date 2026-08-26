/**
 * ## Usage
 *
 * Creates an AWS Athena workgroup that encrypts results server-side.
 *
*/

resource "aws_athena_workgroup" "main" {
  count = var.setup_athena_workgroup ? 1 : 0

  name        = var.name
  description = length(var.description) > 0 ? var.description : format("The workgroup for %s.", var.name)
  state       = var.state_enabled ? "ENABLED" : "DISABLED"

  configuration {
    bytes_scanned_cutoff_per_query     = var.bytes_scanned_cutoff_per_query > 0 ? var.bytes_scanned_cutoff_per_query : null
    enforce_workgroup_configuration    = var.enforce_workgroup_configuration
    publish_cloudwatch_metrics_enabled = var.publish_cloudwatch_metrics_enabled

    result_configuration {
      output_location = var.output_location

      encryption_configuration {
        encryption_option = var.encryption_option
        kms_key_arn       = length(var.kms_key_arn) > 0 ? var.kms_key_arn : null
      }
    }
  }

  tags = var.tags
}