# Define the GitHub repository information
data "github_repository" "my_repo" {
  full_name = "ministryofjustice/Tipstaff"
}

# Create CodePipeline
resource "aws_codepipeline" "codepipeline" {
  name     = "tf_tipstaff_pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.codepipeline_bucket.bucket
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
        FullRepositoryId = data.github_repository.my_repo.full_name
        BranchName       = "master"
        OAuthToken       = jsondecode(data.aws_secretsmanager_secret_version.oauth_token.secret_string)["OAUTH_TOKEN"]
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
        Region      = "eu-west-1"
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeployToEC2"
      input_artifacts = ["build_output"]
      version         = "1"

      configuration = {
        ApplicationName     = "my-dotnet-app"
        DeploymentGroupName = "my-dotnet-deployment-group"
      }
    }
  }
}

# Create CodeBuild project
resource "aws_codebuild_project" "my_build_project" {
  provider     = aws.ireland_provider
  name         = "my-dotnet-build-project"
  description  = "Build .NET application"
  service_role = "arn:aws:iam::${data.aws_caller_identity.original_session.id}:role/MemberInfrastructureAccess"
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
    type            = "GITHUB"
    location        = "https://github.com/ministryofjustice/Tipstaff.git"
    git_clone_depth = 1
  }

  source_version = "master"
}

resource "aws_s3_bucket" "codepipeline_bucket" {
  bucket = "tipstaff-pipeline-bucket"
}

resource "aws_s3_bucket_acl" "codepipeline_bucket_acl" {
  bucket = aws_s3_bucket.codepipeline_bucket.id
  acl    = "private"
}

resource "aws_iam_role" "codepipeline_role" {
  name = "codepipeline_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "codepipeline.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_policy" "allow_ec2_policy" {
  name        = "codepipeline-policy"
  description = "A test policy for codepipeline"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:DescribeInstances",
          "ec2:StartInstances",
          "ec2:StopInstances",
          "codepipeline:*"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })

}

resource "aws_iam_role_policy_attachment" "codepipeline_policy_attachment" {
  policy_arn = aws_iam_policy.allow_ec2_policy.arn
  role       = aws_iam_role.codepipeline_role.name
}

// create CodeBuild role, create policy, and attach policy

resource "aws_iam_role" "codebuild_role" {
  name = "codebuild_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_policy" "allow_codebuild_policy" {
  name        = "allow_codebuild_policy"
  description = "A test policy for codebuild"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "codebuild:*"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })

}

resource "aws_iam_role_policy_attachment" "codebuild_policy_attachment" {
  policy_arn = aws_iam_policy.allow_codebuild_policy.arn
  role       = aws_iam_role.codebuild_role.name
}