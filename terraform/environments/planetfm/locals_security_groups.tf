locals {

  security_groups = {
    data_db = {
      description = "Security group for database servers"
      ingress = {
        all-from-self = {
          description = "Allow all ingress to self"
          from_port   = 0
          to_port     = 0
          protocol    = -1
          self        = true
        }
      }
      egress = {
        all = {
          description     = "Allow all egress"
          from_port       = 0
          to_port         = 0
          protocol        = "-1"
          cidr_blocks     = ["0.0.0.0/0"]
          security_groups = []
        }
      }
    }

    Migration_cutover_sg = {
      description = "Security group for migrated instances"
      ingress = {
        all-from-self = {
          description = "Allow all ingress to self"
          from_port   = 0
          to_port     = 0
          protocol    = -1
          self        = true
        }
        https = {
          description     = "443: https ingress"
          from_port       = 443
          to_port         = 443
          protocol        = "TCP"
          cidr_blocks     = ["10.0.0.0/8"]
          security_groups = []
        }

        rdp = {
          description     = "3389: Allow RDP ingress"
          from_port       = 3389
          to_port         = 3389
          protocol        = "TCP"
          cidr_blocks     = ["10.40.50.128/26","10.40.50.64/26","10.40.50.0/26"]
          security_groups = []
        }
      }
      



    }
  }
}
