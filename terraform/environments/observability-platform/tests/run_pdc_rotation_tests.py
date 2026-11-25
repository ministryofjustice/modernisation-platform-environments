"""Validate the real PDC Terraform files using isolated, mocked Terraform tests."""

import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile


ROOT = Path(__file__).resolve().parents[1]
FIXTURE = ROOT / "tests" / "pdc-rotation"


def write_test_fixture(source, destination):
    # Mock provider defaults only accept literals; generate synthetic IDs in the temporary root.
    destination.write_text(
        source.read_text(encoding="utf-8")
        .replace("@MOCK_PLATFORM_ACCOUNT@", f"{4:012d}")
        .replace("@MOCK_NEW_ACCOUNT@", f"{8:012d}"),
        encoding="utf-8",
    )


def run_declarative_handoff_test(environment):
    """Exercise the real migration blocks against built-in resources and disposable local state."""
    accounts_file = (ROOT / "grafana-cloud-pdc-accounts.tf").read_text(encoding="utf-8")
    moves = "\n".join(re.findall(r"^(?:moved|removed) \{\n.*?^\}", accounts_file, re.M | re.S))
    moves = moves.replace("grafana_cloud_private_data_source_connect_network_token.", "terraform_data.token_")
    moves = moves.replace("aws_secretsmanager_secret_version.", "terraform_data.version_")
    template = """
resource "terraform_data" "token_account" {
  for_each = toset(ACCOUNTS)
  lifecycle { prevent_destroy = true }
}
resource "terraform_data" "version_gc_pdc_token" {
  for_each = toset(ACCOUNTS)
  lifecycle { prevent_destroy = true }
}
resource "terraform_data" "retained_metadata" {
  for_each = toset(["network", "secret", "key", "sprinkler-schedule"])
}
"""
    # Sprinkler was already handed off. Only Cooker's two legacy instances remain.
    initial_configuration = template.replace("ACCOUNTS", '["cooker-development"]')
    handoff_configuration = template.replace("ACCOUNTS", "[]") + moves
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
        plan = terraform("show", "-json", "tfplan")
        if plan.returncode:
            print(plan.stdout)
            raise SystemExit(plan.returncode)
        actions = {
            (item.get("previous_address"), item["address"]): item["change"]["actions"]
            for item in json.loads(plan.stdout)["resource_changes"]
            if item["change"]["actions"] != ["no-op"]
        }
        if actions != {
            ('terraform_data.token_account["cooker-development"]', "terraform_data.token_cooker_handoff"): ["forget"],
            ('terraform_data.version_gc_pdc_token["cooker-development"]', "terraform_data.version_cooker_handoff"): ["forget"],
        }:
            raise SystemExit(f"Expected exactly two Cooker forgets, without deletes: {actions}")

        result = terraform("apply", "-input=false", "-no-color", "tfplan")
        if result.returncode:
            print(result.stdout)
            raise SystemExit(result.returncode)
        state = terraform("state", "list")
        if state.returncode:
            print(state.stdout)
            raise SystemExit(state.returncode)
        expected = {f'terraform_data.retained_metadata["{name}"]' for name in ("network", "secret", "key", "sprinkler-schedule")}
        if set(state.stdout.splitlines()) != expected:
            print(state.stdout)
            raise SystemExit("The handoff must retain all metadata and Sprinkler's schedule.")
        print("Exactly two Cooker state forgets, zero destroys; metadata and Sprinkler schedule retained.")


def run():
    # Copy production files, not a second implementation. Never initialise the live backend.
    with tempfile.TemporaryDirectory(prefix="pdc-rotation-tests-") as temporary:
        directory = Path(temporary)
        for name in (
            "versions.tf",
            "grafana-cloud-stack.tf",
            "grafana-cloud-pdc-accounts.tf",
            "grafana-cloud-pdc-bootstrap.tf",
            "grafana-cloud-pdc-rotation.tf",
            "grafana-cloud-pdc-rotator.tf",
        ):
            shutil.copyfile(ROOT / name, directory / name)
        for name in ("main.tf", "providers.tf"):
            shutil.copyfile(FIXTURE / name, directory / name)
        helper = directory / "contrib" / "bootstrap-pdc-secret.py"
        helper.parent.mkdir()
        shutil.copyfile(ROOT / "contrib" / helper.name, helper)
        stub = directory / "aws"
        shutil.copyfile(FIXTURE / "aws-stub.py", stub)
        stub.chmod(0o700)
        calls = directory / "invocations"
        tests = directory / "tests"
        tests.mkdir()
        for source in FIXTURE.glob("*.tftest.hcl"):
            write_test_fixture(source, tests / source.name)
        environment = os.environ | {
            "TF_IN_AUTOMATION": "1",
            "TF_INPUT": "0",
            "TF_DATA_DIR": str(directory / ".terraform"),
            "PATH": str(directory) + os.pathsep + os.environ["PATH"],
            "EXPECTED_FUNCTION_ARN": f"arn:aws:lambda:eu-west-2:{4:012d}:function:grafana-pdc-token-rotator",
            "EXPECTED_SECRET_ARN": f"arn:aws:secretsmanager:eu-west-2:{4:012d}:secret:grafana-cloud/pdc/{8:012d}-ABCDEF",
            "PDC_TEST_INVOCATIONS": str(calls),
            "PDC_TEST_RESPONSE": "success",
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

        # terraform test also destroys its disposable resources: removal must not invoke again.
        if not calls.exists() or calls.read_text().splitlines() != ["invoke"]:
            raise SystemExit("Expected exactly one synchronous bootstrap across creation, re-apply, image/enrolment change and teardown.")
        print("Exactly one bootstrap invocation; no replay on image/enrolment change or removal.")
        for case, diagnostic in (
            ("function", "Lambda failed"),
            ("transport", "AWS CLI exit 1"),
            ("non-null", "Unexpected PDC bootstrap response"),
        ):
            result = subprocess.run(
                [sys.executable, str(helper)], capture_output=True, text=True, check=False,
                env=environment | {
                    "PDC_FUNCTION_ARN": environment["EXPECTED_FUNCTION_ARN"],
                    "PDC_SECRET_ARN": environment["EXPECTED_SECRET_ARN"],
                    "PDC_TEST_RESPONSE": case,
                },
            )
            if result.returncode == 0 or diagnostic not in result.stderr or "DO-NOT-EMIT" in result.stdout + result.stderr:
                raise SystemExit(f"Expected a redacted, nonzero exit for the {case} bootstrap response.")
        print("Bootstrap rejects function, transport and non-null responses without emitting the payload.")

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
            and "aws_secretsmanager_secret.gc_pdc_token" in result.stdout
            and 'run "protected_secrets"... pass' in result.stdout
        ):
            print(result.stdout)
            raise SystemExit("Expected destructive account disablement to be blocked.")
        print("Destructive account disablement blocked by secret protection.")
        run_declarative_handoff_test(environment)


if __name__ == "__main__":
    run()
