"""Validate the real PDC Terraform files using isolated, mocked Terraform tests."""

import os
from pathlib import Path
import shutil
import subprocess
import tempfile


ROOT = Path(__file__).resolve().parents[1]
FIXTURE = ROOT / "tests" / "pdc-rotation"


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
        shutil.copyfile(FIXTURE / "main.tf", directory / "main.tf")
        tests = directory / "tests"
        tests.mkdir()
        for source in FIXTURE.glob("*.tftest.hcl"):
            shutil.copyfile(source, tests / source.name)
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
        shutil.copyfile(
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


if __name__ == "__main__":
    run()
