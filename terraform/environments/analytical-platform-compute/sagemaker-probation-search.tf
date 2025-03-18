# ------------------------------------------------------------------------------
# Cloud Platform namespace mapping
# ------------------------------------------------------------------------------
locals {
  probation_search_model_bucket_name = "mojap-data-production-sagemaker-ai-probation-search-models"
  probation_search_model_kms_arn     = "arn:aws:kms:eu-west-2:${local.environment_management.account_ids["analytical-platform-data-production"]}:key/55286d64-9b9d-4473-8750-0546f583f19e"
  probation_search_environments = {
    analytical-platform-compute-development = {
      hmpps-probation-search-dev = {
        namespace       = "hmpps-probation-search-dev"                    # MOJ Cloud Platform namespace where OpenSearch is hosted
        instance_type   = "ml.t2.large"                                   # SageMaker AI Real-time Inference instance type to use
        repository_name = "tei-cpu"                                       # "tei" for GPU-accelerated instances, "tei-cpu" for CPU-only instances
        image_tag       = "2.0.1-tei1.2.3-cpu-py310-ubuntu22.04"          # Version of the Hugging Face Text Embeddings Inference image to use. See https://huggingface.co/docs/text-embeddings-inference.
        s3_model_key    = "ext/mixedbread-ai/mxbai-embed-large-v1.tar.gz" # To use a local model from S3
        environment = {                                                   # Environment variables to be passed to the Hugging Face Text Embeddings Inference image. See https://huggingface.co/docs/text-embeddings-inference/cli_arguments.
          #HF_MODEL_ID           = "mixedbread-ai/mxbai-embed-large-v1"    # To use a remote model from Hugging Face Hub (takes precedence over s3_model_key above, if present)
          MAX_CLIENT_BATCH_SIZE = 512
        }
      }
    }
    analytical-platform-compute-production = {
      hmpps-probation-search-preprod = {
        namespace       = "hmpps-probation-search-preprod"
        instance_type   = "ml.t2.large"
        repository_name = "tei-cpu"
        image_tag       = "2.0.1-tei1.2.3-cpu-py310-ubuntu22.04"
        environment = {
          HF_MODEL_ID           = "mixedbread-ai/mxbai-embed-large-v1"
          MAX_CLIENT_BATCH_SIZE = 512
        }
      }
      hmpps-probation-search-prod = {
        namespace       = "hmpps-probation-search-prod"
        instance_type   = "ml.g6.xlarge"
        repository_name = "tei"
        image_tag       = "2.0.1-tei1.2.3-gpu-py310-cu122-ubuntu22.04"
        environment = {
          HF_MODEL_ID           = "mixedbread-ai/mxbai-embed-large-v1"
          MAX_CLIENT_BATCH_SIZE = 512
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
  for_each = tomap(local.probation_search_environment)

  repository_name = each.value.repository_name
  image_tag       = each.value.image_tag
}

resource "aws_sagemaker_model" "probation_search_huggingface_embedding_model" {
  #checkov:skip=CKV_AWS_370:Network isolation must be disabled to enable us to pull the model from Huggingface

  for_each = tomap(local.probation_search_environment)

  execution_role_arn = module.probation_search_sagemaker_execution_iam_role[each.key].iam_role_arn

  primary_container {
    image          = data.aws_sagemaker_prebuilt_ecr_image.probation_search_huggingface_embedding_image[each.key].registry_path
    environment    = each.value.environment
    model_data_url = can(each.value.s3_model_key) ? "s3://${local.probation_search_model_bucket_name}/${each.value.s3_model_key}" : null
  }

  tags = merge(local.tags, {
    Name = "${each.value.namespace}-huggingface-embedding-model"
  })
}

resource "aws_sagemaker_endpoint_configuration" "probation_search" {
  #checkov:skip=CKV_AWS_98:KMS key is not supported for NVMe instance storage

  for_each = tomap(local.probation_search_environment)

  name_prefix = each.value.namespace

  production_variants {
    variant_name           = "AllTraffic"
    model_name             = aws_sagemaker_model.probation_search_huggingface_embedding_model[each.key].name
    initial_instance_count = 1
    instance_type          = each.value.instance_type
  }

  tags = local.tags

  lifecycle {
    replace_triggered_by  = [aws_sagemaker_model.probation_search_huggingface_embedding_model[each.key]]
    create_before_destroy = true
  }
}

resource "aws_sagemaker_endpoint" "probation_search" {
  for_each = tomap(local.probation_search_environment)

  name                 = each.value.namespace
  endpoint_config_name = aws_sagemaker_endpoint_configuration.probation_search[each.key].name

  tags = local.tags
}

# ------------------------------------------------------------------------------
# IAM Permissions
# ------------------------------------------------------------------------------

module "probation_search_sagemaker_execution_iam_role" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  for_each = tomap(local.probation_search_environment)

  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "5.54.0"

  create_role = true

  role_name         = "${each.value.namespace}-sagemaker-exec-role"
  role_requires_mfa = false

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
        "logs:PutLogEvents",
      ]
      resources = ["*"]
    },
    {
      sid    = "KMSAccess"
      effect = "Allow"
      actions = [
        "kms:Decrypt",
        "kms:GenerateDataKey"
      ]
      resources = [local.probation_search_model_kms_arn]
    },
    {
      sid       = "S3BucketAccess"
      effect    = "Allow"
      actions   = ["s3:ListBucket"]
      resources = ["arn:aws:s3:::${local.probation_search_model_bucket_name}"]
    },
    {
      sid       = "S3ObjectAccess"
      effect    = "Allow"
      actions   = ["s3:GetObject"]
      resources = ["arn:aws:s3:::${local.probation_search_model_bucket_name}/*"]
    }
  ]

  tags = local.tags
}

module "probation_search_sagemaker_invocation_iam_role" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  for_each = tomap(local.probation_search_environment)

  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "5.54.0"

  create_role = true

  role_name         = "${each.value.namespace}-sagemaker-role"
  role_requires_mfa = false

  trusted_role_arns = ["arn:aws:iam::754256621582:role/${each.value.namespace}-xa-opensearch-to-sagemaker"]

  inline_policy_statements = [
    {
      sid    = "SageMakerAccess"
      effect = "Allow"
      actions = [
        "sagemaker:InvokeEndpoint",
        "sagemaker:InvokeEndpointAsync",
      ]
      resources = [aws_sagemaker_endpoint.probation_search[each.key].arn]
    }
  ]

  tags = local.tags
}
