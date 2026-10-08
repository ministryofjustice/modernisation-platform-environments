resource "aws_athena_database" "alb_logs" {
  name   = "${var.env_name}_${var.app_name}_alb_logs"
  bucket = module.s3_bucket.bucket.id

  properties = {
    "classification" = "log"
  }
}

resource "aws_athena_workgroup" "lb_logs" {
  name = "${local.name}-lb-logs"

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true
    engine_version {
      selected_engine_version = "Athena engine version 3"
    }

    result_configuration {
      output_location = "s3://${module.s3_bucket.bucket.id}/output/"
      encryption_configuration {
        encryption_option = "SSE_S3"
      }
    }
  }

  tags = { Name = "${local.name}-lb-logs" }
}
