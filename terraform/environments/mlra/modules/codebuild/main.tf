#############################################
# S3 Bucket for storing Selenium reports and other outputs
#############################################

resource "aws_s3_bucket" "selenium_report" {
  bucket = "laa-${var.app_name}-deployment-pipeline-pipelinereportbucket"
  # force_destroy = true # Enable to recreate bucket deleting everything inside
  tags = merge(
    var.tags,
    {
      Name = "laa-${var.app_name}-deployment-pipeline-pipelinereportbucket"
    },
  )
}

resource "aws_s3_bucket_server_side_encryption_configuration" "report_sse" {
  bucket = aws_s3_bucket.selenium_report.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "report_lifecycle" {
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
  bucket = aws_s3_bucket.selenium_report.id
  versioning_configuration {
    status = "Enabled"
  }
}

###################################################################
# KMS and S3 resources to have CodeBuild Artifacts if required
# Taken from https://github.com/ministryofjustice/laa-aws-infrastructure/blob/5d89457e67eca00e42406724cfd8380c156060cb/management/templates/LAA-Management-Pipeline-PreReqs.template
# If enabled make sure to add aws_s3_bucket.codebuild_artifactbucket to be accessible by the CodeBuild job in codebuild_iam_policy.json.tpl, and add in artifact section to CodeBuild resource
###################################################################

# data "template_file" "kms_policy" {
#   template = "${file("${path.module}/kms_policy.json.tpl")}"
#
#   vars = {
#     account_id = var.account_id
#   }
# }
#
# resource "aws_kms_key" "codebuild" {
#   description             = "For CodeBuild to access S3 artifacts"
#   enable_key_rotation     = true
#   policy                  = data.template_file.kms_policy.rendered
# }
#
# resource "aws_kms_alias" "codebuild_alias" {
#   name          = "alias/codebuild"
#   target_key_id = aws_kms_key.codebuild.key_id
# }
#
# resource "aws_s3_bucket" "codebuild_artifact" {
#   bucket = "${var.app_name}-selenium-artifact"
#   # force_destroy = true
# }
#
# resource "aws_s3_bucket_server_side_encryption_configuration" "codebuild_artifact" {
#   bucket = aws_s3_bucket.codebuild_artifact.id
#   rule {
#     apply_server_side_encryption_by_default {
#       sse_algorithm = "AES256"
#     }
#   }
# }
#
# data "template_file" "s3_art_bucket_policy" {
#   template = "${file("${path.module}/s3_bucket_policy.json.tpl")}"
#
#   vars = {
#     account_id = var.account_id,
#     s3_artifact_name = aws_s3_bucket.codebuild_artifact.id,
#     codebuild_role_name = aws_iam_role.codebuild_s3.id
#   }
# }
#
# resource "aws_s3_bucket_policy" "allow_access_from_codebuild_art" {
#   bucket = aws_s3_bucket.codebuild_artifact.id
#   policy = data.template_file.s3_art_bucket_policy.rendered
# }



######################################################
# CodeBuild projects
######################################################

resource "aws_iam_role" "codebuild_s3" {
  name               = "${var.app_name}-CodeBuildRole"
  assume_role_policy = file("${path.module}/codebuild_iam_role.json")
  tags = merge(
    var.tags,
    {
      Name = "${var.app_name}-CodeBuildRole"
    }
  )
}

data "template_file" "codebuild_policy" {
  template = file("${path.module}/codebuild_iam_policy.json.tpl")

  vars = {
    s3_report_bucket_name                      = aws_s3_bucket.selenium_report.id
    core_shared_services_production_account_id = var.core_shared_services_production_account_id
    application_name                           = var.app_name
  }
}

resource "aws_iam_role_policy" "codebuild_s3" {
  name   = "${var.app_name}-CodeBuildPolicy"
  role   = aws_iam_role.codebuild_s3.name
  policy = data.template_file.codebuild_policy.rendered
}


resource "aws_codebuild_project" "app-build" {
  name          = "${var.app_name}-app-build"
  description   = "Project to build the ${var.app_name} java application and xray docker images"
  build_timeout = 20
  # encryption_key = aws_kms_key.codebuild.arn
  service_role = aws_iam_role.codebuild_s3.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }
  # Comment above and uncomment below to use artifact
  # artifacts {
  #   type = "S3"
  #   location = aws_s3_bucket.codebuild_artifact.id
  # }

  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/docker:1.12.1"
    type            = "LINUX_CONTAINER"
    privileged_mode = true

    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = "eu-west-2"
    }

    environment_variable {
      name  = "REPOSITORY_URI"
      value = var.ecr_url
    }

    environment_variable {
      name  = "ARTIFACT_BUCKET"
      value = "selenium_report"
    }

    environment_variable {
      name  = "APPLICATION_NAME"
      value = "mlra"
    }

    environment_variable {
      name  = "REPORT_S3_BUCKET"
      value = "selenium_report"
    }

  }

  source {
    type      = "GITHUB"
    location  = "https://github.com/ministryofjustice/laa-mlra-application.git"
    buildspec = "buildspec-mp.yml"
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.app_name}-app-build"
    },
  )
}



resource "aws_codebuild_project" "selenium" {
  name          = "${var.app_name}-selenium-test"
  description   = "Project to test the Java application ${var.app_name}"
  build_timeout = 20
  # encryption_key = aws_kms_key.codebuild.arn
  service_role   = aws_iam_role.codebuild_s3.arn
  source_version = "LAWS-3074-gha"

  artifacts {
    type = "NO_ARTIFACTS"
  }
  # Comment above and uncomment below to use artifact
  # artifacts {
  #   type = "S3"
  #   location = aws_s3_bucket.codebuild_artifact.id
  # }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/python:2.7.12"
    type         = "LINUX_CONTAINER"

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
    type      = "GITHUB"
    location  = "https://github.com/ministryofjustice/laa-mlra-application.git"
    buildspec = "testspec-lz.yml"
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.app_name}-test"
    },
  )
}
