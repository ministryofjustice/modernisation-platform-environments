#### This file can be used to store locals specific to the member account ####

locals {
  delius_environments_per_account = {
    # account = [env1, env2]
    prod    = [] # prod
    preprod = ["stage", "preprod"]
    test    = []
    dev     = ["dev"]
  }

  ordered_subnet_ids = [data.aws_subnets.shared-private-a.ids[0], data.aws_subnets.shared-private-b.ids[0], data.aws_subnets.shared-private-c.ids[0]]
}
