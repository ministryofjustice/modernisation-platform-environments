resource "aws_lb_target_group" "internal_airflow_mwaa" {
  count = local.create_internal_airflow ? 1 : 0
  name_prefix = "iaf-"
  port        = 443
  protocol    = "HTTPS"
  target_type = "ip"
  vpc_id      = data.aws_vpc.apc_vpc.id

  health_check {
    enabled  = true
    path     = "/"
    port     = "traffic-port"
    protocol = "HTTPS"
    matcher  = "200,302"
  }

  tags = local.tags
}

resource "aws_lb_listener_rule" "internal_airflow_host" {
  count        = local.create_internal_airflow ? 1 : 0
  listener_arn = data.aws_lb_listener.mwaa_https.arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.internal_airflow_mwaa[0].arn
  }

  condition {
    host_header {
      values = ["internal-airflow.${local.environment_configuration.route53_zone}"]
    }
  }
}

resource "aws_lb_target_group_attachment" "internal_airflow_mwaa_webserver" {
  count = local.create_internal_airflow ? length(local.mwaa_private_subnet_ids) : 0

  target_group_arn = aws_lb_target_group.internal_airflow_mwaa[0].arn
  target_id        = data.dns_a_record_set.mwaa_webserver_vpc_endpoint[0].addrs[count.index]
  port             = 443
}
