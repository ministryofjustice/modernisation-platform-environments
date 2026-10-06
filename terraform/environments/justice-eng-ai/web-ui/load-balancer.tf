resource "aws_lb" "app" {
  # checkov:skip=CKV2_AWS_76:No WAFv2 ACL attached yet for this prototype
  # migration; revisit before production go-live.
  # checkov:skip=CKV_AWS_150:Deletion protection deliberately disabled so
  # ``terraform destroy`` can tear the prototype down cleanly. Re-enable
  # before promoting to a long-lived environment.
  # checkov:skip=CKV_AWS_91:Access logging deliberately off for the prototype;
  # Cloudflare-style access analytics are unnecessary for internal MoJ SSO
  # traffic and the S3 log bucket + lifecycle would be extra unused infra.
  name                       = local.application_resource_name
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.alb.id]
  subnets                    = data.terraform_remote_state.justice_eng_ai.outputs.public_subnets
  drop_invalid_header_fields = true
  idle_timeout               = 120
  tags                       = local.tags
}

resource "aws_lb_target_group" "app" {
  name                 = local.application_resource_name
  port                 = var.app_container_port
  protocol             = "HTTP"
  target_type          = "ip"
  vpc_id               = data.terraform_remote_state.justice_eng_ai.outputs.vpc_id
  deregistration_delay = 30
  tags                 = local.tags

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/healthz"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 3
  }
}

# Plain HTTP is redirect-only -- browsers never get a response from the
# target group over port 80.
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app.arn
  port              = 80
  protocol          = "HTTP"
  tags              = local.tags

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.app.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate_validation.site_eu_west_2.certificate_arn
  tags              = local.tags

  # When ``oidc_configured = true`` the listener runs the Entra OIDC flow
  # first (order 1) and then forwards to the target group (order 2). When
  # false, it forwards directly.
  dynamic "default_action" {
    for_each = local.oidc_wired ? [1] : []
    content {
      type  = "authenticate-oidc"
      order = 1
      authenticate_oidc {
        issuer                     = "https://login.microsoftonline.com/${data.aws_secretsmanager_secret_version.entra_oidc_tenant_id[0].secret_string}/v2.0"
        authorization_endpoint     = "https://login.microsoftonline.com/${data.aws_secretsmanager_secret_version.entra_oidc_tenant_id[0].secret_string}/oauth2/v2.0/authorize"
        token_endpoint             = "https://login.microsoftonline.com/${data.aws_secretsmanager_secret_version.entra_oidc_tenant_id[0].secret_string}/oauth2/v2.0/token"
        user_info_endpoint         = "https://graph.microsoft.com/oidc/userinfo"
        client_id                  = data.aws_secretsmanager_secret_version.entra_oidc_client_id[0].secret_string
        client_secret              = data.aws_secretsmanager_secret_version.entra_oidc_client_secret[0].secret_string
        scope                      = "openid email profile"
        session_timeout            = 43200 # 12 hours
        on_unauthenticated_request = "authenticate"
      }
    }
  }

  default_action {
    type             = "forward"
    order            = local.oidc_wired ? 2 : 1
    target_group_arn = aws_lb_target_group.app.arn
  }
}

# ``/healthz`` bypasses OIDC so external monitors (and curl-based debugging)
# can reach the health endpoint without a full OAuth round-trip. Target-
# group health checks already bypass the listener (ALB -> target on the
# traffic port), so this rule exists purely for external HTTPS callers.
# Only present when OIDC is wired -- without it the default action already
# forwards plainly.
resource "aws_lb_listener_rule" "healthz_bypass" {
  count        = local.oidc_wired_count
  listener_arn = aws_lb_listener.https.arn
  priority     = 100
  tags         = local.tags

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }

  condition {
    path_pattern {
      values = ["/healthz"]
    }
  }
}
