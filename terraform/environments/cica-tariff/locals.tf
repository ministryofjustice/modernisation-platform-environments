#### This file can be used to store locals specific to the member account ####
locals {
  pubkey = {
    "development" = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC3Fq4UnSs9jsFRxG7WV/2g4C4gTaG+7J5p5oi3Eup27MMoNBGTQV64ZETq8Gzx0Dx9R5xnj/y1DT350om2cdcGUYUDu47mOY+VXXtJpzK94R5ZzN+74xjz/swTgJQaOY8iaeSNsILkFMm50xTr7gzSaAswL95RH8h1IibzheqmwkHtN97JEaXkJbhE/CYNPmJzUahNG05vEnBG4op7OG5oLi+7cvZlrnho9lpkWRcOgXaS/mQsMKb45plYCU52reWIZhO9IoxaXULoYybk617I0Blhe2IvYcXfWZGw5xrfJrPJFiiK5fmYGgMp0d1J730kKZ5sOh0Y7Bdf3XXefUIaHlKe95/rXQczw5EeMG+lRt6cOS3XAh4CquyvwY3Oj2HgDLE2JMQS3Y9k8dBpopUCGLvk7MnHMb4SLF4FEoaeJQdv07c6amOQm5Hk0l13TAzlQg+xkyW0y3aluLdAyH6fucbwFiUnAINm9tqem7ZGghWxaC6X9xBUpCDOWPO/3KjpLvPNRrmIgEfSh73o3Jks16Ef3f94XOCM+exO8mTuAYK3F6Uhc2I6xMb3Wp35PBOZbKBEZCeoDvyb841UKHd6LLrgQELEOG+xd3UzM24JMh2FEnbCj3orIw2Zj1B4Udyu2EyV7BLpUhMt/jNt9Jonf1MqVzn9M3JfjUQEjYwVqQ==",
    "test"        = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC3Fq4UnSs9jsFRxG7WV/2g4C4gTaG+7J5p5oi3Eup27MMoNBGTQV64ZETq8Gzx0Dx9R5xnj/y1DT350om2cdcGUYUDu47mOY+VXXtJpzK94R5ZzN+74xjz/swTgJQaOY8iaeSNsILkFMm50xTr7gzSaAswL95RH8h1IibzheqmwkHtN97JEaXkJbhE/CYNPmJzUahNG05vEnBG4op7OG5oLi+7cvZlrnho9lpkWRcOgXaS/mQsMKb45plYCU52reWIZhO9IoxaXULoYybk617I0Blhe2IvYcXfWZGw5xrfJrPJFiiK5fmYGgMp0d1J730kKZ5sOh0Y7Bdf3XXefUIaHlKe95/rXQczw5EeMG+lRt6cOS3XAh4CquyvwY3Oj2HgDLE2JMQS3Y9k8dBpopUCGLvk7MnHMb4SLF4FEoaeJQdv07c6amOQm5Hk0l13TAzlQg+xkyW0y3aluLdAyH6fucbwFiUnAINm9tqem7ZGghWxaC6X9xBUpCDOWPO/3KjpLvPNRrmIgEfSh73o3Jks16Ef3f94XOCM+exO8mTuAYK3F6Uhc2I6xMb3Wp35PBOZbKBEZCeoDvyb841UKHd6LLrgQELEOG+xd3UzM24JMh2FEnbCj3orIw2Zj1B4Udyu2EyV7BLpUhMt/jNt9Jonf1MqVzn9M3JfjUQEjYwVqQ==",
    "production"  = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC3Fq4UnSs9jsFRxG7WV/2g4C4gTaG+7J5p5oi3Eup27MMoNBGTQV64ZETq8Gzx0Dx9R5xnj/y1DT350om2cdcGUYUDu47mOY+VXXtJpzK94R5ZzN+74xjz/swTgJQaOY8iaeSNsILkFMm50xTr7gzSaAswL95RH8h1IibzheqmwkHtN97JEaXkJbhE/CYNPmJzUahNG05vEnBG4op7OG5oLi+7cvZlrnho9lpkWRcOgXaS/mQsMKb45plYCU52reWIZhO9IoxaXULoYybk617I0Blhe2IvYcXfWZGw5xrfJrPJFiiK5fmYGgMp0d1J730kKZ5sOh0Y7Bdf3XXefUIaHlKe95/rXQczw5EeMG+lRt6cOS3XAh4CquyvwY3Oj2HgDLE2JMQS3Y9k8dBpopUCGLvk7MnHMb4SLF4FEoaeJQdv07c6amOQm5Hk0l13TAzlQg+xkyW0y3aluLdAyH6fucbwFiUnAINm9tqem7ZGghWxaC6X9xBUpCDOWPO/3KjpLvPNRrmIgEfSh73o3Jks16Ef3f94XOCM+exO8mTuAYK3F6Uhc2I6xMb3Wp35PBOZbKBEZCeoDvyb841UKHd6LLrgQELEOG+xd3UzM24JMh2FEnbCj3orIw2Zj1B4Udyu2EyV7BLpUhMt/jNt9Jonf1MqVzn9M3JfjUQEjYwVqQ=="
  }
  cidr_cica_ss_a        = "10.10.10.0/24"
  cidr_cica_ss_b        = "10.10.110.0/24"
  cidr_cica_dev_a       = "10.11.10.0/24"
  cidr_cica_dev_b       = "10.11.110.0/24"
  cidr_cica_uat_a       = "10.12.10.0/24"
  cidr_cica_uat_b       = "10.12.110.0/24"
  cidr_cica_onprem_uat  = "192.168.4.0/24"
  cidr_cica_onprem_prod = "10.2.30.0/24"
  cidr_cica_ras         = "10.9.14.0/23"
  cidr_cica_lan         = "10.7.11.0/24"
  cidr_cica_ras_nat     = "10.7.14.224/28"
  cidr_cica_prod_a      = "10.13.10.0/24"
  cidr_cica_prod_b      = "10.13.110.0/24"

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
}
#
