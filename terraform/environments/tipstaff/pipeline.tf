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
        Region           = "eu-west-1"
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
        Region              = "eu-west-1"
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

# resource "aws_iam_role" "codepipeline_role" {
#   name = "codepipeline-role"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = "sts:AssumeRole"
#         Effect = "Allow"
#         Principal = {
#           Service = "codepipeline.amazonaws.com"
#         }
#       },
#       {
#         Action = "sts:AssumeRole"
#         Effect = "Allow"
#         Principal = {
#           Service = "codebuild.amazonaws.com"
#         }
#       }
#     ]
#   })
# }

data "aws_iam_policy_document" "assume_role" {
  effect = "Allow"

  principals {
    type        = "Service"
    identifiers = ["ec2.amazonaws.com"]
  }

  actions = ["sts:AssumeRole"]
}

resource "aws_iam_role" "codepipeline_role" {
  name               = "codepipeline_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "codepipeline_policy" {
  statement {
    effect = "Allow"
    actions = [
      "ec2:DescribeInstances",
      "ec2:StartInstances",
      "ec2:StopInstances",
      "codepipeline:*"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "policy" {
  name        = "codepipeline-policy"
  description = "A test policy for codepipeline"
  policy      = data.aws_iam_policy_document.codepipeline_policy.json

  role = aws_iam_role.codepipeline_role.name
}

# resource "aws_iam_role_policy_attachment" "s3_policy_attachment" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
#   role       = aws_iam_role.example_codepipeline_role.name
# }

# resource "aws_iam_role_policy" "codepipeline_policy" {
#   name   = "codepipeline_policy"
#   role   = aws_iam_role.codepipeline_role.id
#   policy = data.aws_iam_policy_document.codepipeline_policy.json
# }

# data "aws_kms_alias" "s3kmskey" {
#   name = "alias/myKmsKey"
# }