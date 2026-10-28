locals {
  private_subnet_ids = sort(data.aws_subnets.shared-private.ids)
  writer_subnet_ids = contains(["preproduction", "production"], local.environment) ? local.private_subnet_ids : slice(
    local.private_subnet_ids, 0, min(1, length(local.private_subnet_ids))
  )

  sftp_egress_rules = {
    for rule in flatten([
      for entry_id, entry in local.push_to_sftp_entries : [
        for cidr in entry.action.push_to_sftp.destination_cidr_blocks : {
          key  = "${entry_id}:${cidr}"
          cidr = cidr
          port = try(entry.action.push_to_sftp.port, 22)
        }
      ]
    ]) : rule.key => rule
  }
}