locals {
  # flatten instance target_groups
  instance_target_group_list = flatten([
    for lb_key, lb_value in var.lbs : [
      for tg_key, tg_value in lb_value.instance_target_groups : {
        key   = tg_key
        value = tg_value
      }
    ]
  ])
  instance_target_groups = {
    for item in local.instance_target_group_list : item.key => item.value
  }

  # flatten instance target_groups attachments
  instance_target_group_attachment_list = flatten([
    for lb_key, lb_value in var.lbs : [
      for tg_key, tg_value in lb_value.instance_target_groups : [
        for attachment in tg_value.attachments : {
          key = "${lb_key}-${tg_key}-${attachment.ec2_instance_name}"
          value = merge(attachment, {
            target_group_key = tg_key
          })
        }
      ]
    ]
  ])
  instance_target_group_attachments = {
    for item in local.instance_target_group_attachment_list : item.key => item.value
  }

  # flatten the load balancer listeners
  lb_listener_list = flatten([
    for lb_key, lb_value in var.lbs : [
      for listener_key, listener_value in lb_value.listeners : {
        key = "${lb_key}-${listener_key}"
        value = merge(listener_value, {
          lb_application_name = lb_key
        })
      }
    ]
  ])
  lb_listeners = {
    for item in local.lb_listener_list : item.key => item.value
  }

  lb_target_groups_list = flatten([
    for lb_key, lb_value in module.lb : [
      for tg_key, tg_value in lb_value.lb_target_groups : [{
        key   = tg_key
        value = tg_value
      }]
    ]
  ])
  lb_target_groups = {
    for item in local.lb_target_groups_list : item.key => item.value
  }
}

resource "aws_lb_target_group" "instance" {
  for_each = local.instance_target_groups

  name                 = each.key
  port                 = each.value.port
  protocol             = each.value.protocol
  target_type          = "instance"
  deregistration_delay = each.value.deregistration_delay
  vpc_id               = var.environment.vpc.id

  dynamic "health_check" {
    for_each = each.value.health_check != null ? [each.value.health_check] : []
    content {
      enabled             = health_check.value.enabled
      interval            = health_check.value.interval
      healthy_threshold   = health_check.value.healthy_threshold
      matcher             = health_check.value.matcher
      path                = health_check.value.path
      port                = health_check.value.port
      protocol            = health_check.value.protocol
      timeout             = health_check.value.timeout
      unhealthy_threshold = health_check.value.unhealthy_threshold
    }
  }
  dynamic "stickiness" {
    for_each = each.value.stickiness != null ? [each.value.stickiness] : []
    content {
      enabled         = stickiness.value.enabled
      type            = stickiness.value.type
      cookie_duration = stickiness.value.cookie_duration
      cookie_name     = stickiness.value.cookie_name
    }
  }

  tags = merge(var.tags, {
    Name = each.key
  })
}

resource "aws_lb_target_group_attachment" "instance" {
  for_each = local.instance_target_group_attachments

  target_group_arn = aws_lb_target_group.instance[each.value.target_group_key].arn
  target_id        = module.ec2_instance[each.value.ec2_instance_name].aws_instance.id
  port             = each.value.port
}

# following AWS terraform naming convention here aws_lb, aws_lb_listener, so lbs.tf and lb_listeners.tf.
module "lb" {
  #checkov:skip=CKV_TF_1:Ensure Terraform module sources use a commit hash; skip as this is MoJ Repo

  for_each = var.lbs

  source = "git::https://github.com/ministryofjustice/modernisation-platform-terraform-loadbalancer.git?ref=v5.0.2"

  providers = {
    aws.bucket-replication = aws
  }

  account_number                   = var.environment.account_id
  application_name                 = each.key
  drop_invalid_header_fields       = each.value.drop_invalid_header_fields
  enable_deletion_protection       = each.value.enable_delete_protection
  force_destroy_bucket             = each.value.force_destroy_bucket
  idle_timeout                     = each.value.idle_timeout
  internal_lb                      = each.value.internal_lb
  load_balancer_type               = each.value.load_balancer_type
  lb_target_groups                 = each.value.lb_target_groups
  access_logs                      = each.value.access_logs
  enable_cross_zone_load_balancing = each.value.enable_cross_zone_load_balancing
  dns_record_client_routing_policy = each.value.dns_record_client_routing_policy
  s3_versioning                    = each.value.s3_versioning
  access_logs_lifecycle_rule       = each.value.access_logs_lifecycle_rule

  existing_bucket_name = try(module.s3_bucket[each.value.existing_bucket_name].bucket.id, each.value.existing_bucket_name)

  s3_notification_queues = {
    for k, v in each.value.s3_notification_queues : k => merge(v, {
      queue_arn = try(aws_sqs_queue.this[v.queue_arn].arn, v.queue_arn),
    })
  }

  security_groups = [
    for sg in each.value.security_groups : lookup(aws_security_group.this, sg, null) != null ? aws_security_group.this[sg].id : sg
  ]

  subnets = each.value.subnets
  region  = var.environment.region
  vpc_all = var.environment.vpc_name
  tags    = merge(local.tags, each.value.tags)

  depends_on = [
    module.ec2_autoscaling_group, # ensure ASG target groups are created first
  ]
}

module "lb_listener" {
  for_each = local.lb_listeners

  source = "../../modules/lb_listener"

  name          = each.key
  business_unit = var.environment.business_unit
  environment   = var.environment.environment
  load_balancer = module.lb[each.value.lb_application_name].load_balancer

  existing_target_groups = merge(
    local.asg_target_groups,
    local.lb_target_groups,
    aws_lb_target_group.instance,
    var.lbs[each.value.lb_application_name].existing_target_groups,
  )

  port                      = each.value.port
  protocol                  = each.value.protocol
  ssl_policy                = each.value.ssl_policy
  certificate_arn_lookup    = { for key, value in module.acm_certificate : key => value.arn }
  certificate_names_or_arns = each.value.certificate_names_or_arns
  default_action            = each.value.default_action
  rules                     = each.value.rules
  alarm_target_group_names  = each.value.alarm_target_group_names

  cloudwatch_metric_alarms = {
    for key, value in each.value.cloudwatch_metric_alarms : key => merge(value, {
      alarm_actions = [
        for item in value.alarm_actions : try(aws_sns_topic.this[item].arn, item)
      ]
      ok_actions = [
        for item in value.ok_actions : try(aws_sns_topic.this[item].arn, item)
      ]
    })
  }

  depends_on = [
    module.acm_certificate, # ensure certs are created first
  ]
  tags = merge(local.tags, each.value.tags)
}
