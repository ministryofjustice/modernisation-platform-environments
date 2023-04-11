locals {
  existing_target_groups_list = [
    for asg_key, asg_value in module.ec2_weblogic_autoscaling_group : [
      for tg_key, tg_value in asg_value.lb_target_groups : {
        key   = "${asg_key}-${tg_key}"
        value = tg_value
      }
    ]
  ]
  existing_target_groups = { for item in flatten(local.existing_target_groups_list) : item.key => item.value }
}
