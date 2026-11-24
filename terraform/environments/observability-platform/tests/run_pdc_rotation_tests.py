"""Validate the real PDC Terraform files using isolated, mocked Terraform tests."""

import os
from pathlib import Path
import shutil
import subprocess
import tempfile


ROOT = Path(__file__).resolve().parents[1]
FIXTURE = ROOT / "tests" / "pdc-rotation"


def write_test_fixture(source, destination):
    # Mock provider defaults only accept literals; generate synthetic IDs in the temporary root.
    destination.write_text(
        source.read_text(encoding="utf-8").replace("@MOCK_PLATFORM_ACCOUNT@", f"{4:012d}"),
        encoding="utf-8",
    )


def run_declarative_handoff_test(environment):
    """Prove that a moved, protected for_each instance can be forgotten without destruction."""
    initial_configuration = """\
terraform {
  required_version = "~> 1.10"
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}

locals {
  accounts = {
    sprinkler-development = "pilot"
    cooker-development    = "control"
  }
}

resource "null_resource" "tokens" {
  for_each = local.accounts
  triggers = { account = each.key }
  lifecycle { prevent_destroy = true }
}

resource "null_resource" "secret_versions" {
  for_each = local.accounts
  triggers = { account = each.key }
  lifecycle { prevent_destroy = true }
}
"""
    handoff_configuration = """\
terraform {
  required_version = "~> 1.10"
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}

locals {
  accounts = {
    cooker-development = "control"
  }
}

resource "null_resource" "tokens" {
  for_each = local.accounts
  triggers = { account = each.key }
  lifecycle { prevent_destroy = true }
}

resource "null_resource" "secret_versions" {
  for_each = local.accounts
  triggers = { account = each.key }
  lifecycle { prevent_destroy = true }
}

moved {
  from = null_resource.tokens["sprinkler-development"]
  to   = null_resource.token_pilot_handoff
}

removed {
  from = null_resource.token_pilot_handoff
  lifecycle { destroy = false }
}

moved {
  from = null_resource.secret_versions["sprinkler-development"]
  to   = null_resource.secret_version_pilot_handoff
}

removed {
  from = null_resource.secret_version_pilot_handoff
  lifecycle { destroy = false }
}
"""
    with tempfile.TemporaryDirectory(prefix="pdc-handoff-state-test-") as temporary:
        directory = Path(temporary)
        config = directory / "main.tf"
        config.write_text(initial_configuration, encoding="utf-8")
        terraform_environment = environment | {"TF_DATA_DIR": str(directory / ".terraform")}

        def terraform(*arguments):
            return subprocess.run(
                ["terraform", *arguments],
                cwd=directory,
                env=terraform_environment,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                check=False,
            )

        for arguments in (
            ("init", "-backend=false", "-no-color"),
            ("apply", "-auto-approve", "-input=false", "-no-color"),
        ):
            result = terraform(*arguments)
            if result.returncode:
                print(result.stdout)
                raise SystemExit(result.returncode)

        config.write_text(handoff_configuration, encoding="utf-8")
        result = terraform("plan", "-input=false", "-no-color", "-out=tfplan")
        if result.returncode:
            print(result.stdout)
            raise SystemExit(result.returncode)
        plan = terraform("show", "-no-color", "tfplan")
        if plan.returncode:
            print(plan.stdout)
            raise SystemExit(plan.returncode)
        if (
            "will no longer be managed by Terraform, but will not be destroyed" not in plan.stdout
            or "Plan: 0 to add, 0 to change, 0 to destroy." not in plan.stdout
        ):
            print(plan.stdout)
            raise SystemExit("Expected the pilot handoff plan to forget only, without destroying.")

        result = terraform("apply", "-input=false", "-no-color", "tfplan")
        if result.returncode:
            print(result.stdout)
            raise SystemExit(result.returncode)
        state = terraform("state", "list")
        if state.returncode:
            print(state.stdout)
            raise SystemExit(state.returncode)
        expected = {
            'null_resource.tokens["cooker-development"]',
            'null_resource.secret_versions["cooker-development"]',
        }
        if set(state.stdout.splitlines()) != expected:
            print(state.stdout)
            raise SystemExit("The handoff must forget only the pilot token and secret version.")
        print("Declarative handoff forgets the pilot token and version; Cooker remains managed.")


def run():
    # Copy production files, not a second implementation. Never initialise the live backend.
    with tempfile.TemporaryDirectory(prefix="pdc-rotation-tests-") as temporary:
        directory = Path(temporary)
        for name in (
            "versions.tf",
            "grafana-cloud-stack.tf",
            "grafana-cloud-pdc-accounts.tf",
            "grafana-cloud-pdc-rotation.tf",
            "grafana-cloud-pdc-rotator.tf",
        ):
            shutil.copyfile(ROOT / name, directory / name)
        for name in ("main.tf", "providers.tf"):
            shutil.copyfile(FIXTURE / name, directory / name)
        tests = directory / "tests"
        tests.mkdir()
        for source in FIXTURE.glob("*.tftest.hcl"):
            write_test_fixture(source, tests / source.name)
        environment = os.environ | {
            "TF_IN_AUTOMATION": "1",
            "TF_INPUT": "0",
            "TF_DATA_DIR": str(directory / ".terraform"),
        }
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

        # Lifecycle destruction errors cannot be captured by Terraform's expect_failures.
        write_test_fixture(
            FIXTURE / "token-destruction.hcl",
            tests / "token-destruction.tftest.hcl",
        )
        result = subprocess.run(
            ["terraform", "test", "-no-color", "-filter=tests/token-destruction.tftest.hcl"],
            cwd=directory,
            env=environment,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            check=False,
        )
        if not (
            result.returncode != 0
            and "prevent_destroy" in result.stdout
            and "grafana_cloud_private_data_source_connect_network_token.account" in result.stdout
            and 'run "bootstrap_tokens"... pass' in result.stdout
        ):
            print(result.stdout)
            raise SystemExit("Expected destructive account disablement to be blocked.")
        print("Destructive account disablement correctly blocked by token protection.")
        run_declarative_handoff_test(environment)


if __name__ == "__main__":
    run()
