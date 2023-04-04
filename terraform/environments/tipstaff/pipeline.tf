resource "aws_codepipeline" "codepipeline" {
  depends_on = [
    aws_codedeploy_app.tipstaff_codedeploy
  ]
  name     = "tf_tipstaff_pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.pipeline-s3-eu-west-2.bucket
    type     = "S3"
    region   = "eu-west-2"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        Owner      = "ministryofjustice"
        Repo       = "Tipstaff"
        Branch     = "dockerize"
        OAuthToken = jsondecode(data.aws_secretsmanager_secret_version.oauth_token.secret_string)["OAUTH_TOKEN"]
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"

      configuration = {
        ProjectName = "my-dotnet-build-project"
        EnvironmentVariables: [
          {
            name: "IMAGE_REPO_NAME"
            value: "${aws_ecr_repository.tipstaff-ecr-repo.name}"
          },
          {
            name: "IMAGE_TAG"
            value: "tipstaff-image-001"
          }
        ]
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeploy"
      input_artifacts = ["build_output"]
      version         = "1"
      region          = "eu-west-2"

      configuration = {
        ApplicationName     = "tipstaff-codedeploy"
        DeploymentGroupName = "tipstaff-deployment-group"
      }
    }
  }
}

resource "aws_s3_bucket" "pipeline-s3-eu-west-2" {
  bucket = "pipeline-s3-eu-west-2"
}

// CodePipeline IAM Role & Policy

resource "aws_iam_role" "codepipeline_role" {
  name = "CodePipelineRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codepipeline.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "codepipeline_role_policy" {
  name = "CodePipelinePolicy"
  role = aws_iam_role.codepipeline_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "codepipeline:*",
          "iam:*",
          "logs:*",
          "s3:*",
          "codedeploy:CreateDeployment",
          "codedeploy:GetApplication",
          "codedeploy:GetApplicationRevision",
          "codedeploy:GetDeployment",
          "codedeploy:GetDeploymentConfig",
          "codedeploy:RegisterApplicationRevision",
          "ec2:*",
          "codebuild:BatchGetBuilds",
          "codebuild:StartBuild",
          "codebuild:BatchGetBuildBatches",
          "codebuild:StartBuildBatch",
          "ecr:DescribeImages",
          "states:DescribeExecution",
          "states:DescribeStateMachine",
          "states:StartExecution",
          "appconfig:StartDeployment",
          "appconfig:StopDeployment",
          "appconfig:GetDeployment",
          "ecr:*",
          "ecs:*"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

# Create CodeBuild project
resource "aws_codebuild_project" "my_build_project" {
  name         = "my-dotnet-build-project"
  description  = "Builds and packages .NET application"
  service_role = aws_iam_role.codebuild_role.arn
  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_MEDIUM"
    image                       = "mcr.microsoft.com/dotnet/framework/sdk:4.8"
    type                        = "WINDOWS_CONTAINER"
    image_pull_credentials_type = "SERVICE_ROLE"
    environment_variables       = [
      {
        name  = "IMAGE_REPO_NAME"
        value = "<your-ECR-repository-name>"
      },
      {
        name  = "IMAGE_TAG"
        value = "<your-image-tag>"
      }
    ]
  }

  source {
    type = "CODEPIPELINE"
  }

  source_version = "master"
}

// CodeBuild IAM Role & Policy

resource "aws_iam_role" "codebuild_role" {
  name = "CodeBuildRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "codebuild_role_policy" {
  name = "CodeBuildPolicy"
  role = aws_iam_role.codebuild_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "codebuild:*",
          "iam:*",
          "logs:*",
          "s3:*",
          "ecr:*",
          "ecs:*"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

// Create CodeDeploy app and deployment group

resource "aws_codedeploy_app" "tipstaff_codedeploy" {
  name = "tipstaff-codedeploy"
}

resource "aws_codedeploy_deployment_group" "tipstaff_deployment_group" {
  depends_on = [
    aws_codedeploy_app.tipstaff_codedeploy
  ]
  app_name                = aws_codedeploy_app.tipstaff_codedeploy.name
  deployment_config_name  = "CodeDeployDefault.ECSAllAtOnce"
  deployment_group_name   = "tipstaff-deployment-group"
  service_role_arn        = aws_iam_role.codedeploy_role.arn

  auto_rollback_configuration {
    enabled = false
    events  = ["DEPLOYMENT_FAILURE"]
  }

  ecs_service {
    cluster_name = aws_ecs_cluster.tipstaff_cluster.name
    service_name = aws_ecs_service.tipstaff_ecs_service.name
  }

}

resource "aws_iam_role" "codedeploy_role" {
  name = "CodeDeployRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codedeploy.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "codedeploy_role_policy" {
  name = "CodeDeployPolicy"
  role = aws_iam_role.codedeploy_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "codedeploy:*",
          "iam:*",
          "logs:*",
          "s3:*",
          "ec2:*",
          "ecr:*",
          "ecs:*"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}