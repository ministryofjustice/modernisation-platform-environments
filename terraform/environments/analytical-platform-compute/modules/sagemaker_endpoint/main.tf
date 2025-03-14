data "aws_sagemaker_prebuilt_ecr_image" "image" {
  repository_name = var.repository_name
  image_tag       = var.image_tag
}

resource "aws_sagemaker_model" "model" {
  execution_role_arn = module.sagemaker_execution_iam_role.iam_role_arn

  primary_container {
    image          = data.aws_sagemaker_prebuilt_ecr_image.image.registry_path
    environment    = var.environment
    model_data_url = var.s3_model_key != null ? "s3://${var.s3_model_bucket_name}/${var.s3_model_key}" : null
  }

  tags = merge(var.tags, {
    Name = "${var.name}-model"
  })
}

resource "aws_sagemaker_endpoint_configuration" "endpoint_config" {
  name_prefix = var.name

  production_variants {
    variant_name           = "AllTraffic"
    model_name             = aws_sagemaker_model.model.name
    initial_instance_count = 1
    instance_type          = var.instance_type
  }

  tags = var.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_sagemaker_endpoint" "endpoint" {
  name                 = var.name
  endpoint_config_name = aws_sagemaker_endpoint_configuration.endpoint_config.name
  tags                 = var.tags
}

module "sagemaker_execution_iam_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "5.54.0"

  create_role = true
  role_name   = "${var.name}-sagemaker-exec-role"

  trusted_role_services = ["sagemaker.amazonaws.com"]

  inline_policy_statements = [
    {
      sid    = "CloudWatchAccess"
      effect = "Allow"
      actions = [
        "cloudwatch:PutMetricData",
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:DescribeLogStreams",
        "logs:PutLogEvents"
      ]
      resources = ["*"]
    },
    {
      sid       = "S3Access"
      effect    = "Allow"
      actions   = ["s3:GetObject"]
      resources = ["arn:aws:s3:::${var.s3_model_bucket_name}/*"]
    }
  ]

  tags = var.tags
}
