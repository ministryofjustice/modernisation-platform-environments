# ---------------------------------------------------------------------------------------------------------------------
# Managed Apache Flink
# ---------------------------------------------------------------------------------------------------------------------
module "flink_geofence" {
  count  = contains(local.deploy_to, local.environment) ? 1 : 0
  source = "./modules/managed-apache-flink"

  depends_on = [module.flink_artifacts_bucket]

  private_subnets  = data.aws_subnets.shared-private.ids
  s3_source_bucket = module.flink_artifacts_bucket.s3_bucket_id
  s3_source_key    = local.geofence_app.jar_filename
  s3_kms_key_arn   = aws_kms_key.s3[0].arn

  vpc_security_groups = [
    aws_security_group.allow_s3[0].id,
    aws_security_group.allow_msk[0].id
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
        # TODO: This is a workaround for the fact that the ARN of the MSK cluster is not available yet
        resources = ["*"]
        #resources = [data.external.msk_arn]
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
        # TODO: This is a workaround for the fact that the ARN of the MSK cluster is not available yet
        resources = ["*"]
        #resources = [
        #  format("%s/*", replace(data.external.msk_arn, ":cluster/", ":topic/"))
        #]
      },
      {
        sid    = "AllowMSKGroups"
        effect = "Allow"
        actions = [
          "kafka-cluster:AlterGroup",
          "kafka-cluster:DescribeGroup"
        ]
        # TODO: This is a workaround for the fact that the ARN of the MSK cluster is not available yet
        resources = ["*"]
        #resources = [
        #  format("%s/*", replace(local.msk_arn, ":cluster/", ":group/"))
        #]
      }
    ]
  }

  tags = local.extended_tags
}
