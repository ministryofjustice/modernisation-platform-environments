variable "enable_starter_pack" {
  type        = bool
  default     = true
  description = "Toggle to enable starter pack service"
}

#------------------------------------------------------------------------------
# Observability PoC feature flags
#
# All default to false. Enable explicitly via workflow -var flags, e.g.:
#   "-var=enable_amp_adot=true -var=enable_cloudwatch_observability=true -var=enable_amg=true"
#
# This ensures no observability resources are deployed unless a user explicitly
# opts in, regardless of environment.
#------------------------------------------------------------------------------

variable "enable_amp_adot" {
  type        = bool
  default     = false
  description = "Deploy AMP workspace + ADOT collector pipeline (Option A). Must be explicitly enabled."
}

variable "enable_cloudwatch_observability" {
  type        = bool
  default     = false
  description = "Deploy OTel Container Insights add-on (Option D). Must be explicitly enabled."
}

variable "enable_amg" {
  type        = bool
  default     = false
  description = "Deploy Amazon Managed Grafana workspace. Must be explicitly enabled."
}