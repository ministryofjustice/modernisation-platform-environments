module "kms_slack" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  count   = contains(local.deploy_to, local.environment) ? 1 : 0
  source  = "terraform-aws-modules/kms/aws"
  version = "4.2.2"

  aliases                 = ["${local.name}/slack-notifications"]
  description             = "KMS CMK for the Integration Hub events Slack SNS topic"
  enable_default_policy   = true
  enable_key_rotation     = true
  deletion_window_in_days = 30
  key_usage               = "ENCRYPT_DECRYPT"
  is_enabled              = true

  key_administrators = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]

  key_statements = [
    {
      sid = "AllowSNSService"
      actions = [
        "kms:Decrypt",
        "kms:GenerateDataKey*",
      ]
      resources = ["*"]
      principals = [{
        type        = "Service"
        identifiers = ["sns.amazonaws.com"]
      }]
      condition = [{
        test     = "StringEquals"
        variable = "aws:SourceAccount"
        values   = [data.aws_caller_identity.current.account_id]
      }]
    },
  ]

  tags = local.extended_tags
}

module "sns_slack" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  count   = contains(local.deploy_to, local.environment) ? 1 : 0
  source  = "terraform-aws-modules/sns/aws"
  version = "7.2.0"

  name              = "${local.name}-slack"
  kms_master_key_id = module.kms_slack[0].key_arn
  tags              = local.extended_tags
}

# AWS Chatbot can only post to Slack channels, not to individual users.
# The AWS account must already be connected to the Slack workspace in Amazon Q Developer in chat applications.
module "chatbot_slack" {
  count  = contains(local.deploy_to, local.environment) ? 1 : 0
  source = "github.com/ministryofjustice/modernisation-platform-terraform-aws-chatbot?ref=0ec33c7bfde5649af3c23d0834ea85c849edf3ac" # v3.0.0

  application_name = "${local.name}-slack"
  slack_channel_id = local.slack_channel_id
  slack_team_id    = local.slack_team_id
  sns_topic_arns   = [module.sns_slack[0].topic_arn]
  # Notifications only: no AWS command permissions for channel users.
  managed_policy_arns = []
  guardrail_policies  = [aws_iam_policy.slack_notifications_only[0].arn]
  tags                = local.extended_tags
}

resource "aws_iam_policy" "slack_notifications_only" {
  count       = contains(local.deploy_to, local.environment) ? 1 : 0
  name        = "${local.name}-slack-notifications-only"
  description = "Disable AWS commands through the events Slack integration"
  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{ Effect = "Deny", Action = "*", Resource = "*" }]
  })
  tags = local.extended_tags
}

# Not placed in the VPC: Lambda's own poller reads from Kafka, and the function only calls SNS.
module "slack_notifier" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  count   = contains(local.deploy_to, local.environment) ? 1 : 0
  source  = "terraform-aws-modules/lambda/aws"
  version = "8.13.0"

  architectures                     = ["arm64"]
  cloudwatch_logs_retention_in_days = 90
  description                       = "Forward events from the Kafka events topic to Slack"
  function_name                     = "${local.name}-slack-notifier"
  handler                           = "handler.lambda_handler"
  ignore_source_code_hash           = true
  runtime                           = "python3.12"
  timeout                           = 30
  source_path = [{
    path = "${path.module}/lambda/slack-notifier"
    patterns = [
      "!(.*/)?__pycache__(/.*)?$",
      "!(.*/)?[^/]+\\.pyc$",
    ]
  }]

  environment_variables = {
    SNS_TOPIC_ARN = module.sns_slack[0].topic_arn
  }

  attach_policies    = true
  number_of_policies = 1
  policies           = ["arn:aws:iam::aws:policy/service-role/AWSLambdaMSKExecutionRole"]

  attach_policy_statements = true
  policy_statements = {
    kafka_read = {
      effect = "Allow"
      actions = [
        "kafka-cluster:Connect",
        "kafka-cluster:DescribeCluster",
      ]
      resources = [aws_msk_cluster.cluster[0].arn]
    }
    kafka_read_topic = {
      effect = "Allow"
      actions = [
        "kafka-cluster:DescribeTopic",
        "kafka-cluster:ReadData",
      ]
      resources = ["arn:aws:kafka:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:topic/${local.cluster_name}/*/events"]
    }
    kafka_consumer_group = {
      effect = "Allow"
      actions = [
        "kafka-cluster:AlterGroup",
        "kafka-cluster:DescribeGroup",
      ]
      resources = ["arn:aws:kafka:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:group/${local.cluster_name}/*/slack-notifier"]
    }
    publish_slack = {
      effect    = "Allow"
      actions   = ["sns:Publish"]
      resources = [module.sns_slack[0].topic_arn]
    }
    encrypt_slack = {
      effect    = "Allow"
      actions   = ["kms:Decrypt", "kms:GenerateDataKey*"]
      resources = [module.kms_slack[0].key_arn]
    }
  }

  tags = local.extended_tags
}

resource "aws_lambda_event_source_mapping" "slack_notifier" {
  count             = contains(local.deploy_to, local.environment) ? 1 : 0
  event_source_arn  = aws_msk_cluster.cluster[0].arn
  function_name     = module.slack_notifier[0].lambda_function_arn
  topics            = ["events"]
  starting_position = "LATEST"
  batch_size        = 1

  amazon_managed_kafka_event_source_config {
    consumer_group_id = "slack-notifier"
  }

  # The topic must exist before the mapping is created
  depends_on = [aws_lambda_invocation.create_topics]
}
