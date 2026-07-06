locals {
  alert_account_configs = {
    # ---------------------------------------------------------------------------
    # REFERENCE BLOCK — every supported field with description.
    # <account-uid> = {
    #
    #   # ── CloudWatch ────────────────────────────────────────────────────────
    #   # Grafana datasource name for CloudWatch (used by all non-Prometheus rules).
    #   # Must exactly match the datasource name configured for this account in
    #   # src/helm/values/grafana/values.yml.tftpl (${account.name}-cloudwatch).
    #   cloudwatch_datasource_name = "data-platform-<account>-cloudwatch"
    #
    #   # AWS region for CloudWatch API calls.
    #   aws_region = "eu-west-2"
    #
    #   # ── Prometheus ────────────────────────────────────────────────────────
    #   # Grafana datasource name for Prometheus. Required only when any signal
    #   # uses datasource_type = "prometheus" (eks_apiserver_*, eks_prom_*).
    #   # Omit entirely for accounts with no Amazon Managed Prometheus workspace.
    #   prometheus_datasource_name = "data-platform-<account>-prometheus"
    #
    #   # ── Alert groups ──────────────────────────────────────────────────────
    #   # Which signal groups to enable for this account.
    #   # Must match keys defined in local.alert_group_folders in
    #   # alerting-golden-signals.tf:
    #   #   "NAT Gateway"     → data-platform/networking
    #   #   "Transit Gateway" → data-platform/networking
    #   #   "Network Monitor" → data-platform/networking
    #   #   "EKS"             → data-platform/cluster
    #   #   "EFS"             → data-platform/storage
    #   #   "S3"              → data-platform/storage
    #   #   "MWAA"            → data-platform/airflow
    #   #   "Control Panel"   → data-platform/cluster
    #   #                        ↳ REQUIRES: namespaces, rds_instances, cache_clusters
    #   enabled_groups = [
    #     "NAT Gateway",
    #     "Transit Gateway",
    #     "Network Monitor",
    #     "EKS",
    #     "EFS",             # ← see dependencies below
    #     "S3",
    #     "MWAA",
    #     "Control Panel",   # ← see dependencies below
    #   ]
    #
    #   # ── Disabled rules ────────────────────────────────────────────────────
    #   # Individual signal keys to exclude entirely for this account. Keys must
    #   # match entries in local.alert_golden_signals in alerting-golden-signals.tf.
    #   # Omit (or leave empty) to create all rules in the enabled groups.
    #   disabled_rules = [
    #     "cp_crashloop_backoff",
    #     "rds_cpu",
    #   ]
    #
    #   # ── EFS dependencies ──────────────────────────────────────────────────
    #   # Required when "EFS" is in enabled_groups and any efs_* signal uses
    #   # dim_key = "FileSystemId" (e.g. efs_throughput).
    #   efs_file_systems = ["fs-abc1234567890", "fs-def0987654321"]
    #
    #   # ── Control Panel dependencies ───────────────────────────────────────
    #   # Required when "Control Panel" is in enabled_groups. Missing any of the
    #   # three will silently drop the corresponding rules.
    #   namespaces     = ["cpanel"]
    #   rds_instances  = ["data-platform-<account>-control-panel-db"]
    #   cache_clusters = ["<account>-control-panel-redis"]
    #
    #   # ── S3 dependencies ──────────────────────────────────────────────────
    #   # Required when "S3" is in enabled_groups.
    #   s3_buckets = ["data-platform-<account>-mwaa", "data-platform-<account>-velero"]
    #
    #   # ── Alert evaluation ─────────────────────────────────────────────────
    #   # How often Grafana evaluates the alert rules for this account.
    #   evaluation_interval = "1m"
    #
    #   # ── Threshold overrides ──────────────────────────────────────────────
    #   # Per-account overrides for any threshold key defined in local.alert_defaults.
    #   threshold_overrides = {
    #     eks_node_cpu_warn = 80
    #   }
    # }
    # ---------------------------------------------------------------------------

    development = {
      cloudwatch_datasource_name = "data-platform-development-cloudwatch"
      prometheus_datasource_name = "data-platform-development-prometheus"
      aws_region                 = "eu-west-2"
      evaluation_interval        = "1m"

      enabled_groups = [
        "AI Gateway"
      ]

      disabled_rules      = []
      threshold_overrides = {}
    }

    test = {}
    preproduction = {}
    production = {}
    
  }
}