# ---------------------------------------------------------------------------------------------------------------------
# ECS Services
# ---------------------------------------------------------------------------------------------------------------------

# --- Shared IAM ---

data "aws_iam_policy_document" "ecs_task_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# Shared execution role policy - ECR pull and KMS decrypt
data "aws_iam_policy_document" "ecs_task_exec" {
  statement {
    effect = "Allow"
    actions = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability"
    ]
    resources = [
      aws_ecr_repository.repository["alerts"].arn,
      aws_ecr_repository.repository["sdg"].arn
    ]
  }
  statement {
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"] # TODO: scope to specific resource once that resource is created
  }
  statement {
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey"
    ]
    resources = [data.aws_kms_key.general_shared.arn]
  }
}

# --- Synthetic Data Generator IAM ---

resource "aws_iam_role" "sdg_task" {
  count              = contains(local.deploy_to, local.environment) ? 1 : 0
  name               = "${local.sdg_prefix}-task"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume.json
  tags               = local.extended_tags
}

resource "aws_iam_role" "sdg_task_exec" {
  count              = contains(local.deploy_to, local.environment) ? 1 : 0
  name               = "${local.sdg_prefix}-task-exec"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume.json
  tags               = local.extended_tags
}

resource "aws_iam_role_policy_attachment" "sdg_task_exec" {
  count      = contains(local.deploy_to, local.environment) ? 1 : 0
  role       = aws_iam_role.sdg_task_exec[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "sdg_task_exec_ecr" {
  count  = contains(local.deploy_to, local.environment) ? 1 : 0
  name   = "${local.sdg_prefix}-task-exec-ecr"
  role   = aws_iam_role.sdg_task_exec[0].name
  policy = data.aws_iam_policy_document.ecs_task_exec.json
}

data "aws_iam_policy_document" "sdg_task" {
  for_each = toset(contains(local.deploy_to, local.environment) ? ["sdg_task"] : [])
  statement {
    sid    = "AllowMSKClusters"
    effect = "Allow"
    actions = [
      "kafka-cluster:AlterCluster",
      "kafka-cluster:Connect",
      "kafka-cluster:DescribeCluster"
    ]
    resources = [local.msk_cluster_arn]
  }

  statement {
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
    resources = local.msk_topic_arns
  }

  statement {
    sid    = "AllowMSKGroups"
    effect = "Allow"
    actions = [
      "kafka-cluster:AlterGroup",
      "kafka-cluster:DescribeGroup"
    ]
    resources = local.msk_group_arns
  }
  statement {
    sid    = "SSMExec"
    effect = "Allow"
    actions = [
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "sdg_task" {
  count  = contains(local.deploy_to, local.environment) ? 1 : 0
  name   = "${local.sdg_prefix}-task"
  role   = aws_iam_role.sdg_task[0].name
  policy = data.aws_iam_policy_document.sdg_task["sdg_task"].json
}

# --- Alerts Service IAM ---

resource "aws_iam_role" "alerts_task" {
  count              = contains(local.deploy_to, local.environment) ? 1 : 0
  name               = "${local.alerts_prefix}-task"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume.json
  tags               = local.extended_tags
}

resource "aws_iam_role" "alerts_task_exec" {
  count              = contains(local.deploy_to, local.environment) ? 1 : 0
  name               = "${local.alerts_prefix}-task-exec"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume.json
  tags               = local.extended_tags
}

resource "aws_iam_role_policy_attachment" "alerts_task_exec" {
  count      = contains(local.deploy_to, local.environment) ? 1 : 0
  role       = aws_iam_role.alerts_task_exec[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "alerts_task_exec_ecr" {
  count  = contains(local.deploy_to, local.environment) ? 1 : 0
  name   = "${local.alerts_prefix}-task-exec-ecr"
  role   = aws_iam_role.alerts_task_exec[0].name
  policy = data.aws_iam_policy_document.ecs_task_exec.json
}

data "aws_iam_policy_document" "alerts_task" {
  for_each = toset(contains(local.deploy_to, local.environment) ? ["alerts_task"] : [])
  statement {
    sid    = "AllowMSKClusters"
    effect = "Allow"
    actions = [
      "kafka-cluster:AlterCluster",
      "kafka-cluster:Connect",
      "kafka-cluster:DescribeCluster"
    ]
    resources = [local.msk_cluster_arn]
  }

  statement {
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
    resources = local.msk_topic_arns
  }

  statement {
    sid    = "AllowMSKGroups"
    effect = "Allow"
    actions = [
      "kafka-cluster:AlterGroup",
      "kafka-cluster:DescribeGroup"
    ]
    resources = local.msk_group_arns
  }

  statement {
    sid    = "AllowSNSTopics"
    effect = "Allow"
    actions = [
      "sns:Publish"
    ]
    resources = [data.aws_sns_topic.drone_incursion_topic["topic"].arn]
  }

  statement {
    sid    = "AllowKMSAccess"
    effect = "Allow"
    actions = [
      "kms:GenerateDataKey",
      "kms:Decrypt"
    ]
    resources = [data.aws_kms_key.sns_topic_kmskey["sns"].arn]
  }
}

resource "aws_iam_role_policy" "alerts_task" {
  count  = contains(local.deploy_to, local.environment) ? 1 : 0
  name   = "${local.alerts_prefix}-task"
  role   = aws_iam_role.alerts_task[0].name
  policy = data.aws_iam_policy_document.alerts_task["alerts_task"].json
}

# --- Kafka-ui IAM ---

resource "aws_iam_role" "kafka_ui_task" {
  count              = contains(local.deploy_to, local.environment) ? 1 : 0
  name               = "${local.kafka_ui_prefix}-task"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume.json
  tags               = local.extended_tags
}

resource "aws_iam_role" "kafka_ui_task_exec" {
  count              = contains(local.deploy_to, local.environment) ? 1 : 0
  name               = "${local.kafka_ui_prefix}-task-exec"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume.json
  tags               = local.extended_tags
}

resource "aws_iam_role_policy_attachment" "kafka_ui_task_exec" {
  count      = contains(local.deploy_to, local.environment) ? 1 : 0
  role       = aws_iam_role.kafka_ui_task_exec[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "kafka-ui_task_exec_ecr" {
  count  = contains(local.deploy_to, local.environment) ? 1 : 0
  name   = "${local.kafka_ui_prefix}-task-exec-ecr"
  role   = aws_iam_role.kafka_ui_task_exec[0].name
  policy = data.aws_iam_policy_document.ecs_task_exec.json
}

data "aws_iam_policy_document" "kafka_ui_task" {
  for_each = toset(contains(local.deploy_to, local.environment) ? ["kafka_ui_task"] : [])
  statement {
    sid    = "kafkaUiMskAccess"
    effect = "Allow"
    actions = [
      "kafka-cluster:WriteData",
      "kafka-cluster:ReadData",
      "kafka-cluster:DescribeTransactionalId",
      "kafka-cluster:DescribeTopicDynamicConfiguration",
      "kafka-cluster:DescribeTopic",
      "kafka-cluster:DescribeGroup",
      "kafka-cluster:DescribeClusterDynamicConfiguration",
      "kafka-cluster:DescribeCluster",
      "kafka-cluster:DeleteTopic",
      "kafka-cluster:DeleteGroup",
      "kafka-cluster:CreateTopic",
      "kafka-cluster:Connect",
      "kafka-cluster:AlterTopicDynamicConfiguration",
      "kafka-cluster:AlterTopic",
      "kafka-cluster:AlterGroup",
      "kafka-cluster:AlterClusterDynamicConfiguration"
    ]
    resources = concat([local.msk_cluster_arn], local.msk_topic_arns, local.msk_group_arns)
  }
}

resource "aws_iam_role_policy" "kafka_ui_task" {
  count  = contains(local.deploy_to, local.environment) ? 1 : 0
  name   = "${local.kafka_ui_prefix}-task"
  role   = aws_iam_role.kafka_ui_task[0].name
  policy = data.aws_iam_policy_document.kafka_ui_task["kafka_ui_task"].json
}

# --- Security Groups ---

resource "aws_security_group" "sdg" {
  #checkov:skip=CKV2_AWS_5: Security group is attached to the SDG ECS service network configuration; Checkov cannot infer attachment through counted/dynamic references.
  count       = contains(local.deploy_to, local.environment) ? 1 : 0
  name_prefix = local.sdg_prefix
  vpc_id      = data.aws_vpc.shared.id
  description = "${local.sdg_prefix} SG"

  tags = merge(local.extended_tags, { Name = local.sdg_prefix })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_egress_rule" "sdg_https_out" {
  count             = contains(local.deploy_to, local.environment) ? 1 : 0
  security_group_id = aws_security_group.sdg[0].id
  description       = "Allow HTTPS outbound for ECR and AWS API calls"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "sdg_msk_out" {
  count             = contains(local.deploy_to, local.environment) ? 1 : 0
  security_group_id = aws_security_group.sdg[0].id
  description       = "Allow MSK outbound"
  ip_protocol       = "tcp"
  from_port         = 9098
  to_port           = 9098
  cidr_ipv4         = data.aws_vpc.shared.cidr_block
}

resource "aws_security_group" "alerts" {
  #checkov:skip=CKV2_AWS_5: Security group is attached to the alerts ECS service network configuration; Checkov cannot infer attachment through counted/dynamic references.
  count       = contains(local.deploy_to, local.environment) ? 1 : 0
  name_prefix = local.alerts_prefix
  vpc_id      = data.aws_vpc.shared.id
  description = "${local.alerts_prefix} SG"

  tags = merge(local.extended_tags, { Name = local.alerts_prefix })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_egress_rule" "alerts_https_out" {
  count             = contains(local.deploy_to, local.environment) ? 1 : 0
  security_group_id = aws_security_group.alerts[0].id
  description       = "Allow HTTPS outbound for ECR, SNS and AWS API calls"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "alerts_msk_out" {
  count             = contains(local.deploy_to, local.environment) ? 1 : 0
  security_group_id = aws_security_group.alerts[0].id
  description       = "Allow MSK outbound"
  ip_protocol       = "tcp"
  from_port         = 9098
  to_port           = 9098
  cidr_ipv4         = data.aws_vpc.shared.cidr_block
}

resource "aws_security_group" "kafka_ui" {
  #checkov:skip=CKV2_AWS_5: Security group is attached to the kafka-ui ECS service network configuration; Checkov cannot infer attachment through counted/dynamic references.
  count       = contains(local.deploy_to, local.environment) ? 1 : 0
  name_prefix = local.kafka_ui_prefix
  vpc_id      = data.aws_vpc.shared.id
  description = "${local.kafka_ui_prefix} SG"

  tags = merge(local.extended_tags, { Name = local.alerts_prefix })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_egress_rule" "kafka_ui_msk_out" {
  count             = contains(local.deploy_to, local.environment) ? 1 : 0
  security_group_id = aws_security_group.kafka_ui[0].id
  description       = "Allow MSK outbound"
  ip_protocol       = "tcp"
  from_port         = 9098
  to_port           = 9098
  cidr_ipv4         = data.aws_vpc.shared.cidr_block
}

resource "aws_vpc_security_group_ingress_rule" "kafka_ui_ingress" {
  count             = contains(local.deploy_to, local.environment) ? 1 : 0
  security_group_id = aws_security_group.kafka_ui[0].id
  description       = "Inbound to kafka-ui"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = data.aws_vpc.shared.cidr_block
}

# --- Synthetic Data Generator ---

module "ecs_container_sdg" {
  count  = contains(local.deploy_to, local.environment) ? 1 : 0
  source = "git::https://github.com/ministryofjustice/modernisation-platform-terraform-ecs-cluster//container?ref=697b010957fabc36b7f648bc535021231f748674" # v6.0.2

  name                     = local.sdg_prefix
  image                    = "${aws_ecr_repository.repository["sdg"].repository_url}:latest"
  essential                = true
  readonly_root_filesystem = false
  port_mappings            = []
  secrets                  = []
  environment = [
    {
      name  = "ENVIRONMENT"
      value = substr(lower(local.environment), 0, 3)
    },
    {
      name  = "KAFKA_BROKER"
      value = local.msk_bootstrap_brokers
    }
  ]
  log_configuration = {
    logDriver = "awslogs"
    options = {
      "awslogs-group"         = "/ecs/${local.sdg_prefix}"
      "awslogs-region"        = data.aws_region.current.region
      "awslogs-stream-prefix" = "ecs"
    }
  }
}

module "ecs_service_sdg" {
  count  = contains(local.deploy_to, local.environment) ? 1 : 0
  source = "git::https://github.com/ministryofjustice/modernisation-platform-terraform-ecs-cluster//service?ref=697b010957fabc36b7f648bc535021231f748674" # v6.0.2

  name        = local.sdg_prefix
  cluster_arn = module.ecs_cluster[0].ecs_cluster_arn

  container_definitions = module.ecs_container_sdg[0].json_encoded_list

  subnets         = data.aws_subnets.shared-private.ids
  security_groups = [aws_security_group.sdg[0].id]

  service_role_arn   = aws_iam_role.sdg_task[0].arn
  task_role_arn      = aws_iam_role.sdg_task[0].arn
  task_exec_role_arn = aws_iam_role.sdg_task_exec[0].arn

  capacity_provider      = local.capacity_provider
  enable_execute_command = true

  service_load_balancers = []

  deployment_circuit_breaker = {
    enable   = true
    rollback = true
  }

  tags = local.extended_tags
}

resource "aws_cloudwatch_log_group" "sdg" {
  count             = contains(local.deploy_to, local.environment) ? 1 : 0
  name              = "/ecs/${local.sdg_prefix}"
  retention_in_days = 365
  kms_key_id        = aws_kms_key.ecs_cloudwatch[0].arn
  tags              = local.extended_tags
}

# --- Alerts Service ---

module "ecs_container_alerts" {
  count  = contains(local.deploy_to, local.environment) ? 1 : 0
  source = "git::https://github.com/ministryofjustice/modernisation-platform-terraform-ecs-cluster//container?ref=697b010957fabc36b7f648bc535021231f748674" # v6.0.2

  name                     = local.alerts_prefix
  image                    = "${aws_ecr_repository.repository["alerts"].repository_url}:latest"
  essential                = true
  readonly_root_filesystem = true
  port_mappings            = []
  secrets                  = []
  environment = [
    {
      name  = "ENVIRONMENT"
      value = substr(lower(local.environment), 0, 3)
    },
    {
      name  = "SPRING_PROFILES_ACTIVE"
      value = substr(lower(local.environment), 0, 3)
    },
    {
      name  = "MOJ-DRONE-INCURSION-ARN"
      value = data.aws_sns_topic.drone_incursion_topic["topic"].arn
    }
  ]
  log_configuration = {
    logDriver = "awslogs"
    options = {
      "awslogs-group"         = "/ecs/${local.alerts_prefix}"
      "awslogs-region"        = data.aws_region.current.region
      "awslogs-stream-prefix" = "ecs"
    }
  }
}

module "ecs_service_alerts" {
  count  = contains(local.deploy_to, local.environment) ? 1 : 0
  source = "git::https://github.com/ministryofjustice/modernisation-platform-terraform-ecs-cluster//service?ref=697b010957fabc36b7f648bc535021231f748674" # v6.0.2

  name        = local.alerts_prefix
  cluster_arn = module.ecs_cluster[0].ecs_cluster_arn

  container_definitions = module.ecs_container_alerts[0].json_encoded_list

  subnets         = data.aws_subnets.shared-private.ids
  security_groups = [aws_security_group.alerts[0].id]

  service_role_arn   = aws_iam_role.alerts_task[0].arn
  task_role_arn      = aws_iam_role.alerts_task[0].arn
  task_exec_role_arn = aws_iam_role.alerts_task_exec[0].arn

  capacity_provider = local.capacity_provider

  service_load_balancers = []

  deployment_circuit_breaker = {
    enable   = true
    rollback = true
  }

  tags = local.extended_tags
}

resource "aws_cloudwatch_log_group" "alerts" {
  count             = contains(local.deploy_to, local.environment) ? 1 : 0
  name              = "/ecs/${local.alerts_prefix}"
  retention_in_days = 365
  kms_key_id        = aws_kms_key.ecs_cloudwatch[0].arn
  tags              = local.extended_tags
}

# --- Kafka-ui Service ---

module "ecs_container_kafka_ui" {
  count  = contains(local.deploy_to, local.environment) ? 1 : 0
  source = "git::https://github.com/ministryofjustice/modernisation-platform-terraform-ecs-cluster//container?ref=697b010957fabc36b7f648bc535021231f748674" # v6.0.2

  name                     = local.kafka_ui_prefix
  image                    = "provectuslabs/kafka-ui:latest"
  essential                = true
  readonly_root_filesystem = true
  port_mappings            = []
  secrets                  = []
  environment = [
    {
      name  = "KAFKA_CLUSTERS_0_NAME"
      value = module.ecs_cluster[0].ecs_cluster_name
    },
    {
      name  = "KAFKA_CLUSTERS_0_BOOTSTRAPSERVERS"
      value = local.msk_bootstrap_brokers
    },
    {
      name  = "KAFKA_CLUSTERS_0_PROPERTIES_SECURITY_PROTOCOL"
      value = "SASL_SSL"
    },
    {
      name  = "KAFKA_CLUSTERS_0_PROPERTIES_SASL_MECHANISM"
      value = "AWS_MSK_IAM"
    },
    {
      name  = "KAFKA_CLUSTERS_0_PROPERTIES_SASL_JAAS_CONFIG"
      value = "software.amazon.msk.auth.iam.IAMLoginModule required;"
    },
    {
      name  = "KAFKA_CLUSTERS_0_PROPERTIES_SASL_CLIENT_CALLBACK_HANDLER_CLASS"
      value = "software.amazon.msk.auth.iam.IAMClientCallbackHandler"
    },
    {
      name  = "LOGGING_LEVEL_ROOT"
      value = "INFO"
    }
  ]
  log_configuration = {
    logDriver = "awslogs"
    options = {
      "awslogs-group"         = "/ecs/${local.kafka_ui_prefix}"
      "awslogs-region"        = data.aws_region.current.region
      "awslogs-stream-prefix" = "ecs"
    }
  }
}

module "ecs_service_kafka_ui" {
  count  = contains(local.deploy_to, local.environment) ? 1 : 0
  source = "git::https://github.com/ministryofjustice/modernisation-platform-terraform-ecs-cluster//service?ref=697b010957fabc36b7f648bc535021231f748674" # v6.0.2

  name        = local.kafka_ui_prefix
  cluster_arn = module.ecs_cluster[0].ecs_cluster_arn

  container_definitions = module.ecs_container_kafka_ui[0].json_encoded_list

  subnets         = data.aws_subnets.shared-private.ids
  security_groups = [aws_security_group.kafka_ui[0].id]

  service_role_arn   = aws_iam_role.kafka_ui_task[0].arn
  task_role_arn      = aws_iam_role.kafka_ui_task[0].arn
  task_exec_role_arn = aws_iam_role.kafka_ui_task_exec[0].arn

  capacity_provider = local.capacity_provider

  service_load_balancers = []

  deployment_circuit_breaker = {
    enable   = true
    rollback = true
  }

  tags = local.extended_tags
}

resource "aws_cloudwatch_log_group" "kafka_ui" {
  count             = contains(local.deploy_to, local.environment) ? 1 : 0
  name              = "/ecs/${local.kafka_ui_prefix}"
  retention_in_days = 365
  kms_key_id        = aws_kms_key.ecs_cloudwatch[0].arn
  tags              = local.extended_tags
}
