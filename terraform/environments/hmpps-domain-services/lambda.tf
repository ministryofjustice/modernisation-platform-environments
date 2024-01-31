locals {
    lambda_ad_object_cleanup = {
        function_name = "AD-Object-CleanUp"
    }
}

module "ad-clean-up-lambda" {
  source                 = "github.com/ministryofjustice/modernisation-platform-terraform-lambda-function" # ref for V3.1
  count                  = local.environment == "test" ? 1 : 0 # temporary whilst on-going work


  application_name       = local.lambda_ad_object_cleanup.function_name
  function_name          = local.lambda_ad_object_cleanup.function_name
  description            = "Lambda to remove corresponding computer object from Active Directory upon server termination"
  package_type           = "Zip"
  filename               = data.archive_file.ad-cleanup-lambda.output_path
  source_code_hash       = data.archive_file.ad-cleanup-lambda.output_base64sha256
  handler                = "lambda_function.lambda_handler"
  runtime                = "python3.8"

  create_role            = false
  lambda_role            = aws_iam_role.lambda-ad-role.arn

  vpc_subnet_ids         = tolist(data.aws_subnets.shared-private.ids)
  vpc_security_group_ids = [module.baseline.security_groups["domain"].id]

  tags = merge(
    local.tags,
    {
      Name = "ad-clean-up-lambda"
    },
  )
}

data "archive_file" "ad-cleanup-lambda" {
  count            = local.environment == "test" ? 1 : 0 # temporary whilst on-going work
  type             = "zip"
  source_dir       = "lambda/ad-clean-up"
  output_path      = "lambda/ad-cleanup/ad-cleanup-lambda-payload-test.zip"
}

data "aws_iam_policy_document" "lambda_assume_role_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda-ad-role" {
  count = local.environment == "test" ? 1 : 0 # temporary whilst on-going work  
  name  = "LambdaFunctionADObjectCleanUp"
  tags  = local.tags

  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "lambda-vpc-attachment" {
  count      = local.environment == "test" ? 1 : 0 # temporary whilst on-going work
  role       = aws_iam_role.lambda-ad-role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}
