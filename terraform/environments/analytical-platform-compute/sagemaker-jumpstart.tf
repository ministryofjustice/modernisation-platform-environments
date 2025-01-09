# image
# model id

# ----------------
# locals
# ----------------
locals {
  name_prefix          = "test"
  pytorch_version      = "2.1.0"
  tensorflow_version   = null
  transformers_version = "4.37.0"
  instance_type        = "ml.g4dn.xlarge"
  instance_count       = 1
  async_config = {
    s3_output_path    = "mojap-compute-sagemaker-jumpstart-${local.environment}/output"
    s3_failure_path   = "mojap-compute-sagemaker-jumpstart-${local.environment}/failure"
    kms_key_id        = null
    sns_error_topic   = null
    sns_success_topic = null
  }
  serverless_config = {
    max_concurrency   = null
    memory_size_in_mb = null
  }
  hf_model_id              = "mixedbread-ai/mxbai-rerank-xsmall-v1"
  hf_api_token             = null
  hf_model_revision        = null
  model_data               = null
  sagemaker_execution_role = null
  autoscaling = {
    min_capacity               = 1
    max_capacity               = null
    scaling_target_invocations = null
    scale_in_cooldown          = 300
    scale_out_cooldown         = 660
  }
  framework_version = local.pytorch_version != null ? local.pytorch_version : local.tensorflow_version
  repository_name   = local.pytorch_version != null ? "huggingface-pytorch-inference" : "huggingface-tensorflow-inference"
  device            = length(regexall("^ml\\.[g|p{1,3}\\.$]", local.instance_type)) > 0 ? "gpu" : "cpu"
  image_key         = "${local.framework_version}-${local.device}"
  pytorch_image_tag = {
    "2.0.0-cpu" = "2.0.0-transformers${local.transformers_version}-cpu-py310-ubuntu20.04"
    "2.0.0-gpu" = "2.0.0-transformers${local.transformers_version}-gpu-py310-cu118-ubuntu20.04"
    "2.1.0-gpu" = "2.1.0-transformers${local.transformers_version}-gpu-py310-cu118-ubuntu20.04"
  }
  # tensorflow_image_tag = {
  #   "2.5.1-gpu" = "2.5.1-transformers${local.transformers_version}-gpu-py36-cu111-ubuntu18.04"
  #   "2.5.1-cpu" = "2.5.1-transformers${local.transformers_version}-cpu-py36-ubuntu18.04"
  # }
  sagemaker_endpoint_type = {
    real_time    = (local.async_config.s3_output_path == null && local.serverless_config.max_concurrency == null) ? true : false
    asynchronous = (local.async_config.s3_output_path != null && local.serverless_config.max_concurrency == null) ? true : false
    serverless   = (local.async_config.s3_output_path == null && local.serverless_config.max_concurrency != null) ? true : false
  }

}

# random lowercase string used for naming
resource "random_string" "resource_id" {
  length  = 8
  lower   = true
  special = false
  upper   = false
  numeric = false
}

# ----------------
# Container Image
# ----------------
data "aws_sagemaker_prebuilt_ecr_image" "huggingface_image" {
  repository_name = "huggingface-pytorch-inference"
  image_tag       = local.pytorch_version != null ? local.pytorch_image_tag[local.image_key] : local.tensorflow_image_tag[local.image_key]
}

# ----------------
# Permission
# ----------------
module "sagemaker_execution_role" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  count = terraform.workspace == "analytical-platform-compute-development" ? 1 : 0 # Creates IAM role if not provided

  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "5.48.0"

  create_role       = true
  role_name         = "poc-sagemaker-execution-role"
  role_requires_mfa = false

  trusted_role_services = ["sagemaker.amazonaws.com"]

  custom_role_policy_arns = [module.sagemaker_jumpstart_execution_policy[0].arn]

  tags = local.tags
}

