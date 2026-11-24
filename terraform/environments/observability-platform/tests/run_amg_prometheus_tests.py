"""Test the actual default AMG Prometheus data source for both environments."""

import os
from pathlib import Path
import shutil
import subprocess
import tempfile


ROOT = Path(__file__).resolve().parents[1]


def run():
    source = (ROOT / "amg-workspace.tf").read_text(encoding="utf-8")
    prometheus_source = source.split("/* Prometheus Source */", 1)[1].split(
        "/* GitHub Source */", 1
    )[0]
    with tempfile.TemporaryDirectory(prefix="amg-prometheus-tests-") as temporary:
        directory = Path(temporary)
        shutil.copyfile(
            ROOT / "amg-tenant-environment-configurations.tf",
            directory / "amg-tenant-environment-configurations.tf",
        )
        (directory / "main.tf").write_text(
            """\
terraform {
  required_providers {
    grafana = {
      source  = "grafana/grafana"
      version = "~> 3.25.9"
    }
  }
}

variable "environment" { type = string }
locals { environment = var.environment }

module "managed_prometheus" {
  source = "./prometheus"
}
"""
            + prometheus_source,
            encoding="utf-8",
        )
        module = directory / "prometheus"
        module.mkdir()
        (module / "main.tf").write_text(
            'output "workspace_prometheus_endpoint" { value = "https://example.test/" }\n',
            encoding="utf-8",
        )
        tests = directory / "tests"
        tests.mkdir()
        (tests / "prometheus.tftest.hcl").write_text(
            """\
mock_provider "grafana" {}

run "development_uses_amg_migrated_plugin" {
  command = plan
  variables { environment = "development" }
  assert {
    condition = (
      grafana_data_source.observability_platform_prometheus.type == "grafana-amazonprometheus-datasource" &&
      grafana_data_source.observability_platform_prometheus.is_default &&
      jsondecode(grafana_data_source.observability_platform_prometheus.json_data_encoded).sigV4Auth
    )
    error_message = "Development must use the migrated AMG plugin with default SigV4 settings."
  }
}

run "production_retains_prometheus" {
  command = plan
  variables { environment = "production" }
  assert {
    condition = (
      grafana_data_source.observability_platform_prometheus.type == "prometheus" &&
      grafana_data_source.observability_platform_prometheus.is_default &&
      jsondecode(grafana_data_source.observability_platform_prometheus.json_data_encoded).sigV4Auth
    )
    error_message = "Production must retain the existing default Prometheus data source."
  }
}
""",
            encoding="utf-8",
        )
        environment = os.environ | {"TF_IN_AUTOMATION": "1", "TF_INPUT": "0"}
        for arguments in (
            ("init", "-backend=false", "-no-color"),
            ("validate", "-no-color"),
            ("test", "-no-color"),
        ):
            result = subprocess.run(
                ["terraform", *arguments],
                cwd=directory,
                env=environment,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                check=False,
            )
            if result.returncode:
                print(result.stdout)
                raise SystemExit(result.returncode)
            if arguments[0] != "init":
                print(result.stdout)


if __name__ == "__main__":
    run()
