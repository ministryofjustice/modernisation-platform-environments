# ------------------------------------------------------------------------------
# Cloud Platform namespace mapping
# ------------------------------------------------------------------------------
locals {
  probation_search_model_bucket_name = "mojap-probation-search-model-export"
  probation_search_environments = {
    analytical-platform-compute-development = {
      hmpps-probation-search-dev = {
        namespace       = "hmpps-probation-search-dev"                 # MOJ Cloud Platform namespace where OpenSearch is hosted
        instance_type   = "ml.t2.large"                                # SageMaker AI Real-time Inference instance type to use
        repository_name = "tei-cpu"                                    # "tei" for GPU-accelerated instances, "tei-cpu" for CPU-only instances
        image_tag       = "2.0.1-tei1.2.3-cpu-py310-ubuntu22.04"       # Version of the Hugging Face Text Embeddings Inference image to use. See https://huggingface.co/docs/text-embeddings-inference.
        environment = {                                                # Environment variables to be passed to the Hugging Face Text Embeddings Inference image. See https://huggingface.co/docs/text-embeddings-inference/cli_arguments.
          HF_MODEL_ID           = "mixedbread-ai/mxbai-embed-large-v1" # To use a remote model from Hugging Face Hub (takes precedence over s3_model_key above, if present)
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
module "probation_search_sagemaker_endpoint" {
  for_each = tomap(local.probation_search_environment)

  source = "./modules/sagemaker_endpoint"

  s3_model_bucket_name = local.probation_search_model_bucket_name
  s3_model_key         = try(each.value.s3_model_key, null)
  name                 = each.value.namespace
  instance_type        = each.value.instance_type
  repository_name      = each.value.repository_name
  image_tag            = each.value.image_tag
  environment          = each.value.environment
  tags                 = local.tags
}

# ------------------------------------------------------------------------------
# IAM
# ------------------------------------------------------------------------------
module "probation_search_cross_account_role" {
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
      resources = [module.probation_search_sagemaker_endpoint[each.key].sagemaker_endpoint_arn]
    }
  ]

  tags = local.tags
}

