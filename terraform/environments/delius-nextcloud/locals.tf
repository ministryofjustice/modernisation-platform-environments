locals {
    environments_per_account = {
        # account = [env1, env2]
        prod     = [] # prod
        pre_prod = [] # stage, pre-prod
        test     = []
        dev      = ["dev"]
}

ordered_subnet_ids = [data.aws_subnets.shared-private-a.ids[0], data.aws_subnets.shared-private-b.ids[0], data.aws_subnets.shared-private-c.ids[0]]
}
