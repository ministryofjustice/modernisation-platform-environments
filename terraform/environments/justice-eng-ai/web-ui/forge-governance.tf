# Stage 3: provision the formal assessment dependency before the enforced Forge
# image rolls out. Enabling infrastructure is not a switch to bypass governance.
variable "forge_governance_enabled" {
  type        = bool
  default     = false
  description = "Provision the private governance API and inject its settings into Forge. Enable only after publishing the reviewed API image."
}

variable "forge_governance_image" {
  type        = string
  default     = ""
  description = "Immutable ECR image URI ending @sha256:<digest>, built from governance/Dockerfile in the application-builder Stage 2 PR."
  validation {
    condition     = var.forge_governance_image == "" || can(regex("^[0-9]{12}\\.dkr\\.ecr\\.[a-z0-9-]+\\.amazonaws\\.com/[^@]+@sha256:[a-f0-9]{64}$", var.forge_governance_image))
    error_message = "Supply an immutable private ECR image URI with a SHA256 digest."
  }
}

locals {
  forge_governance          = local.forge_internal && var.forge_governance_enabled
  forge_governance_hostname = "governance.${local.hosted_zone_name}"
  forge_governance_environment = local.forge_governance ? [
    { name = "GOVERNANCE_API_URL", value = "https://${local.forge_governance_hostname}/" },
    { name = "FORGE_GOVERNANCE_ENABLED", value = "true" },
    { name = "FORGE_GOVERNANCE_MODE", value = "approved-patterns" },
  ] : []
  forge_governance_secrets = local.forge_governance ? [
    { name = "GOVERNANCE_SERVICE_TOKEN", valueFrom = aws_secretsmanager_secret.forge_governance[0].arn },
  ] : []
}

resource "random_password" "forge_governance" {
  count   = local.forge_governance ? 1 : 0
  length  = 64
  special = false
}

resource "aws_secretsmanager_secret" "forge_governance" {
  count                   = local.forge_governance ? 1 : 0
  name                    = "${local.forge_secret_path_prefix}/governance-service-token"
  recovery_window_in_days = 7
  tags                    = local.tags
}

resource "aws_secretsmanager_secret_version" "forge_governance" {
  count         = local.forge_governance ? 1 : 0
  secret_id     = aws_secretsmanager_secret.forge_governance[0].id
  secret_string = random_password.forge_governance[0].result
}

# The ECS agent reuses Forge's execution role to pull from shared ECR and inject
# the same token. The API's separate task role gets only the existing Bedrock policy.
resource "aws_iam_role" "forge_governance_task" {
  count              = local.forge_governance ? 1 : 0
  name               = "forge-governance-task"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role.json
  tags               = local.tags
}

resource "aws_iam_role_policy_attachment" "forge_governance_bedrock" {
  count      = local.forge_governance ? 1 : 0
  role       = aws_iam_role.forge_governance_task[0].name
  policy_arn = aws_iam_policy.bedrock_runtime.arn
}

resource "aws_security_group" "forge_governance_lb" {
  count       = local.forge_governance ? 1 : 0
  name_prefix = "forge-governance-lb-"
  description = "Private governance HTTPS listener; only Forge tasks can connect"
  vpc_id      = data.aws_vpc.shared.id
  tags        = local.tags
}

resource "aws_security_group" "forge_governance_api" {
  count       = local.forge_governance ? 1 : 0
  name_prefix = "forge-governance-api-"
  description = "Private governance API; accepts traffic only from its internal ALB"
  vpc_id      = data.aws_vpc.shared.id
  tags        = local.tags
}

