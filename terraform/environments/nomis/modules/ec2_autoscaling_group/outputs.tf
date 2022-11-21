output "userdataraw" {
  description = "debug variables"
  value = {
    ami              = data.aws_ami.this
    cloudinit_config = data.cloudinit_config.this
    ebs_volumes      = local.ebs_volumes
    tags             = local.tags
    subnet           = data.aws_subnet.this
    user_data_raw    = local.user_data_raw
    ebs_volumes      = local.ebs_volumes
  }
}
