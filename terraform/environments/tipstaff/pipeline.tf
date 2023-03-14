# Define the GitHub repository information
data "github_repository" "my_repo" {
  full_name = "ministryofjustice/Tipstaff"
}

# Create CodePipeline
resource "aws_codepipeline" "codepipeline" {
  provider = aws.ireland_provider
  name     = "tf_tipstaff_pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.tipstaff_pipeline.bucket
    type     = "S3"
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
        Branch     = "master"
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
      }
    }
  }

  # stage {
  #   name = "Deploy"

  #   action {
  #     name            = "Deploy"
  #     category        = "Deploy"
  #     owner           = "AWS"
  #     provider        = "CodeDeployToEC2"
  #     input_artifacts = ["build_output"]
  #     version         = "1"

  #     configuration = {
  #       ApplicationName     = "my-dotnet-app"
  #       DeploymentGroupName = "my-dotnet-deployment-group"
  #     }
  #   }
  # }
}

# resource "aws_s3_bucket" "codepipeline_bucket" {
#   provider = aws.ireland_provider
#   bucket   = "tipstaff-pipeline-bucket"
# }

resource "aws_s3_bucket" "tipstaff_pipeline" {
  provider = aws.ireland_provider
  bucket   = "tipstaff_pipeline"
}

# resource "aws_s3_bucket_acl" "codepipeline_bucket_acl" {
#   bucket   = aws_s3_bucket.codepipeline_bucket.id
#   acl      = "private"
# }

// CodePipeline IAM Role & Policy

resource "aws_iam_role" "codepipeline_role" {
  provider = aws.ireland_provider
  name     = "CodePipelineRole"
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
  provider = aws.ireland_provider
  name     = "CodePipelinePolicy"
  role     = aws_iam_role.codepipeline_role.id
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
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

# Create CodeBuild project
resource "aws_codebuild_project" "my_build_project" {
  provider     = aws.ireland_provider
  name         = "my-dotnet-build-project"
  description  = "Build .NET application"
  service_role = aws_iam_role.codebuild_role.arn
  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_MEDIUM"
    image                       = "mcr.microsoft.com/dotnet/framework/sdk:4.8"
    type                        = "WINDOWS_SERVER_2019_CONTAINER"
    image_pull_credentials_type = "SERVICE_ROLE"
  }

  source {
    type = "CODEPIPELINE"
  }

  source_version = "master"
}

// CodeBuild IAM Role & Policy

resource "aws_iam_role" "codebuild_role" {
  provider = aws.ireland_provider
  name     = "CodeBuildRole"
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
  provider = aws.ireland_provider
  name     = "CodeBuildPolicy"
  role     = aws_iam_role.codebuild_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "codebuild:*",
          "iam:*",
          "logs:*",
          "s3:*"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}