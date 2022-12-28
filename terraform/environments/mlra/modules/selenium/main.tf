resource "aws_s3_bucket" "selenium_report" {
  # count  = var.environment == "development" ? 1 : 0
  bucket = "laa-${var.app_name}-deployment-pipeline-pipelinereportbucket"

  tags = merge(
    var.tags,
    {
      Name = "laa-${var.app_name}-deployment-pipeline-pipelinereportbucket"
    },
  )
}

resource "aws_s3_bucket_server_side_encryption_configuration" "report_sse" {
  # count  = var.environment == "development" ? 1 : 0
  bucket = aws_s3_bucket.selenium_report.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "report_lifecycle" {
  # count  = var.environment == "development" ? 1 : 0
  bucket = aws_s3_bucket.selenium_report.id

  rule {
    id = "monthly-expiration"
    expiration {
      days = var.s3_lifecycle_expiration_days
    }
    noncurrent_version_expiration {
      noncurrent_days = var.s3_lifecycle_noncurr_version_expiration_days
    }

    status = "Enabled"
  }
}

resource "aws_s3_bucket_versioning" "report_versioning" {
  count  = var.environment == "development" ? 1 : 0
  bucket = aws_s3_bucket.selenium_report.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Selenium CodeBuild job lifting to MP directly

resource "aws_s3_bucket" "codebuild_artifact" {
  bucket = "${var.app_name}-selenium-artifact"
}

resource "aws_iam_role" "codebuild_s3" {
  name = "${var.app_name}-CodeBuildRole"
  assume_role_policy = file("${path.module}/codebuild_iam_role.json")
}

resource "aws_iam_role_policy" "codebuild_s3" {
  name = "${var.app_name}-CodeBuildPolicy"
  role = aws_iam_role.codebuild_s3.name
  policy = file("${path.module}/codebuild_iam_policy.json")
}

resource "aws_codebuild_project" "selenium" {
  name          = "${var.app_name}-selenium-test"
  description   = "Project to test the Java application ${var.app_name}"
  build_timeout = 20
  service_role  = aws_iam_role.codebuild_s3.arn

  artifacts {
    type = "S3"
    location = aws_s3_bucket.codebuild_artifact.id
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/python:2.7.12"
    type                        = "LINUX_CONTAINER"

    environment_variable {
      name  = "APP_URL"
      value = var.application_test_url
    }

    environment_variable {
      name  = "APPLICATION_NAME"
      value = var.app_name
    }

    environment_variable {
      name  = "REPORT_S3_BUCKET"
      value = aws_s3_bucket.selenium_report.id
    }
  }

  source {
    type            = "S3"
    # location        = "https://github.com/ministryofjustice/laa-mlra-application.git"
    buildspec       = "testspec-lz.yml"
    location        = "${aws_s3_bucket.codebuild_artifact.id}/source.zip"
  }

  # logs_config {
  #   cloudwatch_logs {
  #     status   = "DISABLED"
  #   }
  # }

  tags = merge(
    var.tags,
    {
      Name = "${var.app_name}-test"
    },
  )
}
