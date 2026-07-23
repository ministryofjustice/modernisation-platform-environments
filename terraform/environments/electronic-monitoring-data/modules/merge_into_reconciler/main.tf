module "merge_into_this" {
  source       = "../step_function"
  name         = "merge_into_${local.name}"
  iam_policies = tomap({ "merge_into_${local.name}_step_function_policy" = aws_iam_policy.merge_into_this })
  variable_dictionary = tomap(
    {
      "merge_function_name" = var.function_to_iterate.lambda_function_arn,
      "table_name"          = local.camel_name 
    }
  )
  type = "STANDARD"
}

data "aws_iam_policy_document" "merge_into_this" {
  statement {
    effect    = "Allow"
    actions   = ["lambda:InvokeFunction"]
    resources = [var.function_to_iterate.lambda_function_arn,]
  }
}

resource "aws_iam_policy" "merge_into_this" {
  name   = "insert_into_${local.name}"
  policy = data.aws_iam_policy_document.merge_into_this.json
}
