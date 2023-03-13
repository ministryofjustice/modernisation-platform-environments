# Define the GitHub repository information
data "github_repository" "my_repo" {
  full_name = "ministryofjustice/Tipstaff"
}

# Create CodePipeline
resource "aws_codepipeline" "codepipeline" {
  name     = "tf_tipstaff_pipeline"
  role_arn = "arn:aws:iam::${data.aws_caller_identity.original_session.id}:role/MemberInfrastructureAccess"

  artifact_store {
    location = aws_s3_bucket.codepipeline_bucket.bucket
    type     = "S3"

    # encryption_key {
    #   id   = data.aws_kms_alias.s3kmskey.arn
    #   type = "KMS"
    # }
  }

  #   stage {
  #     name = "Source"

  #     action {
  #       name             = "Source"
  #       category         = "Source"
  #       owner            = "AWS"
  #       provider         = "CodeStarSourceConnection"
  #       version          = "1"
  #       output_artifacts = ["source_output"]

  #       configuration = {
  #         ConnectionArn    = aws_codestarconnections_connection.source-repo-connection.arn
  #         FullRepositoryId = "47194958"
  #         BranchName       = "master"
  #       }
  #     }
  #   }

  # Define the source stage with the GitHub repository
  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
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

# # CodeDeploy Application
# resource "aws_codedeploy_app" "my_dotnet_app" {
#   name             = "my-dotnet-app"
#   compute_platform = "Server"
# }

# # CodeDeploy Deployment Group
# resource "aws_codedeploy_deployment_group" "my_deployment_group" {
#   app_name              = aws_codedeploy_app.my_dotnet_app.name
#   deployment_group_name = "my-dotnet-deployment-group"
#   service_role_arn      = "arn:aws:iam::${data.aws_caller_identity.original_session.id}:role/MemberInfrastructureAccess"
# }

# resource "aws_codestarconnections_connection" "source-repo-connection" {
#   name          = "source-repo-connection"
#   provider_type = "GitHub"
# }

resource "aws_s3_bucket" "codepipeline_bucket" {
  bucket = "tipstaff-pipeline-bucket"
}

resource "aws_s3_bucket_acl" "codepipeline_bucket_acl" {
  bucket = aws_s3_bucket.codepipeline_bucket.id
  acl    = "private"
}

# data "aws_iam_policy_document" "assume_role" {
#   statement {
#     effect = "Allow"

#     principals {
#       type        = "Service"
#       identifiers = ["codepipeline.amazonaws.com"]
#     }

#     actions = ["sts:AssumeRole"]
#   }
# }

# resource "aws_iam_role" "codepipeline_role" {
#   name               = "test-role"
#   assume_role_policy = data.aws_iam_policy_document.assume_role.json
# }

# data "aws_iam_policy_document" "codepipeline_policy" {
#   statement {
#     effect = "Allow"

#     actions = [
#       "s3:GetObject",
#       "s3:GetObjectVersion",
#       "s3:GetBucketVersioning",
#       "s3:PutObjectAcl",
#       "s3:PutObject",
#     ]

#     resources = [
#       aws_s3_bucket.codepipeline_bucket.arn,
#       "${aws_s3_bucket.codepipeline_bucket.arn}/*"
#     ]
#   }

#   statement {
#     effect   = "Allow"
#     actions  = ["codestar-connections:UseConnection"]
#     resource = [aws_codestarconnections_connection.example.arn]
#   }

#   statement {
#     effect = "Allow"

#     actions = [
#       "codebuild:BatchGetBuilds",
#       "codebuild:StartBuild",
#     ]

#     resources = ["*"]
#   }
# }

# resource "aws_iam_role_policy" "codepipeline_policy" {
#   name   = "codepipeline_policy"
#   role   = aws_iam_role.codepipeline_role.id
#   policy = data.aws_iam_policy_document.codepipeline_policy.json
# }

# data "aws_kms_alias" "s3kmskey" {
#   name = "alias/myKmsKey"
# }