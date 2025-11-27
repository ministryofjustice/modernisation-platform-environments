#### This file can be used to store locals specific to the member account ####
locals {
  pubkey = {
    "development" = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC3Fq4UnSs9jsFRxG7WV/2g4C4gTaG+7J5p5oi3Eup27MMoNBGTQV64ZETq8Gzx0Dx9R5xnj/y1DT350om2cdcGUYUDu47mOY+VXXtJpzK94R5ZzN+74xjz/swTgJQaOY8iaeSNsILkFMm50xTr7gzSaAswL95RH8h1IibzheqmwkHtN97JEaXkJbhE/CYNPmJzUahNG05vEnBG4op7OG5oLi+7cvZlrnho9lpkWRcOgXaS/mQsMKb45plYCU52reWIZhO9IoxaXULoYybk617I0Blhe2IvYcXfWZGw5xrfJrPJFiiK5fmYGgMp0d1J730kKZ5sOh0Y7Bdf3XXefUIaHlKe95/rXQczw5EeMG+lRt6cOS3XAh4CquyvwY3Oj2HgDLE2JMQS3Y9k8dBpopUCGLvk7MnHMb4SLF4FEoaeJQdv07c6amOQm5Hk0l13TAzlQg+xkyW0y3aluLdAyH6fucbwFiUnAINm9tqem7ZGghWxaC6X9xBUpCDOWPO/3KjpLvPNRrmIgEfSh73o3Jks16Ef3f94XOCM+exO8mTuAYK3F6Uhc2I6xMb3Wp35PBOZbKBEZCeoDvyb841UKHd6LLrgQELEOG+xd3UzM24JMh2FEnbCj3orIw2Zj1B4Udyu2EyV7BLpUhMt/jNt9Jonf1MqVzn9M3JfjUQEjYwVqQ==",
    "test"        = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC3Fq4UnSs9jsFRxG7WV/2g4C4gTaG+7J5p5oi3Eup27MMoNBGTQV64ZETq8Gzx0Dx9R5xnj/y1DT350om2cdcGUYUDu47mOY+VXXtJpzK94R5ZzN+74xjz/swTgJQaOY8iaeSNsILkFMm50xTr7gzSaAswL95RH8h1IibzheqmwkHtN97JEaXkJbhE/CYNPmJzUahNG05vEnBG4op7OG5oLi+7cvZlrnho9lpkWRcOgXaS/mQsMKb45plYCU52reWIZhO9IoxaXULoYybk617I0Blhe2IvYcXfWZGw5xrfJrPJFiiK5fmYGgMp0d1J730kKZ5sOh0Y7Bdf3XXefUIaHlKe95/rXQczw5EeMG+lRt6cOS3XAh4CquyvwY3Oj2HgDLE2JMQS3Y9k8dBpopUCGLvk7MnHMb4SLF4FEoaeJQdv07c6amOQm5Hk0l13TAzlQg+xkyW0y3aluLdAyH6fucbwFiUnAINm9tqem7ZGghWxaC6X9xBUpCDOWPO/3KjpLvPNRrmIgEfSh73o3Jks16Ef3f94XOCM+exO8mTuAYK3F6Uhc2I6xMb3Wp35PBOZbKBEZCeoDvyb841UKHd6LLrgQELEOG+xd3UzM24JMh2FEnbCj3orIw2Zj1B4Udyu2EyV7BLpUhMt/jNt9Jonf1MqVzn9M3JfjUQEjYwVqQ==",
    "production"  = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC3Fq4UnSs9jsFRxG7WV/2g4C4gTaG+7J5p5oi3Eup27MMoNBGTQV64ZETq8Gzx0Dx9R5xnj/y1DT350om2cdcGUYUDu47mOY+VXXtJpzK94R5ZzN+74xjz/swTgJQaOY8iaeSNsILkFMm50xTr7gzSaAswL95RH8h1IibzheqmwkHtN97JEaXkJbhE/CYNPmJzUahNG05vEnBG4op7OG5oLi+7cvZlrnho9lpkWRcOgXaS/mQsMKb45plYCU52reWIZhO9IoxaXULoYybk617I0Blhe2IvYcXfWZGw5xrfJrPJFiiK5fmYGgMp0d1J730kKZ5sOh0Y7Bdf3XXefUIaHlKe95/rXQczw5EeMG+lRt6cOS3XAh4CquyvwY3Oj2HgDLE2JMQS3Y9k8dBpopUCGLvk7MnHMb4SLF4FEoaeJQdv07c6amOQm5Hk0l13TAzlQg+xkyW0y3aluLdAyH6fucbwFiUnAINm9tqem7ZGghWxaC6X9xBUpCDOWPO/3KjpLvPNRrmIgEfSh73o3Jks16Ef3f94XOCM+exO8mTuAYK3F6Uhc2I6xMb3Wp35PBOZbKBEZCeoDvyb841UKHd6LLrgQELEOG+xd3UzM24JMh2FEnbCj3orIw2Zj1B4Udyu2EyV7BLpUhMt/jNt9Jonf1MqVzn9M3JfjUQEjYwVqQ==",
    "database"    = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC22Wv/BpjC1E99lUiysxjfYZIWmJed5/PCq90Wgt76o0uFiCiCqWPJJELTt8gpuu5hWCtOszdDn3xHLoG1aIlETW2aCGq0w7gJyIXT4EsNrMYFfcpdFNWM/gOzjkb8/OJ0TkO3en/6YHbD4mKQ1tT7QKE99QqJzRYoYXHGAOwORhDRFF7uG7klZjJqyDufMWO4PiKBQK1I2+3yKksSrqjArb8KyovlblDksbrV7GuhS/B4nuX+nbc+lendqMiYWkIBHyJK8Tm7TjywMWdGb6MFYQYPYu3vRyHYIxQPomeHr6x+DNzW52LzfoJ27dILzbyZdCV4j/4wlzRsjVttB1ybrmhFazLo1gk/OD+Rn5G8gKMPhvWYbMF9qxySG4uUjc+e9k4t7b/gVbFTLgxsKW1WLwRYaQYhgFAztgOcW7M1fIy1KXLgALUNkwjZIZNJHezb5TulU86q4DQKYRJ9GT2BrLuxGH9YoHmcGswXjmiy9JUSN1zOfddeulMzRYuVk1j7bv2Af2DWY77lsk/Z0vFpX+tLluw/XIjKPdXaBL58bWYW2xhor4E66lQjACe+TyRM/B5nAq4xTHNYFeBlNHovhLTBmmw91NmFc1TB90EKUrf/Xbly8Ivq3V59gybxMO0G9gv3UNtKLVr5DC4/BEIjpVXBaROU9WI/HEzHVT0Lxw=="
  }
  cidr_cica_ss_a        = "10.10.10.0/24"
  cidr_cica_ss_b        = "10.10.110.0/24"
  cidr_cica_dev_a       = "10.11.10.0/24"
  cidr_cica_dev_b       = "10.11.110.0/24"
  cidr_cica_dev_c       = "10.11.20.0/24"
  cidr_cica_dev_d       = "10.11.120.0/24"
  cidr_cica_uat_a       = "10.12.10.0/24"
  cidr_cica_uat_b       = "10.12.110.0/24"
  cidr_cica_uat_c       = "10.12.20.0/24"
  cidr_cica_uat_d       = "10.12.120.0/24"
  cidr_cica_onprem_uat  = "192.168.4.0/24"
  cidr_cica_onprem_prod = "10.2.30.0/24"
  cidr_cica_ras         = "10.9.14.0/23"
  cidr_cica_lan         = "10.7.11.0/24"
  cidr_cica_ras_nat     = "10.7.14.224/28"
  cidr_cica_prod_a      = "10.13.10.0/24"
  cidr_cica_prod_b      = "10.13.110.0/24"
  cidr_cica_prod_c      = "10.13.20.0/24"
  cidr_cica_prod_d      = "10.13.120.0/24"
  cidr_analytics        = local.environment == "test" ? ["10.26.128.19/32"] : local.environment == "production" ? ["10.27.128.28/32"] : [] # Request from Harish on behalf of Siva, connection from Analytics Platform

  #get snapshot IDs for each volume. Required to stop instance replacement on apply
  block_device_mapping_xvde = {
    for mapping in data.aws_ami.shared_ami.block_device_mappings : "0" => mapping
    if mapping.device_name == "xvde"

  }
  snapshot_id_xvde = local.block_device_mapping_xvde[0].ebs.snapshot_id

  block_device_mapping_xvdf = {
    for mapping in data.aws_ami.shared_ami.block_device_mappings : "1" => mapping
    if mapping.device_name == "xvdf"
  }
  snapshot_id_xvdf = local.block_device_mapping_xvdf[1].ebs.snapshot_id

  block_device_mapping_xvdg = {
    for mapping in data.aws_ami.shared_ami.block_device_mappings : "2" => mapping
    if mapping.device_name == "xvdg"
  }
  snapshot_id_xvdg = local.block_device_mapping_xvdg[2].ebs.snapshot_id

  block_device_mapping_xvdh = {
    for mapping in data.aws_ami.shared_ami.block_device_mappings : "3" => mapping
    if mapping.device_name == "xvdh"
  }
  snapshot_id_xvdh = local.block_device_mapping_xvdh[3].ebs.snapshot_id

  block_device_mapping_xvdi = {
    for mapping in data.aws_ami.shared_ami.block_device_mappings : "4" => mapping
    if mapping.device_name == "xvdi"
  }
  snapshot_id_xvdi = local.block_device_mapping_xvdi[4].ebs.snapshot_id

  block_device_mapping_merge = merge(local.block_device_mapping_xvde, local.block_device_mapping_xvdf, local.block_device_mapping_xvdg, local.block_device_mapping_xvdh, local.block_device_mapping_xvdi)
  subnets_a_b                = [data.aws_subnet.data_subnets_a.id, data.aws_subnet.data_subnets_b.id]
  subnets_a_b_map = {
    "subnet_a" = data.aws_subnet.data_subnets_a.id
    "subnet_b" = data.aws_subnet.data_subnets_b.id
  }
  #get snapshot IDs for each volume. Required to stop instance replacement on apply
  block_device_mapping_xvde_db = local.environment == "production" ? {
    for mapping in tolist(data.aws_ami.shared_db_ami)[0].block_device_mappings : "0" => mapping
    if mapping.device_name == "xvde"

  } : {}
  snapshot_id_xvde_db = local.environment == "production" ? local.block_device_mapping_xvde_db[0].ebs.snapshot_id : ""

  block_device_mapping_xvdf_db = local.environment == "production" ? {
    for mapping in tolist(data.aws_ami.shared_db_ami)[0].block_device_mappings : "1" => mapping
    if mapping.device_name == "xvdf"
  } : {}
  snapshot_id_xvdf_db = local.environment == "production" ? local.block_device_mapping_xvdf_db[1].ebs.snapshot_id : ""

  block_device_mapping_xvdg_db = local.environment == "production" ? {
    for mapping in tolist(data.aws_ami.shared_db_ami)[0].block_device_mappings : "2" => mapping
    if mapping.device_name == "xvdg"
  } : {}
  snapshot_id_xvdg_db = local.environment == "production" ? local.block_device_mapping_xvdg_db[2].ebs.snapshot_id : ""

  block_device_mapping_xvdh_db = local.environment == "production" ? {
    for mapping in tolist(data.aws_ami.shared_db_ami)[0].block_device_mappings : "3" => mapping
    if mapping.device_name == "xvdh"
  } : {}
  snapshot_id_xvdh_db = local.environment == "production" ? local.block_device_mapping_xvdh_db[3].ebs.snapshot_id : ""

  block_device_mapping_xvdi_db = local.environment == "production" ? {
    for mapping in tolist(data.aws_ami.shared_db_ami)[0].block_device_mappings : "4" => mapping
    if mapping.device_name == "xvdi"
  } : {}
  snapshot_id_xvdi_db = local.environment == "production" ? local.block_device_mapping_xvdi_db[4].ebs.snapshot_id : ""

  block_device_mapping_xvdj_db = local.environment == "production" ? {
    for mapping in tolist(data.aws_ami.shared_db_ami)[0].block_device_mappings : "5" => mapping
    if mapping.device_name == "xvdj"
  } : {}
  snapshot_id_xvdj_db = local.environment == "production" ? local.block_device_mapping_xvdj_db[5].ebs.snapshot_id : ""

  block_device_mapping_xvdk_db = local.environment == "production" ? {
    for mapping in tolist(data.aws_ami.shared_db_ami)[0].block_device_mappings : "6" => mapping
    if mapping.device_name == "xvdk"
  } : {}
  snapshot_id_xvdk_db = local.environment == "production" ? local.block_device_mapping_xvdk_db[6].ebs.snapshot_id : ""

  block_device_mapping_xvdl_db = local.environment == "production" ? {
    for mapping in tolist(data.aws_ami.shared_db_ami)[0].block_device_mappings : "7" => mapping
    if mapping.device_name == "xvdl"
  } : {}
  snapshot_id_xvdl_db = local.environment == "production" ? local.block_device_mapping_xvdl_db[7].ebs.snapshot_id : ""

  block_device_mapping_xvdm_db = local.environment == "production" ? {
    for mapping in tolist(data.aws_ami.shared_db_ami)[0].block_device_mappings : "8" => mapping
    if mapping.device_name == "xvdm"
  } : {}
  snapshot_id_xvdm_db = local.environment == "production" ? local.block_device_mapping_xvdm_db[8].ebs.snapshot_id : ""

  block_device_mapping_xvdn_db = local.environment == "production" ? {
    for mapping in tolist(data.aws_ami.shared_db_ami)[0].block_device_mappings : "9" => mapping
    if mapping.device_name == "xvdn"
  } : {}
  snapshot_id_xvdn_db = local.environment == "production" ? local.block_device_mapping_xvdn_db[9].ebs.snapshot_id : ""

  env_to_cica_map = {
    "development" = ["dev"]
    "test"        = ["uat"]
    "production"  = ["uat", "prod"]
  }
  target_prefix = local.env_to_cica_map[local.environment]

  cica_s3_resource = [
    for prefix in local.target_prefix : "arn:aws:s3:::${prefix}storagebucket"
  ]

  tariffdb_volume_layout = [
    {
      device_name = "xvde"
      size        = 100
    },
    {
      device_name = "xvdf"
      size        = 2000
    },
    {
      device_name = "xvdg"
      size        = 100
    },
    {
      device_name = "xvdh"
      size        = 16
    },
    {
      device_name = "xvdi"
      size        = 30
    },
    {
      device_name = "xvdj"
      size        = 8
    },
    {
      device_name = "xvdk"
      size        = 1
    },
    {
      device_name = "xvdl"
      size        = 200
    },
    {
      device_name = "xvdm"
      size        = 500
    },
    {
      device_name = "xvdn"
      size        = 500
    }
  ]
  tariffapp_volume_layout = [
    {
      device_name = "xvde"
      size        = 100
    },
    {
      device_name = "xvdf"
      size        = 100
    },
    {
      device_name = "xvdg"
      size        = 100
    },
    {
      device_name = "xvdh"
      size        = 16
    },
    {
      device_name = "xvdi"
      size        = local.environment == "production" ? 100 : 30
    }
  ]
}
#
