locals {
  tariffdb_vol_import_data = {
    "subnet_a-xvde" = {
      device_name = "xvde"
      instance_id = "i-030db90a2de02f56e"
      volume_id   = "vol-0709994329a0f926b"
    },
    "subnet_a-xvdf" = {
      device_name = "xvdf"
      instance_id = "i-030db90a2de02f56e"
      volume_id   = "vol-074b0406dd536d13c"
    },
    "subnet_a-xvdg" = {
      device_name = "xvdg"
      instance_id = "i-030db90a2de02f56e"
      volume_id   = "vol-06aac65b8ceb9ec33"
    },
    "subnet_a-xvdh" = {
      device_name = "xvdh"
      instance_id = "i-030db90a2de02f56e"
      volume_id   = "vol-05527dd7dc6fbbf71"
    },
    "subnet_a-xvdi" = {
      device_name = "xvdi"
      instance_id = "i-030db90a2de02f56e"
      volume_id   = "vol-0e527f79fac9663ab"
    },
    "subnet_a-xvdj" = {
      device_name = "xvdj"
      instance_id = "i-030db90a2de02f56e"
      volume_id   = "vol-040a345567e8228f6"
    },
    "subnet_a-xvdk" = {
      device_name = "xvdk"
      instance_id = "i-030db90a2de02f56e"
      volume_id   = "vol-036210f231728cc61"
    },
    "subnet_a-xvdl" = {
      device_name = "xvdl"
      instance_id = "i-030db90a2de02f56e"
      volume_id   = "vol-04866216a4c04fc08"
    },
    "subnet_a-xvdm" = {
      device_name = "xvdm"
      instance_id = "i-030db90a2de02f56e"
      volume_id   = "vol-0a2818d6252e83ec1"
    },
    "subnet_a-xvdn" = {
      device_name = "xvdn"
      instance_id = "i-030db90a2de02f56e"
      volume_id   = "vol-03c0b2549c2596a73"
    },
    "subnet_b-xvde" = {
      device_name = "xvde"
      instance_id = "i-0939a0ee8fb520bc9"
      volume_id   = "vol-0c4c5c5c9965a4995"
    },
    "subnet_b-xvdf" = {
      device_name = "xvdf"
      instance_id = "i-0939a0ee8fb520bc9"
      volume_id   = "vol-003f2a06c1d0fc633"
    },
    "subnet_b-xvdg" = {
      device_name = "xvdg"
      instance_id = "i-0939a0ee8fb520bc9"
      volume_id   = "vol-01734340782caff24"
    },
    "subnet_b-xvdh" = {
      device_name = "xvdh"
      instance_id = "i-0939a0ee8fb520bc9"
      volume_id   = "vol-0858561bccd244619"
    },
    "subnet_b-xvdi" = {
      device_name = "xvdi"
      instance_id = "i-0939a0ee8fb520bc9"
      volume_id   = "vol-008d101c2bd92a11b"
    },
    "subnet_b-xvdj" = {
      device_name = "xvdj"
      instance_id = "i-0939a0ee8fb520bc9"
      volume_id   = "vol-0f73727edcf8f5064"
    },
    "subnet_b-xvdk" = {
      device_name = "xvdk"
      instance_id = "i-0939a0ee8fb520bc9"
      volume_id   = "vol-06bde5b029f52f672"
    },
    "subnet_b-xvdl" = {
      device_name = "xvdl"
      instance_id = "i-0939a0ee8fb520bc9"
      volume_id   = "vol-0991c1cbbc54f5fde"
    },
    "subnet_b-xvdm" = {
      device_name = "xvdm"
      instance_id = "i-0939a0ee8fb520bc9"
      volume_id   = "vol-0e8388d6835a171f9"
    },
    "subnet_b-xvdn" = {
      device_name = "xvdn"
      instance_id = "i-0939a0ee8fb520bc9"
      volume_id   = "vol-05f9b59545f6f6609"
    } 
  }
}

import {
  for_each = local.environment == "production" ? local.tariffdb_vol_import_data : {}
  to = aws_ebs_volume.tariffdb_storage[each.key]
  id = each.value.volume_id
}

import {
  for_each = local.environment == "production" ? local.tariffdb_vol_import_data : {}
  to = aws_volume_attachment.tariffdb_attachment[each.key]
  id = "${each.value.device_name}:${each.value.volume_id}:${each.value.instance_id}"
}