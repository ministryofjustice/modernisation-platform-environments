locals {
  tariff_app_xvde = {
    development = "vol-0e4cf68a8692776d4"
    test        = "vol-084fc01b98a8f382b"
    production  = "vol-0f8a8393be973fff1"
  }
  tariff_app_xvdf = {
    development = "vol-00ed0723e93b248ba"
    test        = "vol-0ff63ee1ffa50bbb1"
    production  = "vol-063eecb0e70ff6dcd"
  }
  tariff_app_xvdg = {
    development = "vol-05e6b1e5ad3f207e3"
    test        = "vol-05279f7731c67d6f9"
    production  = "vol-00ef1707406fbe29d"
  }
  tariff_app_xvdh = {
    development = "vol-04934584ea88f7034"
    test        = "vol-088b076c075df49f0"
    production  = "vol-08b11bcd67069e027"
  }
  tariff_app_xvdi = {
    development = "vol-06f21c63393301264"
    test        = "vol-0e9baac9c0072f768"
    production  = "vol-03defb57a8bd2375c"
  }
}

import {
  to = aws_ebs_volume.tariff_app_storage["xvde"]
  id = local.tariff_app_xvde[local.environment]
}
import {
  to = aws_ebs_volume.tariff_app_storage["xvdf"]
  id = local.tariff_app_xvdf[local.environment]
}
import {
  to = aws_ebs_volume.tariff_app_storage["xvdg"]
  id = local.tariff_app_xvdg[local.environment]
}
import {
  to = aws_ebs_volume.tariff_app_storage["xvdh"]
  id = local.tariff_app_xvdh[local.environment]
}
import {
  to = aws_ebs_volume.tariff_app_storage["xvdi"]
  id = local.tariff_app_xvdi[local.environment]
}

import {
  to = aws_volume_attachment.tariff_app_storage_attachment["xvde"]
  id = "xvde:${local.tariff_app_xvde[local.environment]}:${aws_instance.tariff_app.id}"
}
import {
  to = aws_volume_attachment.tariff_app_storage_attachment["xvdf"]
  id = "xvdf:${local.tariff_app_xvdf[local.environment]}:${aws_instance.tariff_app.id}"
}
import {
  to = aws_volume_attachment.tariff_app_storage_attachment["xvdg"]
  id = "xvdg:${local.tariff_app_xvdg[local.environment]}:${aws_instance.tariff_app.id}"
}
import {
  to = aws_volume_attachment.tariff_app_storage_attachment["xvdh"]
  id = "xvdh:${local.tariff_app_xvdh[local.environment]}:${aws_instance.tariff_app.id}"
}
import {
  to = aws_volume_attachment.tariff_app_storage_attachment["xvdi"]
  id = "xvdi:${local.tariff_app_xvdi[local.environment]}:${aws_instance.tariff_app.id}"
}

# Production only
locals {
  tariff_app2_storage = {
    "xvde" = "vol-04f6ad22242ec56db"
    "xvdf" = "vol-0cb90b662927e3e97"
    "xvdg" = "vol-043eb3dff09c66cec"
    "xvdh" = "vol-01bfbda7aaa643745"
    "xvdi" = "vol-0c74627d2943d9afd"
  }
}

import {
  for_each = local.environment == "production" ? local.tariff_app2_storage : {}
  to       = aws_ebs_volume.tariff_app2_storage[each.key]
  id       = each.value
}

import {
  for_each = local.environment == "production" ? local.tariff_app2_storage : {}
  to       = aws_volume_attachment.tariff_app2_storage_attachment[each.key]
  id       = "${each.key}:${each.value}:${aws_instance.tariff_app_2[0].id}"
}
