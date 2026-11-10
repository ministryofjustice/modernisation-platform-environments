locals {
  name         = "integration-hub-events"
  cluster_name = "${local.name}-msk"
  deploy_to    = ["development"]

  extended_tags = merge(local.tags, {
    component = local.cluster_name
  })

  msk_sg_ingress_cidr = contains(local.deploy_to, local.environment) ? toset([
    for sub in data.aws_subnet.private_subnet_ids : sub.cidr_block
  ]) : toset([])

  # Topics created by the create-topics Lambda. Existing topics are never changed.
  kafka_topics = {
    events = {
      partitions         = 3
      replication_factor = 1
    }
  }

  # Development alerts channel used by the file transfer service (#integration-hub-alerts in Justice Digital)
  slack_channel_id = "C0CAB9Q6S2U"
  slack_team_id    = "T02DYEB3A"
}
