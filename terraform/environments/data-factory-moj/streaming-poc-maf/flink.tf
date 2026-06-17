# ---------------------------------------------------------------------------------------------------------------------
# Managed Apache Flink
# ---------------------------------------------------------------------------------------------------------------------
module "flink_geofence" {
  count  = contains(local.deploy_to, local.environment) ? 1 : 0
  source = "./modules/managed-apache-flink"

  private_subnets  = data.aws_subnets.shared-private.ids
  s3_source_bucket = module.flink_artifacts_bucket.s3_bucket_id
  s3_source_key    = local.geofence_app.jar_filename

  vpc_security_groups = [
    aws_security_group.allow_s3.id,
    aws_security_group.allow_msk.id
  ]

  config_property_group = {
    app_name              = "flink-moj-geofence"
    runtime_environment   = "FLINK-1_20"
    parallelism           = 2
    parallelism_per_kpu   = 1
    auto_scaling_enabled  = true
    log_retention_days    = 7
    snapshots_enabled     = true
    checkpointing_enabled = true
    custom_property_group = {
      spring-profile = substr(lower(local.environment), 0, 3)
      app_name       = "flink-moj-geofence"
    }
    job_property_group = {
      job_group = "none"
    }
    additional_iam_statements = [
      {
        sid       = "AllowAllOpensearch"
        effect    = "Allow"
        actions   = ["opensearch:*"]
        resources = ["*"]
      },
      {
        sid    = "AllowMSKClusters"
        effect = "Allow"
        actions = [
          "kafka-cluster:AlterCluster",
          "kafka-cluster:Connect",
          "kafka-cluster:DescribeCluster"
        ]
        resources = [data.external.msk_arn.result.arn]
      },
      {
        sid    = "AllowMSKTopics"
        effect = "Allow"
        actions = [
          "kafka-cluster:AlterTopic",
          "kafka-cluster:AlterTopicDynamicConfiguration",
          "kafka-cluster:CreateTopic",
          "kafka-cluster:DeleteTopic",
          "kafka-cluster:DescribeTopic",
          "kafka-cluster:DescribeTopicDynamicConfiguration",
          "kafka-cluster:ReadData",
          "kafka-cluster:WriteData"
        ]
        resources = [
          format("%s/*", replace(data.external.msk_arn.result.arn, ":cluster/", ":topic/"))
        ]
      },
      {
        sid    = "AllowMSKGroups"
        effect = "Allow"
        actions = [
          "kafka-cluster:AlterGroup",
          "kafka-cluster:DescribeGroup"
        ]
        resources = [
          format("%s/*", replace(data.external.msk_arn.result.arn, ":cluster/", ":group/"))
        ]
      }
    ]
  }
}
