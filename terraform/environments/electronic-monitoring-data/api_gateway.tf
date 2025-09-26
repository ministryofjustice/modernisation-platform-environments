module "get_zipped_file_api_api" {
  source          = "./modules/api_step_function"
  api_name        = "get_zipped_file_api"
  api_description = "API to trigger step function that gets a zipped file out of storage"
  api_path        = "execute"
  step_function   = module.get_zipped_file_api
  stages = [
    {
      stage_name             = "test",
      stage_description      = "API Stage for testing",
      burst_limit            = 200,
      rate_limit             = 2000,
      throttling_burst_limit = 200,
      throttling_rate_limit  = 2000

    }
  ]
  schema = {
    type = "object"
    properties = {
      file_name     = { type = "string" }
      zip_file_name = { type = "string" }
    }
    required = ["file_name", "zip_file_name"]
  }
  api_version = "0.1.1"
}

# ------------------------------
# allow de to trigger api
# ------------------------------

data "aws_iam_policy_document" "trigger_api" {
  statement {
    effect    = "Allow"
    actions   = ["execute-api:Invoke"]
    resources = ["arn:aws:execute-api:${data.aws_region.current.name}:${local.env_account_id}:${module.get_zipped_file_api_api.api_gateway_id}/*"]
  }
}

resource "aws_iam_policy" "trigger_step_function_api" {
  name   = "trigger_step_function_api_policy"
  policy = data.aws_iam_policy_document.trigger_api.json
}

resource "aws_iam_role_policy_attachment" "trigger_step_function_api_de" {
  role       = try(one(data.aws_iam_roles.mod_plat_roles.arns))
  policy_arn = aws_iam_policy.trigger_step_function_api.arn

}
