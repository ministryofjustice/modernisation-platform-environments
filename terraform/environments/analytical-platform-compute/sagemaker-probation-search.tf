# ------------------------------------------------------------------------------
# Cloud Platform namespace mapping
# ------------------------------------------------------------------------------
locals {
  probation_search_environments = {
    analytical-platform-compute-development = {
      hmpps-probation-search-dev = {
        namespace       = "hmpps-probation-search-dev"
        instance_type   = "ml.m6g.large"
        repository_name = "tei-cpu"
        image_tag       = "2.0.1-tei1.2.3-cpu-py310-ubuntu22.04"
        environment = {
          HF_MODEL_ID = "mixedbread-ai/mxbai-embed-large-v1"
        }
      }
    }
    analytical-platform-compute-production = {
      hmpps-probation-search-preprod = {
        namespace       = "hmpps-probation-search-preprod"
        instance_type   = "ml.m6g.large"
        repository_name = "tei-cpu"
        image_tag       = "2.0.1-tei1.2.3-cpu-py310-ubuntu22.04"
        environment = {
          HF_MODEL_ID = "mixedbread-ai/mxbai-embed-large-v1"
        }
      }
      hmpps-probation-search-prod = {
        namespace       = "hmpps-probation-search-prod"
        instance_type   = "ml.g6.xlarge"
        repository_name = "tei"
        image_tag       = "2.0.1-tei1.2.3-gpu-py310-cu122-ubuntu22.04"
        environment = {
          HF_MODEL_ID = "mixedbread-ai/mxbai-embed-large-v1"
        }
      }
    }
  }
  probation_search_environment = lookup(local.probation_search_environments, terraform.workspace, {})
}

# ------------------------------------------------------------------------------
# SageMaker
# ------------------------------------------------------------------------------
data "aws_sagemaker_prebuilt_ecr_image" "probation_search_huggingface_embedding_image" {
  for_each        = tomap(local.probation_search_environment)
  repository_name = each.value.repository_name
  image_tag       = each.value.image_tag
}

resource "aws_sagemaker_model" "probation_search_huggingface_embedding_model" {
  #checkov:skip=CKV_AWS_370:Network isolation must be disabled to enable us to pull the model from Huggingface
  for_each           = tomap(local.probation_search_environment)
  name               = "${each.value.namespace}-sagemaker-hf-model"
  execution_role_arn = aws_iam_role.probation_search_sagemaker_execution_role[each.key].arn
  primary_container {
    image       = data.aws_sagemaker_prebuilt_ecr_image.probation_search_huggingface_embedding_image[each.key].registry_path
    environment = each.value.environment
  }
}

resource "aws_sagemaker_endpoint_configuration" "probation_search_config" {
  #checkov:skip=CKV_AWS_98:KMS key is not supported for NVMe instance storage.
  for_each = tomap(local.probation_search_environment)
  name     = "${each.value.namespace}-sagemaker-endpoint-config"
  production_variants {
    variant_name           = "AllTraffic"
    model_name             = aws_sagemaker_model.probation_search_huggingface_embedding_model[each.key].name
    initial_instance_count = 1
    instance_type          = each.value.instance_type
  }
}

resource "aws_sagemaker_endpoint" "probation_search_endpoint" {
  for_each             = tomap(local.probation_search_environment)
  name                 = "${each.value.namespace}-sagemaker-endpoint"
  endpoint_config_name = aws_sagemaker_endpoint_configuration.probation_search_config[each.key].name
}


# ------------------------------------------------------------------------------
# IAM Permissions
# ------------------------------------------------------------------------------

resource "aws_iam_role" "probation_search_sagemaker_invoke_role" {
  for_each = tomap(local.probation_search_environment)
  name     = "${each.value.namespace}-sagemaker-role"

  ## Allow role in Account A (MOJ Cloud Platform account) to assume this role and invoke SageMaker in Account B (Analytical Platform Compute account on MOJ Modernisation Platform)
  ## See https://github.com/opensearch-project/ml-commons/blob/f741f71fff0d2ef6df7a3a62729cc1cb0953a37c/docs/tutorials/aws/semantic_search_with_bedrock_titan_embedding_model_in_another_account.md
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AssumeFromCloudPlatform"
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Principal = {
          AWS = "arn:aws:iam::754256621582:role/${each.value.namespace}-xa-opensearch-to-sagemaker"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "probation_search_sagemaker_invoke_policy" {
  for_each = tomap(local.probation_search_environment)
  role     = aws_iam_role.probation_search_sagemaker_invoke_role[each.key].name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sagemaker:InvokeEndpointAsync",
          "sagemaker:InvokeEndpoint"
        ]
        Resource = aws_sagemaker_endpoint.probation_search_endpoint[each.key].arn
      }
    ]
  })
}

resource "aws_iam_role" "probation_search_sagemaker_execution_role" {
  for_each = tomap(local.probation_search_environment)
  name     = "${each.value.namespace}-sagemaker-exec-policy"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "sagemaker.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "probation_search_sagemaker_logs_policy" {
  for_each = tomap(local.probation_search_environment)
  role     = aws_iam_role.probation_search_sagemaker_execution_role[each.key].id
  
  policy = jsonencode({
    Sid    = "LogsAccess"
    Effect = "Allow"
    Actions = [
      "cloudwatch:PutMetricData",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:CreateLogGroup",
      "logs:DescribeLogStreams",
    ]
    Resources = "*"
  })
}
