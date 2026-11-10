resource "aws_security_group" "events_to_kafka" {
  #checkov:skip=CKV2_AWS_5:Skipping because this SG is attached via the Lambda vpc_config block
  count       = contains(local.deploy_to, local.environment) ? 1 : 0
  name_prefix = "${local.name}-events-to-kafka-sg"
  description = "Security group for the events-to-kafka Lambda"
  vpc_id      = data.aws_vpc.shared.id

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(local.extended_tags, {
    Name = "${local.name}-events-to-kafka-sg"
  })
}

resource "aws_vpc_security_group_egress_rule" "events_to_kafka_msk" {
  count                        = contains(local.deploy_to, local.environment) ? 1 : 0
  security_group_id            = aws_security_group.events_to_kafka[0].id
  description                  = "Allow outbound IAM traffic to the MSK cluster"
  from_port                    = 9098
  to_port                      = 9098
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.msk[0].id
}

module "events_to_kafka" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  count   = contains(local.deploy_to, local.environment) ? 1 : 0
  source  = "terraform-aws-modules/lambda/aws"
  version = "8.13.0"

  architectures                     = ["arm64"]
  cloudwatch_logs_retention_in_days = 90
  description                       = "Publish events from the Integration Hub events bus to the Kafka events topic"
  function_name                     = "${local.name}-events-to-kafka"
  handler                           = "handler.lambda_handler"
  ignore_source_code_hash           = true
  runtime                           = "python3.12"
  timeout                           = 60
  source_path = [{
    path             = "${path.module}/../api/lambda/events-to-kafka"
    pip_requirements = true
    patterns = [
      "!(.*/)?__pycache__(/.*)?$",
      "!(.*/)?[^/]+\\.pyc$",
    ]
  }]

  vpc_subnet_ids         = data.aws_subnets.shared-private.ids
  vpc_security_group_ids = [aws_security_group.events_to_kafka[0].id]
  attach_network_policy  = true

  environment_variables = {
    BOOTSTRAP_SERVERS = aws_msk_cluster.cluster[0].bootstrap_brokers_sasl_iam
    KAFKA_TOPIC       = "events"
  }

  attach_policy_statements = true
  policy_statements = {
    connect = {
      effect    = "Allow"
      actions   = ["kafka-cluster:Connect", "kafka-cluster:DescribeCluster"]
      resources = [aws_msk_cluster.cluster[0].arn]
    }
    write_events_topic = {
      effect = "Allow"
      actions = [
        "kafka-cluster:DescribeTopic",
        "kafka-cluster:WriteData",
      ]
      resources = ["arn:aws:kafka:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:topic/${local.cluster_name}/*/events"]
    }
  }

  allowed_triggers = {
    eventbridge = {
      principal  = "events.amazonaws.com"
      source_arn = aws_cloudwatch_event_rule.events_to_kafka[0].arn
    }
  }

  tags = local.extended_tags
}
