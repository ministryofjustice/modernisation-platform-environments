locals {

  security_groups = {
    private_dc = {
      description = "Security group for Domain Controllers"
      ingress = {
        all-from-self = {
          description = "Allow all ingress to self"
          from_port   = 0
          to_port     = 0
          protocol    = -1
          self        = true
        }
        all-from-noms-test-vnet = {
          description = "Allow all from noms test vnet"
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = ["10.101.0.0/16"]
        }
        all-from-noms-mgmt-vnet = {
          description = "Allow all from noms mgmt vnet"
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = ["10.102.0.0/16"]
        }
        all-from-noms-test-dr-vnet = {
          description = "Allow all from noms test vnet"
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = ["10.111.0.0/16"]
        }
        all-from-noms-mgmt-dr-vnet = {
          description = "Allow all from noms mgmt dr vnet"
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = ["10.112.0.0/16"]
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
  }
}