resource "aws_vpc_security_group_ingress_rule" "forge_to_governance" {
  count                        = local.forge_governance ? 1 : 0
  security_group_id            = aws_security_group.forge_governance_lb[0].id
  referenced_security_group_id = aws_security_group.forge_ecs_service[0].id
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "governance_lb_to_api" {
  count                        = local.forge_governance ? 1 : 0
  security_group_id            = aws_security_group.forge_governance_lb[0].id
  referenced_security_group_id = aws_security_group.forge_governance_api[0].id
  from_port                    = 8001
  to_port                      = 8001
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "governance_api_from_lb" {
  count                        = local.forge_governance ? 1 : 0
  security_group_id            = aws_security_group.forge_governance_api[0].id
  referenced_security_group_id = aws_security_group.forge_governance_lb[0].id
  from_port                    = 8001
  to_port                      = 8001
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "governance_api_https" {
  count             = local.forge_governance ? 1 : 0
  security_group_id = aws_security_group.forge_governance_api[0].id
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_acm_certificate" "forge_governance" {
  count             = local.forge_governance ? 1 : 0
  domain_name       = local.forge_governance_hostname
  validation_method = "DNS"
  tags              = local.tags
  lifecycle { create_before_destroy = true }
}

resource "aws_route53_record" "forge_governance_validation" {
  for_each = local.forge_governance ? { for item in aws_acm_certificate.forge_governance[0].domain_validation_options : item.domain_name => item } : {}
  zone_id  = aws_route53_zone.app.zone_id
  name     = each.value.resource_record_name
  type     = each.value.resource_record_type
  ttl      = 60
  records  = [each.value.resource_record_value]
}

resource "aws_acm_certificate_validation" "forge_governance" {
  count                   = local.forge_governance ? 1 : 0
  certificate_arn         = aws_acm_certificate.forge_governance[0].arn
  validation_record_fqdns = [for record in aws_route53_record.forge_governance_validation : record.fqdn]
}

resource "aws_lb" "forge_governance" {
  count                      = local.forge_governance ? 1 : 0
  name                       = "forge-governance"
  internal                   = true
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.forge_governance_lb[0].id]
  subnets                    = local.private_subnet_ids
  drop_invalid_header_fields = true
  idle_timeout               = 120
  enable_deletion_protection = true
  tags                       = local.tags
}

resource "aws_lb_target_group" "forge_governance" {
  count       = local.forge_governance ? 1 : 0
  name        = "forge-governance"
  port        = 8001
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = data.aws_vpc.shared.id
  health_check {
    path    = "/healthz"
    matcher = "200"
  }
  tags = local.tags
}

resource "aws_lb_listener" "forge_governance" {
  count             = local.forge_governance ? 1 : 0
  load_balancer_arn = aws_lb.forge_governance[0].arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate_validation.forge_governance[0].certificate_arn
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.forge_governance[0].arn
  }
  tags = local.tags
}

resource "aws_route53_record" "forge_governance" {
  count   = local.forge_governance ? 1 : 0
  zone_id = aws_route53_zone.app.zone_id
  name    = local.forge_governance_hostname
  type    = "A"
  alias {
    name                   = aws_lb.forge_governance[0].dns_name
    zone_id                = aws_lb.forge_governance[0].zone_id
    evaluate_target_health = true
  }
}

resource "aws_cloudwatch_log_group" "forge_governance" {
  count             = local.forge_governance ? 1 : 0
  name              = "/ecs/forge-governance"
  retention_in_days = 30
  tags              = local.tags
}

resource "aws_ecs_task_definition" "forge_governance" {
  count                    = local.forge_governance ? 1 : 0
  family                   = "forge-governance"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.forge_ecs_task_execution[0].arn
  task_role_arn            = aws_iam_role.forge_governance_task[0].arn
  container_definitions = jsonencode([{
    name                   = "governance"
    image                  = var.forge_governance_image
    essential              = true
    readonlyRootFilesystem = true
    user                   = "1000:1000"
    portMappings           = [{ containerPort = 8001, hostPort = 8001, protocol = "tcp" }]
    environment = [
      { name = "AI_EVALUATOR", value = "bedrock" },
      { name = "AWS_REGION", value = data.aws_region.current.region },
      { name = "BEDROCK_MODEL_ID", value = var.bedrock_model_id },
      { name = "BEDROCK_MAX_TOKENS", value = "512" },
      { name = "TMPDIR", value = "/scratch" },
    ]
    secrets          = [{ name = "GOVERNANCE_SERVICE_TOKEN", valueFrom = aws_secretsmanager_secret.forge_governance[0].arn }]
    healthCheck      = { command = ["CMD-SHELL", "python -c \"import urllib.request; urllib.request.urlopen('http://127.0.0.1:8001/healthz',timeout=3)\""], interval = 30, timeout = 5, retries = 3, startPeriod = 15 }
    mountPoints      = [{ sourceVolume = "scratch", containerPath = "/scratch", readOnly = false }]
    logConfiguration = { logDriver = "awslogs", options = { awslogs-group = aws_cloudwatch_log_group.forge_governance[0].name, awslogs-region = data.aws_region.current.region, awslogs-stream-prefix = "governance" } }
  }])
  volume { name = "scratch" }
  lifecycle {
    precondition {
      condition     = var.forge_governance_image != ""
      error_message = "Publish the reviewed governance API image and supply its immutable digest before enabling infrastructure."
    }
  }
  tags = local.tags
}

resource "aws_ecs_service" "forge_governance" {
  count           = local.forge_governance ? 1 : 0
  name            = "forge-governance"
  cluster         = aws_ecs_cluster.app.id
  task_definition = aws_ecs_task_definition.forge_governance[0].arn
  desired_count   = 1
  launch_type     = "FARGATE"
  network_configuration {
    assign_public_ip = false
    security_groups  = [aws_security_group.forge_governance_api[0].id]
    subnets          = local.private_subnet_ids
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.forge_governance[0].arn
    container_name   = "governance"
    container_port   = 8001
  }
  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }
  depends_on = [aws_lb_listener.forge_governance, aws_secretsmanager_secret_version.forge_governance, aws_iam_role_policy.forge_ecs_task_execution_secrets, aws_iam_role_policy_attachment.forge_governance_bedrock]
  tags       = local.tags
}

output "forge_governance_url" {
  value       = local.forge_governance ? "https://${local.forge_governance_hostname}/" : ""
  description = "Private assessment endpoint for Forge. No token value is exposed."
}
