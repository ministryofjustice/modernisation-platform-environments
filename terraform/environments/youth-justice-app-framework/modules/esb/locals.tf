locals {
 
 esb_security_group_ingress = [
    {
      from_port   = 8401
      to_port     = 8401
      protocol    = "tcp"
      self        = true
      description = "ESB TEST"
    },
    {
      from_port   = 9091
      to_port     = 9091
      protocol    = "tcp"
      self        = true
      description = "ESB TEST"
    }
  ]
}