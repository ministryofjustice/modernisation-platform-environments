# Not placed in the VPC: Lambda's own poller reads from Kafka, and the function only logs.
module "events_consumer" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  count   = contains(local.deploy_to, local.environment) ? 1 : 0
  source  = "terraform-aws-modules/lambda/aws"
  version = "8.13.0"

  architectures                     = ["arm64"]
  cloudwatch_logs_retention_in_days = 90
  description                       = "Consume the Kafka events topic and log each message"
  function_name                     = "${local.name}-events-consumer"
  handler                           = "handler.lambda_handler"
  ignore_source_code_hash           = true
  runtime                           = "python3.12"
  timeout                           = 30
  source_path = [{
    path = "${path.module}/lambda/events-consumer"
    patterns = [
      "!(.*/)?__pycache__(/.*)?$",
      "!(.*/)?[^/]+\\.pyc$",
    ]
  }]

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
      resources = ["arn:aws:kafka:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:group/${local.cluster_name}/*/events-consumer"]
    }
  }

  tags = local.extended_tags
}

resource "aws_lambda_event_source_mapping" "events_consumer" {
  count             = contains(local.deploy_to, local.environment) ? 1 : 0
  event_source_arn  = aws_msk_cluster.cluster[0].arn
  function_name     = module.events_consumer[0].lambda_function_arn
  topics            = ["events"]
  starting_position = "LATEST"
  batch_size        = 1

  amazon_managed_kafka_event_source_config {
    consumer_group_id = "events-consumer"
  }

  # The topic must exist before the mapping is created
  depends_on = [aws_lambda_invocation.create_topics]
}
