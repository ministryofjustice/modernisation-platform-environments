locals {

  esb_security_group_ingress = [
    {
      from_port   = 8401
      to_port     = 8401
      protocol    = "tcp"
      self        = true
      description = "esb-admin service to esb-admin service communication TEST"
    },
    {
      from_port   = 9091
      to_port     = 9091
      protocol    = "tcp"
      self        = true
      description = "esb-hub service to esb-hub service communication TEST"
    }
  ]
}