data "aws_iam_policy_document" "sagemaker_jumpstart_execution_policy" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions
  #checkov:skip=CKV_AWS_111: test policy for development
  #checkov:skip=CKV_AWS_356: test policy for development

  count = terraform.workspace == "analytical-platform-compute-development" ? 1 : 0 # Creates IAM role if not provided
  statement {
    sid    = "LogsAccess"
    effect = "Allow"
    actions = [
      "cloudwatch:PutMetricData",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:CreateLogGroup",
      "logs:DescribeLogStreams",
    ]
    resources = [
      "*"
    ]
  }
  statement {
    sid    = "BucketAccess"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket"
    ]
    resources = [
      "arn:aws:s3:::mojap-compute-sagemaker-jumpstart-${local.environment}/*",
      "arn:aws:s3:::mojap-compute-sagemaker-jumpstart-${local.environment}"
    ]
  }
  statement {
    sid    = "EcrSagemakerImageAccess"
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage"
    ]
    resources = ["*"]
  }
}

module "sagemaker_jumpstart_execution_policy" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions
  count = terraform.workspace == "analytical-platform-compute-development" ? 1 : 0 # Creates IAM role if not provided

  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.48.0"

  name = "sagemaker-jumpstart-execution-policy"

  policy = data.aws_iam_policy_document.sagemaker_jumpstart_execution_policy[0].json

  tags = local.tags
}

module "sagemaker_bucket" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  count   = terraform.workspace == "analytical-platform-compute-development" ? 1 : 0 # Creates IAM role if not provided
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.2.2"

  bucket = "mojap-compute-sagemaker-jumpstart-${local.environment}"

  force_destroy = true

  attach_policy = true
  policy        = data.aws_iam_policy_document.sagemaker_bucket_policy[0].json

  object_lock_enabled = false

  versioning = {
    status = "Disabled"
  }

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = merge(
    local.tags,
    { "backup" = "false" }
  )
}

data "aws_iam_policy_document" "sagemaker_bucket_policy" {
  #checkov:skip=CKV_AWS_356:resource "*" limited by condition
  #checkov:skip=CKV_AWS_111: test policy for development
  #checkov:skip=CKV_AWS_356: test policy for development

  count = terraform.workspace == "analytical-platform-compute-development" ? 1 : 0 # Creates IAM role if not provided
  statement {
    sid     = "BroadS3Access"
    effect  = "Allow"
    actions = ["s3:*"]
    resources = [
      "arn:aws:s3:::mojap-compute-sagemaker-jumpstart-${local.environment}/*",
      "arn:aws:s3:::mojap-compute-sagemaker-jumpstart-${local.environment}"
    ]

    principals {
      type        = "AWS"
      identifiers = [module.sagemaker_execution_role[0].iam_role_arn]
    }
  }
}


# ----------------
# SageMaker Model
# ----------------
resource "aws_sagemaker_model" "model_with_hub_model" { # mxbai_rerank_xsmall_model 
  count                    = terraform.workspace == "analytical-platform-compute-development" ? 1 : 0
  name                     = "mxbai-rerank-xsmall-model"
  execution_role_arn       = module.sagemaker_execution_role[0].iam_role_arn
  tags                     = local.tags
  enable_network_isolation = true

  primary_container {
    # image = "764974769150.dkr.ecr.eu-west-2.amazonaws.com/tei:2.0.1-tei1.2.3-gpu-py310-cu122-ubuntu22.04"
    image = data.aws_sagemaker_prebuilt_ecr_image.huggingface_image.registry_path
    environment = {
      HF_MODEL_ID = local.hf_model_id
    }
  }

  lifecycle {
    create_before_destroy = false
  }
}

data "aws_sagemaker_prebuilt_ecr_image" "huggingface_image" {
  repository_name = "huggingface-pytorch-inference"
  image_tag       = "2.1.0-transformers4.37.0-gpu-py310-cu118-ubuntu20.04"
}


locals {
  # sagemaker_model = local.model_data != null && local.hf_model_id == null ? aws_sagemaker_model.model_with_model_artifact[0] : aws_sagemaker_model.model_with_hub_model[0]
  sagemaker_model = aws_sagemaker_model.mxbai_rerank_xsmall_model[0]
}

###
# ----------------
# SageMaker Endpoint configuration
# ----------------

