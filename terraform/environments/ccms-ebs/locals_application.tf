locals {    
  webgate_autoscaling_groups = {
    autoscaling_group = {
    desired_capacity = 1
    max_size         = 1
    min_size         = 0
    force_delete     = true
    warm_pool        = null
    }
  }
}