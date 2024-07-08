locals {
  lambda_ad_object_cleanup = {
    function_name = "AD-Object-CleanUp"
  }
}

module "ad-clean-up-lambda" {
  # use latest commit hash because v3.1.0 tag download fails
  source = "github.com/ministryofjustice/modernisation-platform-terraform-lambda-function?ref=9d3d83f0b0938d7ee90eb579fe1d8e36a8ac1163"
  count  = local.environment == "development" ? 1 : 0                                      # temporary

  application_name = local.lambda_ad_object_cleanup.function_name
  function_name    = local.lambda_ad_object_cleanup.function_name
  description      = "Lambda to remove corresponding computer object from Active Directory upon server termination"
  package_type     = "Zip"
  filename         = data.archive_file.ad-cleanup-lambda.output_path
  source_code_hash = data.archive_file.ad-cleanup-lambda.output_base64sha256
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.8"

  create_role = false
  lambda_role = aws_iam_role.lambda-ad-role[count.index].arn

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
  type        = "zip"
  source_dir  = "lambda/ad-clean-up"
  output_path = "lambda/ad-clean-up/ad-clean-up-lambda-payload-test.zip"
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
  count = local.environment == "development" ? 1 : 0 # temporary
  name  = "LambdaFunctionADObjectCleanUp"
  tags  = local.tags

  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "lambda-vpc-attachment" {
  count      = local.environment == "development" ? 1 : 0 # temporary
  role       = aws_iam_role.lambda-ad-role[count.index].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_secrets_manager" {
  count      = local.environment == "development" ? 1 : 0 # temporary
  role       = aws_iam_role.lambda-ad-role[count.index].name
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
}
