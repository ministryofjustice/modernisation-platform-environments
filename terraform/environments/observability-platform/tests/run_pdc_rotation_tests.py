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


def check_cp3_handoff(directory, environment):
    """Plan from the previously applied tenant; only mock providers and the AWS stub are used."""
    handoff = "grafana-cloud-pdc-cp3-handoff.tf"
    previous = directory / "before_cp3_handoff"
    previous.mkdir()
    shutil.copyfile(FIXTURE / "cp3-data-sources.tf", directory / "cp3-data-sources.tf")
    shutil.copytree(ROOT / "modules/grafana-cloud/aws-account-data-sources", directory / "aws-account-data-sources")
    for path in [*directory.glob("*.tf"), directory / "contrib", directory / "aws-account-data-sources"]:
        if path.name != handoff:
            (previous / path.name).symlink_to(path)
    shutil.copytree(directory / "configuration", previous / "configuration")
    (previous / "configuration" / "accounts_override.tf").write_text("""
module "grafana_cloud_tenant_configuration" {
  tenants = merge(local.environment_configuration_gc.tenant_configuration, {
    cloud-platform = { aws_accounts = { for stage in ["development", "preproduction", "nonlive", "live"] :
      "cloud-platform-${stage}" => { pdc_enabled = true } } }
  })
}
""")
    # Use the same provider mocks as the metadata suite, in a separate disposable state.
    tests = directory / "handoff-tests"
    tests.mkdir()
    mocks = (directory / "tests/metadata.tftest.hcl").read_text().split('\nrun "', 1)[0]
    (tests / "cp3.tftest.hcl").write_text(mocks + (FIXTURE / "cp3-handoff.hcl").read_text())
    calls = directory / "handoff-invocations"
    env = environment | {
        "PDC_TEST_INVOCATIONS": str(calls),
        "EXPECTED_SECRET_ARN": f"arn:aws:secretsmanager:eu-west-2:{4:012d}:secret:grafana-cloud/pdc/mock-ABCDEF",
    }
    subprocess.run(["terraform", "init", "-backend=false", "-test-directory=handoff-tests", "-no-color"],
                   cwd=directory, env=env, check=True, stdout=subprocess.DEVNULL)
    run = subprocess.run(["terraform", "test", "-test-directory=handoff-tests", "-json", "-verbose"],
                         cwd=directory, env=env, text=True, capture_output=True)
    events = [json.loads(line) for line in run.stdout.splitlines()]
    if run.returncode:
        raise SystemExit(run.stderr + "\n".join(e["@message"] for e in events if e["type"] == "diagnostic"))
    plan, = [e["test_plan"] for e in events if e["type"] == "test_plan"]
    actual = {
        (r.get("previous_address"), r["address"]): r["change"]["actions"]
        for r in plan["resource_changes"] if r["mode"] == "managed" and r["change"]["actions"] != ["no-op"]
    }
    expected = {(None, f'{resource}["this"]'): ["update"] for resource in (
        "aws_iam_policy.gc_pdc_rotator", "aws_kms_key.gc_pdc_failure_alerts", "aws_sns_topic_policy.gc_pdc_failure_alerts",
    )}
    for stage in ("preproduction", "nonlive", "live"):
        key = f'["cloud-platform-{stage}"]'
        for resource in ("aws_secretsmanager_secret", "aws_kms_key"):
            expected[(f"{resource}.gc_pdc_token{key}", f"{resource}.cp3_{stage}_handoff")] = ["forget"]
        for resource in (
            "grafana_cloud_private_data_source_connect_network.account", "aws_kms_alias.gc_pdc_token",
            "aws_secretsmanager_secret_policy.gc_pdc_token", "terraform_data.gc_pdc_bootstrap",
            "aws_cloudwatch_event_rule.gc_pdc_enrolment", "aws_cloudwatch_event_target.gc_pdc_enrolment",
            "aws_lambda_permission.gc_pdc_enrolment_tick", "aws_lambda_permission.gc_pdc_enrolment_rotation",
            "aws_cloudwatch_metric_alarm.gc_pdc_enrolment_delivery",
        ):
            expected[(None, resource + key)] = ["delete"]
        for resource in ("grafana_data_source.cloudwatch[0]", 'grafana_data_source_permission.this["cloudwatch"]'):
            expected[(None, f"module.grafana_cloud_aws_data_sources{key}.{resource}")] = ["delete"]
    if actual != expected:
        raise SystemExit(f"Unexpected managed changes in CP3 handoff: {actual}")
    if calls.read_text().splitlines() != ["invoke"] * 5:
        raise SystemExit("Expected bootstrap only for Example and the four original CP3 accounts, never on teardown.")
    print("CP3 handoff: 6 exact secret/key forgets, 33 scoped deletes, 3 shared policy updates; no other managed changes.")


def run():
    # Copy production files, not a second implementation. Never initialise the live backend.
    with tempfile.TemporaryDirectory(prefix="pdc-rotation-tests-") as temporary:
        directory = Path(temporary)
        for name in (
            "versions.tf",
            "grafana-cloud-stack.tf",
            "grafana-cloud-pdc-accounts.tf",
            "grafana-cloud-pdc-cp3-handoff.tf",
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
        run_declarative_handoff_test(environment)
        check_cp3_handoff(directory, environment)


if __name__ == "__main__":
    run()