resource "aws_sagemaker_endpoint_configuration" "huggingface_realtime" {
  count = terraform.workspace == "analytical-platform-compute-development" && local.sagemaker_endpoint_type.real_time ? 1 : 0
  name  = "${local.name_prefix}-ep-config-${random_string.resource_id.result}"
  tags  = local.tags


  production_variants {
    variant_name           = "AllTraffic"
    model_name             = local.sagemaker_model.name
    initial_instance_count = local.instance_count
    instance_type          = local.instance_type
  }
}


resource "aws_sagemaker_endpoint_configuration" "huggingface_async" {
  count = terraform.workspace == "analytical-platform-compute-development" && local.sagemaker_endpoint_type.asynchronous ? 1 : 0
  name  = "${local.name_prefix}-ep-config-${random_string.resource_id.result}"
  tags  = local.tags


  production_variants {
    variant_name           = "AllTraffic"
    model_name             = local.sagemaker_model.name
    initial_instance_count = local.instance_count
    instance_type          = local.instance_type
  }
  async_inference_config {
    output_config {
      s3_output_path  = local.async_config.s3_output_path
      s3_failure_path = local.async_config.s3_failure_path
      kms_key_id      = local.async_config.kms_key_id
      notification_config {
        error_topic   = local.async_config.sns_error_topic
        success_topic = local.async_config.sns_success_topic
      }
    }
  }
}


resource "aws_sagemaker_endpoint_configuration" "huggingface_serverless" {
  count = terraform.workspace == "analytical-platform-compute-development" && local.sagemaker_endpoint_type.serverless ? 1 : 0
  name  = "${local.name_prefix}-ep-config-${random_string.resource_id.result}"
  tags  = local.tags


  production_variants {
    variant_name = "AllTraffic"
    model_name   = local.sagemaker_model.name

    serverless_config {
      max_concurrency   = local.serverless_config.max_concurrency
      memory_size_in_mb = local.serverless_config.memory_size_in_mb
    }
  }
}


locals {
  sagemaker_endpoint_config = (
    local.sagemaker_endpoint_type.real_time ?
    aws_sagemaker_endpoint_configuration.huggingface[0] : (
      local.sagemaker_endpoint_type.asynchronous ?
      aws_sagemaker_endpoint_configuration.huggingface_async[0] : (
        local.sagemaker_endpoint_type.serverless ?
        aws_sagemaker_endpoint_configuration.huggingface_serverless[0] : null
      )
    )
  )
}

# ----------------
# SageMaker Endpoint
# ----------------


resource "aws_sagemaker_endpoint" "huggingface" {
  count = terraform.workspace == "analytical-platform-compute-development" ? 1 : 0
  name  = "${local.name_prefix}-ep-${random_string.resource_id.result}"
  tags  = local.tags

  endpoint_config_name = local.sagemaker_endpoint_config.name
}

# ----------------
# AutoScaling configuration
# ----------------


locals {
  use_autoscaling = local.autoscaling.max_capacity != null && local.autoscaling.scaling_target_invocations != null && !local.sagemaker_endpoint_type.serverless ? 1 : 0
}

resource "aws_appautoscaling_target" "sagemaker_target" {
  count              = local.use_autoscaling
  min_capacity       = local.autoscaling.min_capacity
  max_capacity       = local.autoscaling.max_capacity
  resource_id        = "endpoint/${aws_sagemaker_endpoint.huggingface.name}/variant/AllTraffic"
  scalable_dimension = "sagemaker:variant:DesiredInstanceCount"
  service_namespace  = "sagemaker"
}

resource "aws_appautoscaling_policy" "sagemaker_policy" {
  count              = local.use_autoscaling
  name               = "${local.name_prefix}-scaling-target-${random_string.resource_id.result}"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.sagemaker_target[0].resource_id
  scalable_dimension = aws_appautoscaling_target.sagemaker_target[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.sagemaker_target[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "SageMakerVariantInvocationsPerInstance"
    }
    target_value       = local.autoscaling.scaling_target_invocations
    scale_in_cooldown  = local.autoscaling.scale_in_cooldown
    scale_out_cooldown = local.autoscaling.scale_out_cooldown
  }
}
