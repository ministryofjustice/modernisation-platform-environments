module "create_topics" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  count   = contains(local.deploy_to, local.environment) ? 1 : 0
  source  = "terraform-aws-modules/lambda/aws"
  version = "8.13.0"

  architectures                     = ["arm64"]
  cloudwatch_logs_retention_in_days = 90
  description                       = "Create Kafka topics on the MSK cluster. Runs inside the VPC because the brokers are not reachable from the Terraform runners"
  function_name                     = "${local.name}-create-topics"
  handler                           = "handler.lambda_handler"
  ignore_source_code_hash           = true
  runtime                           = "python3.12"
  memory_size                       = 256
  timeout                           = 120
  source_path = [{
    path             = "${path.module}/lambda/create-topics"
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
  }

  attach_policy_statements = true
  policy_statements = {
    connect = {
      effect    = "Allow"
      actions   = ["kafka-cluster:Connect", "kafka-cluster:DescribeCluster"]
      resources = [aws_msk_cluster.cluster[0].arn]
    }
    manage_topics = {
      effect = "Allow"
      actions = [
        "kafka-cluster:CreateTopic",
        "kafka-cluster:DescribeTopic",
      ]
      resources = ["arn:aws:kafka:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:topic/${local.cluster_name}/*"]
    }
  }

  tags = local.extended_tags
}

# Invoked on creation, and again whenever the topics map changes. The function skips topics that already exist.
resource "aws_lambda_invocation" "create_topics" {
  count         = contains(local.deploy_to, local.environment) ? 1 : 0
  function_name = module.create_topics[0].lambda_function_name
  input         = jsonencode({ topics = [for name, config in local.kafka_topics : merge({ name = name }, config)] })

  lifecycle_scope = "CREATE_ONLY"

  depends_on = [aws_vpc_security_group_egress_rule.events_to_kafka_msk]
}
