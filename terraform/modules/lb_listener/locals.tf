locals {
  target_group_attachments = flatten([
    for target_group_name, target_group_value in var.target_groups : [
      for attachment_value in target_group_value.attachments : {
        name       = target_group_name
        attachment = attachment_value
      }
    ]
  ])

  target_groups = merge(var.existing_target_groups, aws_lb_target_group.this)
}
