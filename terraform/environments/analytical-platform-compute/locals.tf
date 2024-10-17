locals {
  /* VPC */
  our_vpc_name                                        = "${local.application_name}-${local.environment}"
  vpc_flow_log_cloudwatch_log_group_name_prefix       = "/aws/vpc-flow-log/"
  vpc_flow_log_cloudwatch_log_group_name_suffix       = local.our_vpc_name
  vpc_flow_log_cloudwatch_log_group_retention_in_days = 400
  vpc_flow_log_max_aggregation_interval               = 60

  /* AMP */
  amp_workspace_alias                        = "${local.application_name}-${local.environment}"
  amp_cloudwatch_log_group_name              = "/aws/amp/${local.amp_workspace_alias}"
  amp_cloudwatch_log_group_retention_in_days = 400

  /* EKS */
  eks_cluster_name                           = "${local.application_name}-${local.environment}"
  eks_cloudwatch_log_group_name              = "/aws/eks/${local.eks_cluster_name}/logs"
  eks_cloudwatch_log_group_retention_in_days = 400

  /* Kube Prometheus Stack */
  prometheus_operator_crd_version = "v0.77.1"

  /* Mapping Analytical Platform Environments to Modernisation Platform */

  analytical_platform_environment = format("analytical-platform-%s", local.environment == "test" ? "development" : local.environment)

  /* Environment Configuration */
  environment_configuration = local.environment_configurations[local.environment]

  /* S3 - APC bucket locals */
  apc_buckets = {
    "mojap-derived-tables-replication" = {
      force_destroy       = true
      object_lock_enabled = false
      acl                 = "private"
      versioning = {
        status = "Disabled"
      }
      bucket = "mojap-derived-tables-replication-${local.environment}"
      server_side_encryption_configuration = {
        rule = {
          bucket_key_enabled = false

          apply_server_side_encryption_by_default = {
            sse_algorithm = "AES256"
          }
        }
      }
      public_access_block = {
        block_public_acls       = true
        block_public_policy     = true
        ignore_public_acls      = true
        restrict_public_buckets = true
      }
    }
    "mlflow_buckets" = {
      bucket = "mojap-compute-${local.environment}-mlflow"
      force_destroy = true
      server_side_encryption_configuration = {
        rule = {
          bucket_key_enabled = true
          apply_server_side_encryption_by_default = {
            kms_master_key_id = module.mlflow_s3_kms.key_arn
            sse_algorithm     = "aws:kms"
          }
        }
      }
    }
  }
}
