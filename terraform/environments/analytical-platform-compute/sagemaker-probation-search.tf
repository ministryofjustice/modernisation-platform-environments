resource "aws_iam_role" "probation_search_sagemaker_invoke_role" {
  name = "probation-search-sagemaker-role"

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
          AWS = "arn:aws:iam::754256621582:role/hmpps-probation-search-dev-xa-opensearch-to-sagemaker"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "probation_search_sagemaker_invoke_policy" {
  role = aws_iam_role.probation_search_sagemaker_invoke_role.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action = [
          "sagemaker:InvokeEndpointAsync",
          "sagemaker:InvokeEndpoint"
        ]
        Resource = aws_sagemaker_endpoint.probation_search_endpoint.arn
      }
    ]
  })
}

resource "aws_iam_role" "probation_search_sagemaker_execution_role" {
  name = "probation-search-sagemaker-execution-role"

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

resource "aws_sagemaker_model" "probation_search_huggingface_embedding_model" {
  name               = "probation-search-sagemaker-hf-model"
  execution_role_arn = aws_iam_role.probation_search_sagemaker_execution_role.arn

  primary_container {
    image = "764974769150.dkr.ecr.eu-west-2.amazonaws.com/tei:2.0.1-tei1.2.3-gpu-py310-cu122-ubuntu22.04"
    environment = {
      HF_MODEL_ID = "mixedbread-ai/mxbai-embed-large-v1"
    }
  }
}

resource "aws_sagemaker_endpoint_configuration" "probation_search_config" {
  name = "probation-search-sagemaker-endpoint-config"
  production_variants {
    variant_name           = "AllTraffic"
    model_name             = aws_sagemaker_model.probation_search_huggingface_embedding_model.name
    initial_instance_count = 1
    instance_type          = "ml.g5.2xlarge"
  }
}

resource "aws_sagemaker_endpoint" "probation_search_endpoint" {
  name                 = "probation-search-sagemaker-endpoint"
  endpoint_config_name = aws_sagemaker_endpoint_configuration.probation_search_config.name
}

output "probation_search_sagemaker_endpoint_id" {
  value = aws_sagemaker_endpoint.probation_search_endpoint.id
}