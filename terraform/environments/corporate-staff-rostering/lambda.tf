locals {
  lambda_ad_object_cleanup = {
    function_name = "AD-Object-Clean-Up"
  }
}

module "ad-clean-up-lambda" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-lambda-function" # ref for V3.1
  count  = local.environment == "test" ? 1 : 0 # temporary                                            # temporary whilst on-going work


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
      Name = "ad-object-clean-up-lambda"
    },
  )
}

data "archive_file" "ad-cleanup-lambda" {
  type             = "zip"
  source_dir       = "lambda/ad-clean-up"
  output_path      = "lambda/ad-clean-up/ad-clean-up-lambda-payload-test.zip"
}

