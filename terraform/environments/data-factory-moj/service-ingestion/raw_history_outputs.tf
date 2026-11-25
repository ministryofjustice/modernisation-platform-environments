output "raw_history_runtimes" {
  description = "Development Raw History receivers and published component targets."
  sensitive   = true

  value = local.is-development ? (
    module.configured_ingestion[0].raw_history_runtimes
  ) : {}
}
