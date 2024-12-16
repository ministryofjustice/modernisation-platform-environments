# automatically add ebs performance widgets here

locals {

  widget_groups_ec2_keys = [
    for i in range(length(var.widget_groups)) : try(var.widget_groups[i].search_filter, null) == null ? [
      for ec2_key, ec2_value in var.ec2_instances : ec2_key
      ] : [
      for ec2_key, ec2_value in var.ec2_instances : ec2_key if contains(local.widget_groups_search_filter_ec2_ids[i], ec2_value.aws_instance.id)
    ]
  ]

  widget_groups_ebs_iops = [
    for i in range(length(var.widget_groups)) : distinct(flatten([
      for ec2_key in local.widget_groups_ec2_keys[i] : [
        for ebs_key, ebs_value in var.ec2_instances[ec2_key].aws_ebs_volume : ebs_value.iops if try(var.widget_groups[i].add_ebs_widgets.iops, false)
      ]
    ]))
  ]

  widget_groups_ebs_throughput = [
    for i in range(length(var.widget_groups)) : distinct(flatten([
      for ec2_key in local.widget_groups_ec2_keys[i] : [
        for ebs_key, ebs_value in var.ec2_instances[ec2_key].aws_ebs_volume : ebs_value.throughput if try(var.widget_groups[i].add_ebs_widgets.throughput, false)
      ]
    ]))
  ]

  widget_groups_ebs_volumes = [
    for i in range(length(var.widget_groups)) : distinct(flatten([
      for ec2_key in local.widget_groups_ec2_keys[i] : [
        for ebs_key, ebs_value in var.ec2_instances[ec2_key].aws_ebs_volume : merge(ebs_value, {
          metric_id   = join("_", ["vol", split("-", ebs_value.id)[1]])
          metric_id_r = join("_", ["vol", split("-", ebs_value.id)[1], "r"])
          metric_id_w = join("_", ["vol", split("-", ebs_value.id)[1], "w"])
        })
      ]
    ]))
  ]

  widget_groups_ebs_widgets_iops = [
    for i in range(length(var.widget_groups)) : [
      for iops in local.widget_groups_ebs_iops[i] : {
        type            = "metric"
        alarm_threshold = iops
        properties = {
          view   = "timeSeries"
          period = 60
          region = "eu-west-2"
          stat   = "Sum"
          title  = "EBS ${iops} iops"
          metrics = concat([
            for ebs_value in local.widget_groups_ebs_volumes[i] : [
              [{
                expression = "${ebs_value.metric_id_r}/PERIOD(${ebs_value.metric_id_r})+${ebs_value.metric_id_w}/PERIOD(${ebs_value.metric_id_w})"
                id         = ebs_value.metric_id
                label      = "${ebs_value.id} ${ebs_value.tags.Name}"
                region     = "eu-west-2"
              }],
              ["AWS/EBS", "VolumeReadOps", "VolumeId", ebs_value.id, {
                id      = ebs_value.metric_id_r
                period  = 60
                region  = "eu-west-2"
                stat    = "Sum"
                visible = false
              }],
              ["AWS/EBS", "VolumeWriteOps", "VolumeId", ebs_value.id, {
                id      = ebs_value.metric_id_w
                period  = 60
                region  = "eu-west-2"
                stat    = "Sum"
                visible = false
              }]
            ] if ebs_value.iops == iops
          ]...)
          yAxis = {
            left = {
              showUnits = false,
              label     = "iops/s"
            }
          }
        }
      }
    ]
  ]

  widget_groups_ebs_widgets_throughput = [
    for i in range(length(var.widget_groups)) : [
      for throughput in local.widget_groups_ebs_throughput[i] : {
        type            = "metric"
        alarm_threshold = throughput
        properties = {
          view   = "timeSeries"
          period = 60
          region = "eu-west-2"
          stat   = "Sum"
          title  = "EBS ${throughput} throughput"
          metrics = concat([
            for ebs_value in local.widget_groups_ebs_volumes[i] : [
              [{
                expression = "(${ebs_value.metric_id_r}/PERIOD(${ebs_value.metric_id_r})+${ebs_value.metric_id_w}/PERIOD(${ebs_value.metric_id_r}))/1048576"
                id         = ebs_value.metric_id
                label      = "${ebs_value.id} ${ebs_value.tags.Name}"
                region     = "eu-west-2"
              }],
              ["AWS/EBS", "VolumeReadBytes", "VolumeId", ebs_value.id, {
                id      = ebs_value.metric_id_r
                period  = 60
                region  = "eu-west-2"
                stat    = "Sum"
                visible = false
              }],
              ["AWS/EBS", "VolumeWriteBytes", "VolumeId", ebs_value.id, {
                id      = ebs_value.metric_id_w
                period  = 60
                region  = "eu-west-2"
                stat    = "Sum"
                visible = false
              }]
            ] if ebs_value.throughput == throughput
          ]...)
          yAxis = {
            left = {
              showUnits = false,
              label     = "MiB/s"
            }
          }
        }
      }
    ]
  ]
}
