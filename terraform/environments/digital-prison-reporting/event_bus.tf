
module "create_event_bus_dpd" {
  source = "./modules/eventbridge"
  dpr_event_bus_name = local.event_bus_dpr
}