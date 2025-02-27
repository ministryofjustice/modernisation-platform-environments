resource "aws_athena_workgroup" "primary" {
  name = "primary"

  configuration {
    enforce_workgroup_configuration = false
    publish_cloudwatch_metrics_enabled = false

    result_configuration {
      output_location = "s3://manual-athena-test-ex"
    }
  }
}