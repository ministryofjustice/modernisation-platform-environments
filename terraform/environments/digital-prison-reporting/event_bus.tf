
module "create_event_bus_dpd" {
  source = "./modules/eventbridge"
  dpr_event_bus_name = local.event_bus_dpr

  tags = merge(
    local.all_tags,
    {
      Name           = local.event_bus_dpr
      Jira           = "DPR2-1715"
      Resource_Group = "Front-End"
    }
  )
}