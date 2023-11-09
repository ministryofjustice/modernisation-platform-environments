#############################################
# S3 Bucket for storing deployment, test reports and other outputs
#############################################

resource "aws_s3_bucket" "deployment_report" {
  bucket = "laa-${var.app_name}-deployment-pipeline-reportbucket"
  # force_destroy = true # Enable to recreate bucket deleting everything inside
  tags = merge(
    var.tags,
    {
      Name = "laa-${var.app_name}-deployment-pipeline-reportbucket"
    },
  )
}

resource "aws_s3_bucket_server_side_encryption_configuration" "report_sse" {
  bucket = aws_s3_bucket.deployment_report.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "report_lifecycle" {
  bucket = aws_s3_bucket.deployment_report.id

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
  bucket = aws_s3_bucket.deployment_report.id
  versioning_configuration {
    status = "Enabled"
  }
}

######################################################
# ECR Resources
######################################################

resource "aws_ecr_repository" "local-ecr" {
  name                 = "${var.app_name}-local-ecr"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.app_name}-local-ecr"
    },
  )
}

resource "aws_ecr_repository_policy" "local-ecr-policy" {
  repository = aws_ecr_repository.local-ecr.name
  policy     = data.aws_iam_policy_document.local-ecr-policy-data.json
}

data "aws_iam_policy_document" "local-ecr-policy-data" {
  statement {
    sid    = "AccessECR"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.account_id}:role/${var.app_name}-CodeBuildRole"]
    }

    actions = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
      "ecr:PutImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:DescribeRepositories",
      "ecr:GetRepositoryPolicy",
      "ecr:ListImages"
    ]
  }
}

######################################################
# S3 Resource Bucket for Codebuild
######################################################

resource "aws_s3_bucket" "codebuild_resources" {
  bucket = "laa-${var.app_name}-management-resourcebucket"
  # force_destroy = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "resources_sse" {
  bucket = aws_s3_bucket.codebuild_resources.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

data "template_file" "s3_resource_bucket_policy" {
  template = file("${path.module}/s3_bucket_policy.json.tpl")

  vars = {
    account_id          = var.account_id,
    s3_resource_name    = aws_s3_bucket.codebuild_resources.id,
    codebuild_role_name = aws_iam_role.codebuild_s3.id
  }
}

resource "aws_s3_bucket_policy" "allow_access_from_codebuild" {
  bucket = aws_s3_bucket.codebuild_resources.id
  policy = data.template_file.s3_resource_bucket_policy.rendered
}

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
    s3_report_bucket_name                      = aws_s3_bucket.deployment_report.id
    core_shared_services_production_account_id = var.core_shared_services_production_account_id
    account_id                                 = var.account_id
    app_name                                   = var.app_name
  }
}

resource "aws_iam_role_policy" "codebuild_s3" {
  name   = "${var.app_name}-CodeBuildPolicy"
  role   = aws_iam_role.codebuild_s3.name
  policy = data.template_file.codebuild_policy.rendered
}

resource "aws_codebuild_project" "app-build" {
  name          = "${var.app_name}-app-build"
  description   = "Project to build the ${var.app_name} Java application"
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
    compute_type    = "BUILD_GENERAL1_MEDIUM"
    image           = "aws/codebuild/docker:17.09.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = true

    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = "eu-west-2"
    }

    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = var.account_id
    }

    environment_variable {
      name  = "REPOSITORY_URI"
      value = var.local_ecr_url
    }

    environment_variable {
      name  = "ARTIFACT_BUCKET"
      value = "deployment_report"
    }

    environment_variable {
      name  = "APPLICATION_NAME"
      value = var.app_name
    }

    environment_variable {
      name  = "REPORT_S3_BUCKET"
      value = "deployment_report"
    }

  }

  source {
    type      = "GITHUB"
    location  = "https://github.com/ministryofjustice/laa-${var.app_name}.git"
    buildspec = "buildspec-mp.yml"
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.app_name}-app-build"
    },
  )
}

resource "aws_codebuild_project" "test-build" {
  name          = "${var.app_name}-test-build"
  description   = "Project to test the Java application ${var.app_name}"
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
    compute_type = "BUILD_GENERAL1_MEDIUM"
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
      value = aws_s3_bucket.deployment_report.id
    }
  }

  source {
    type      = "GITHUB"
    location  = "https://github.com/ministryofjustice/laa-${var.app_name}.git"
    buildspec = "testspec-lz.yml"
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.app_name}-test"
    },
  )
}