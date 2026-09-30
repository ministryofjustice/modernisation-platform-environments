# Temporary: renames module.athena_lb_logs to module.athena without recreating anything.
# Delete this file once the change has been applied.

moved {
  from = module.athena_lb_logs
  to   = module.athena
}
