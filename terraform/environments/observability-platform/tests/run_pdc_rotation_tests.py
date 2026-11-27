"""Validate the real PDC Terraform files using isolated, mocked Terraform tests."""

from contextlib import redirect_stderr, redirect_stdout
import io
import json
import os
from pathlib import Path
import re
import runpy
import shutil
import subprocess
import tempfile
from unittest.mock import patch


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


def check_enrolment_order(directory, environment):
    graph = subprocess.check_output(["terraform", "graph"], cwd=directory, env=environment, text=True)
    edges = re.findall(r'"([^"]+)" -> "([^"]+)"', graph)

    def prerequisites(resource):
        return {dep for node, dep in edges if node == resource}

    def precedes(first, last):
        pending = [last]
        seen = set()
        while pending:
            node = pending.pop()
            if node == first:
                return True
            seen.add(node)
            pending.extend(prerequisites(node) - seen)
        return False

    bootstrap = "terraform_data.gc_pdc_bootstrap"
    rule = "aws_cloudwatch_event_rule.gc_pdc_enrolment"
    target = "aws_cloudwatch_event_target.gc_pdc_enrolment"
    event_permission = "aws_lambda_permission.gc_pdc_enrolment_tick"
    rotation_permission = "aws_lambda_permission.gc_pdc_enrolment_rotation"
    for first, last in [(bootstrap, rule), (rule, event_permission), (event_permission, target), (rotation_permission, target)]:
        if not precedes(first, last):
            raise SystemExit(f"Missing enrolment dependency: {first} must precede {last}.")
    print("Terraform orders first issuance before the rule, and both invoke permissions before the target.")


def check_bootstrap_retries(helper, environment):
    main = runpy.run_path(str(helper))["main"]
    calls = Path(environment["PDC_TEST_INVOCATIONS"])
    backoff = [10, 20, 40] + [60] * 14
    for case, delays, error in (
        ("throttle,legacy-throttle,success", backoff[:2], None),
        ("throttle", backoff, "TooManyRequestsException); retry limit reached"),
        ("throttle,function", backoff[:1], "Lambda failed"),
        ("denied", [], "AccessDeniedException"),
        ("unsafe-code", [], "AWS CLI exit 254"),
        ("unknown-format", [], "AWS CLI exit 254"),
        ("read-timeout", [], "AWS CLI exit 255"),
        ("transport", [], "AWS CLI exit 255"),
        ("function", [], "Lambda failed"),
        ("non-null", [], "Unexpected PDC bootstrap response"),
    ):
        calls.write_text("")
        output = io.StringIO()
        failure = None
        with (
            patch.dict(os.environ, environment | {"PDC_TEST_RESPONSE": case}),
            patch("time.sleep") as sleep,
            redirect_stdout(output), redirect_stderr(output),
        ):
            try:
                main()
            except SystemExit as exc:
                failure = str(exc)
        if (error is None and failure is not None) or (error is not None and error not in (failure or "")):
            raise SystemExit(f"Unexpected result for bootstrap stub case: {case}.")
        if [call.args for call in sleep.call_args_list] != [(delay,) for delay in delays] or calls.read_text().splitlines() != ["invoke"] * (1 + len(delays)):
            raise SystemExit(f"Unexpected attempts or backoff for bootstrap stub case: {case}.")
        if any(private in output.getvalue() + (failure or "") for private in ("DO-NOT-EMIT", "arn:", f"{4:012d}")):
            raise SystemExit(f"Leaked bootstrap diagnostic in stub case: {case}.")
    print("Only Invoke throttles retry: throttle-then-success, bounded exhaustion and redacted non-retryable failures verified.")


def check_bootstrap_recovery(directory, environment):
    # Exercise Terraform's create-time provisioner failure semantics without a provider or remote state.
    root = directory / "recovery"
    root.mkdir()
    (root / "main.tf").write_text("""
resource "terraform_data" "gc_pdc_bootstrap" {
  for_each = toset(["new-development"])
  provisioner "local-exec" {
    command = "python3 ../contrib/bootstrap-pdc-secret.py"
  }
}
""")
    calls = root / "invocations"
    env = environment | {"TF_DATA_DIR": str(root / ".terraform"), "PDC_TEST_INVOCATIONS": str(calls)}

    def terraform(*args, case="success", check=True):
        return subprocess.run(
            ["terraform", *args], cwd=root, env=env | {"PDC_TEST_RESPONSE": case},
            capture_output=True, text=True, check=check,
        )

    terraform("init", "-backend=false")
    failure = terraform("apply", "-auto-approve", "-no-color", case="denied", check=False)
    if failure.returncode == 0 or "AccessDeniedException" not in failure.stdout + failure.stderr:
        raise SystemExit("Expected a failed bootstrap create provisioner in disposable state.")
    terraform("plan", "-out=tfplan")
    change, = json.loads(terraform("show", "-json", "tfplan").stdout)["resource_changes"]
    if not (
        change["address"] == 'terraform_data.gc_pdc_bootstrap["new-development"]'
        and change.get("action_reason") == "replace_because_tainted"
        and change["change"]["actions"] == ["delete", "create"]
    ):
        raise SystemExit("Expected replacement of only the tainted bootstrap marker.")
    terraform("apply", "tfplan")
    terraform("plan", "-detailed-exitcode")
    terraform("apply", "-auto-approve")
    if calls.read_text().splitlines() != ["invoke", "invoke"]:
        raise SystemExit("Expected one failed invoke, one recovery invoke and no replay on re-apply.")
    print("Failed bootstrap taints its local marker; the next plan replaces it, then a successful re-apply does not replay.")


def run():
    # Copy production files, not a second implementation. Never initialise the live backend.
    with tempfile.TemporaryDirectory(prefix="pdc-rotation-tests-") as temporary:
        directory = Path(temporary)
        for name in (
            "versions.tf",
            "grafana-cloud-stack.tf",
            "grafana-cloud-pdc-accounts.tf",
            "grafana-cloud-pdc-bootstrap.tf",
            "grafana-cloud-pdc-enrolment.tf",
            "grafana-cloud-pdc-rotation.tf",
            "grafana-cloud-pdc-rotator.tf",
        ):
            shutil.copyfile(ROOT / name, directory / name)
        for name in ("main.tf", "providers.tf"):
            shutil.copyfile(FIXTURE / name, directory / name)
        configuration = directory / "configuration"
        shutil.copytree(FIXTURE / "configuration", configuration)
        shutil.copyfile(
            ROOT / "grafana-cloud-tenant-environment-configurations.tf",
            configuration / "grafana-cloud-tenant-environment-configurations.tf",
        )
        shutil.copytree(
            ROOT / "modules" / "grafana-cloud" / "tenant-configuration",
            configuration / "modules" / "grafana-cloud" / "tenant-configuration",
        )
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

        check_enrolment_order(directory, environment)
        # terraform test also destroys its disposable resources: removal must not invoke again.
        if not calls.exists() or calls.read_text().splitlines() != ["invoke"]:
            raise SystemExit("Expected exactly one synchronous bootstrap across creation, image update, tick target replacement and teardown.")
        print("Exactly one bootstrap invocation; no replay on image update, tick target replacement or removal.")
        bootstrap_environment = environment | {
            "PDC_FUNCTION_ARN": environment["EXPECTED_FUNCTION_ARN"],
            "PDC_SECRET_ARN": environment["EXPECTED_SECRET_ARN"],
        }
        check_bootstrap_retries(helper, bootstrap_environment)
        check_bootstrap_recovery(directory, bootstrap_environment)

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


if __name__ == "__main__":
    run()
