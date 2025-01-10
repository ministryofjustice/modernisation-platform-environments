resource "aws_iam_role" "probation_search_sagemaker_invoke_role" {
  name = "probation-search-sagemaker-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "opensearch.amazonaws.com"
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = "754256621582"
          }
        }
      }
    ]
  })

  inline_policy {
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Resource = aws_sagemaker_endpoint.probation_search_endpoint.arn
          Action = [
            "sagemaker:InvokeEndpointAsync",
            "sagemaker:InvokeEndpoint"
          ]
        }
      ]
    })
  }
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