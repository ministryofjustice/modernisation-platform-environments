# Policy document to allow write access to the raw_history, invalid_data buckets, read access to the validation_metadata bucket
# and read/delete access to the landing bucket
data "aws_iam_policy_document" "validation_lambda_function" {
  statement {
    actions = [
      "s3:PutObject",
      "s3:ListBucket"
    ]

    resources = [
      "${data.aws_s3_bucket.raw_history.arn}/*",
      "${aws_s3_bucket.invalid.arn}/*",
    ]
  }

  statement {
    actions = [
      "s3:ListBucket",
      "s3:GetObject"
    ]

    resources = [
      aws_s3_bucket.validation_metadata.arn,
      "${aws_s3_bucket.validation_metadata.arn}/*"
    ]
  }

  statement {
    actions = [
      "s3:GetObject",
      "s3:DeleteObject"
    ]

    resources = [
      aws_s3_bucket.landing.arn,
      "${aws_s3_bucket.landing.arn}/*"
    ]
  }
}

module "validation_lambda_function" {
  # Commit hash for v7.20.1
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-lambda?ref=84dfbfddf9483bc56afa0aff516177c03652f0c7"

  function_name           = "${var.db}-validation"
  description             = "Lambda to validate DMS data output"
  handler                 = "main.handler"
  runtime                 = "python3.12"
  timeout                 = 60
  architectures           = ["x86_64"]
  build_in_docker         = false
  store_on_s3             = true
  s3_bucket               = aws_s3_bucket.lambda.bucket
  s3_object_storage_class = "STANDARD"
  s3_prefix               = "validation/"

  attach_policy_json = true
  policy_json        = data.aws_iam_policy_document.validation_lambda_function.json

  environment_variables = {
    ENVIRONMENT         = var.environment
    PASS_BUCKET         = data.aws_s3_bucket.raw_history.bucket
    FAIL_BUCKET         = aws_s3_bucket.invalid.bucket
    METADATA_BUCKET     = aws_s3_bucket.validation_metadata.bucket
    METADATA_PATH       = ""
    SLACK_SECRET_KEY    = "" # TODO: Handle properly
    VALID_FILES_MUTABLE = var.valid_files_mutable
  }

  source_path = [{
    path             = "${path.module}/lambda-functions/validation/main.py"
    pip_requirements = "${path.module}/lambda-functions/validation/requirements.txt"
    # Exclude tests and dist-info directories from the deployment package
    patterns = [
      "!pyarrow/tests/?.*",
      "!numpy/tests/?.*",
      "!.*/.*dist-info/.*"
    ]
  }]

  tags = var.tags
}
