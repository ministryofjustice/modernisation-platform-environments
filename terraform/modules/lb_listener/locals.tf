locals {
  aws_lb = var.load_balancer_arn != null ? data.aws_lb.this[0] : var.load_balancer

  target_group_attachments = flatten([
    for target_group_name, target_group_value in var.target_groups : [
      for attachment_value in target_group_value.attachments : {
        name       = target_group_name
        attachment = attachment_value
      }
    ]
  ])

  target_groups = merge(var.existing_target_groups, aws_lb_target_group.this)

  #  target_group_arn = merge(flatten([
  #    for key, value in aws_lb_listener.this : [
  #      for key, value in aws_lb_listener.this.default_action : {
  #        arn_suffix = value.target_group_arn != "" ? (regex("[^:]*$", value.target_group_arn)) : null
  #      }
  #    ]
  #  ])...)
}
