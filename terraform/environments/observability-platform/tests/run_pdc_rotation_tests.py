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
from collections import Counter
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


def check_policy_scale(directory, environment):
    stack_id = "1907875"
    preamble = (directory / "tests" / "metadata.tftest.hcl").read_text().split('run "central_metadata_without_activation"')[0]
    preamble = preamble.replace('"12345"', f'"{stack_id}"').replace("grafana-pdc-rotation-failures-development", "grafana-pdc-rotation-failures-production")
    preamble = preamble.replace('mock_provider "aws" {', 'mock_provider "aws" {\n override_during = plan')
    preamble = preamble.replace('mock_provider "grafana" {', 'mock_provider "grafana" {\n override_during = plan')
    preamble = preamble.replace("override_resource {", "override_resource {\n override_during = plan")
    preamble = preamble.replace('mock_provider "aws" {', '''mock_provider "aws" {
  mock_resource "aws_dynamodb_table" {
    defaults = { arn = "arn:aws:dynamodb:eu-west-2:@MOCK_PLATFORM_ACCOUNT@:table/grafana-pdc-token-rotator-state" }
  }
'''.replace("@MOCK_PLATFORM_ACCOUNT@", f"{4:012d}"))
    preamble += '''
override_resource {
  target = module.grafana_pdc_token_rotator["this"].aws_cloudwatch_log_group.lambda[0]
  override_during = plan
  values = { arn = "arn:aws:logs:eu-west-2:@MOCK_PLATFORM_ACCOUNT@:log-group:/aws/lambda/grafana-pdc-token-rotator" }
}
override_resource {
  target = module.grafana_pdc_token_rotator["this"].aws_lambda_function.this[0]
  override_during = plan
  values = { arn = "arn:aws:lambda:eu-west-2:@MOCK_PLATFORM_ACCOUNT@:function:grafana-pdc-token-rotator" }
}
override_data {
  target = module.grafana_pdc_token_rotator["this"].data.aws_caller_identity.current
  values = { account_id = "@MOCK_PLATFORM_ACCOUNT@" }
}
'''.replace("@MOCK_PLATFORM_ACCOUNT@", f"{4:012d}")
    runs = []
    for count in (0, 11, 200, 211):
        accounts = "{}" if count == 0 else f'{{ for i in range({count}) : "scale-${{i}}" => {{ pdc_enabled = true }} }}'
        variables = (
            "use_environment_configuration = true" if count == 11 else
            f'accounts = {accounts}\nrotator = {{ image_digest = "sha256:{"a" * 64}", bootstrap_enabled = true }}'
        )
        runs.append(f'''
run "accounts_{count}" {{
  command = plan
  state_key = "accounts_{count}"
  variables {{
    environment = "production"
    {variables}
  }}
}}
''')
    (directory / "tests" / "policy-scale.tftest.hcl").write_text(
        preamble + "".join(runs)
    )
    module_override = directory / "scale_override.tf"
    module_override.write_text('module "grafana_pdc_token_rotator" {\n providers = { aws = aws.policy }\n}\n')
    try:
        result = subprocess.run(
            ["terraform", "test", "-json", "-verbose", "-filter=tests/policy-scale.tftest.hcl"],
            cwd=directory, env=environment, capture_output=True, text=True,
        )
    finally:
        module_override.unlink()
    if result.returncode:
        for line in result.stdout.splitlines():
            event = json.loads(line)
            if event.get("type") == "diagnostic":
                print(event["diagnostic"])
        print(result.stderr)
        raise SystemExit("Policy scale rendering failed.")
    snapshots = [json.loads(line) for line in result.stdout.splitlines() if json.loads(line).get("type") == "test_plan"]
    if len(snapshots) != 4:
        raise SystemExit("Expected four actual Terraform policy snapshots.")
    for count, snapshot in zip((0, 11, 200, 211), snapshots):
        resources = {
            change["address"]: change["change"]["after"]
            for change in snapshot["test_plan"]["resource_changes"] if change["mode"] == "managed"
        }
        if "policy" not in resources['aws_iam_policy.gc_pdc_rotator["this"]']:
            raise SystemExit("Rotator policy must be fully known in the offline scale plan.")
        policy = json.loads(resources['aws_iam_policy.gc_pdc_rotator["this"]']["policy"])

        def compact(document):
            return json.dumps(document, separators=(",", ":"), ensure_ascii=False)

        def values(value):
            return value if isinstance(value, list) else [value]

        def matches(value, pattern):
            # IAM has only * and ? wildcards; Python's fnmatch also interprets [].
            return re.fullmatch(re.escape(pattern).replace(r"\*", ".*").replace(r"\?", "."), value) is not None

        def allows(document, action, resource, context, principal=None):
            for statement in document["Statement"]:
                if statement["Effect"] != "Allow":
                    raise AssertionError("This focused evaluator supports Allow statements only.")
                if not any(matches(action, a) for a in values(statement["Action"])):
                    continue
                if not any(matches(resource, r) for r in values(statement["Resource"])):
                    continue
                if principal is not None:
                    principals = statement["Principal"]
                    if not any(matches(principal, p) for p in values(principals if isinstance(principals, str) else next(iter(principals.values())))):
                        continue
                accepted = True
                for operator, conditions in statement.get("Condition", {}).items():
                    if operator not in ("StringEquals", "ArnEquals", "ArnLike", "StringLike"):
                        raise AssertionError(f"Unsupported condition operator: {operator}")
                    for key, expected in conditions.items():
                        actual = context.get(key)
                        accepted &= actual is not None and any(
                            matches(actual, e) if operator.endswith("Like") else actual == e
                            for e in values(expected)
                        )
                if accepted:
                    return True
            return False

        central = f"{4:012d}"
        secret_prefix = f"arn:aws:secretsmanager:eu-west-2:{central}:secret:"
        secret = secret_prefix + f"grafana-cloud/pdc/{1000:012d}-ABCDEF"
        function = f"arn:aws:lambda:eu-west-2:{central}:function:grafana-pdc-token-rotator"
        role = f"arn:aws:iam::{central}:role/grafana-pdc-token-rotator"
        tags = {
            "secretsmanager:ResourceTag/pdc:rotator-stack-id": stack_id,
            "secretsmanager:ResourceTag/pdc:bootstrap": "true",
            "secretsmanager:RotationLambdaARN": function,
        }
        tenant_resources = {k: v for k, v in resources.items() if k.startswith("aws_secretsmanager_secret.gc_pdc_token[")}
        assert len(tenant_resources) == count
        account_ids = [v["tags"]["pdc:tenant-account-id"] for v in tenant_resources.values()]
        if count:
            for tenant in tenant_resources.values():
                tenant_secret = secret_prefix + tenant["name"] + "-ABCDEF"
                for action in ("DescribeSecret", "GetSecretValue", "ListSecretVersionIds", "PutSecretValue", "UpdateSecretVersionStage", "RotateSecret"):
                    assert allows(policy, "secretsmanager:" + action, tenant_secret, tags)
                assert tenant["tags"]["pdc:rotator-stack-id"] == stack_id
                assert allows(policy, "sts:AssumeRole", f'arn:aws:iam::{tenant["tags"]["pdc:tenant-account-id"]}:role/grafana-pdc-agent-restarter',
                              {"aws:ResourceAccount": tenant["tags"]["pdc:tenant-account-id"]})
            for bad_secret in (
                secret_prefix + "grafana-cloud/pdc-token-rotator/management-token-ABCDEF",
                secret_prefix + "grafana-cloud/pdc-token-rotator/stack-query-token-ABCDEF",
                secret_prefix + "unrelated/secret-ABCDEF",
                secret.replace("eu-west-2", "eu-west-1"),
                secret.replace(central, f"{5:012d}"),
                secret + "X",
            ):
                assert not allows(policy, "secretsmanager:PutSecretValue", bad_secret, tags)
            for bad_tags in ({}, tags | {"secretsmanager:ResourceTag/pdc:rotator-stack-id": "other-stack"}):
                assert not allows(policy, "secretsmanager:GetSecretValue", secret, bad_tags)
            for bad_tags in (
                {k: v for k, v in tags.items() if k != "secretsmanager:ResourceTag/pdc:bootstrap"},
                tags | {"secretsmanager:ResourceTag/pdc:bootstrap": "false"},
                tags | {"secretsmanager:RotationLambdaARN": function + ":1"},
            ):
                assert not allows(policy, "secretsmanager:RotateSecret", secret, bad_tags)
            assert not allows(policy, "secretsmanager:DeleteSecret", secret, tags)
            assert not allows(policy, "sts:AssumeRole", f"arn:aws:iam::{9999:012d}:role/grafana-pdc-agent-restarter", {"aws:ResourceAccount": f"{9999:012d}"})
            for name in ("other-role", "path/grafana-pdc-agent-restarter", "grafana-pdc-agent-restarter-extra"):
                assert not allows(policy, "sts:AssumeRole", f"arn:aws:iam::{account_ids[0]}:role/{name}", {"aws:ResourceAccount": account_ids[0]})
            assert not allows(policy, "sts:AssumeRole", f"arn:aws:iam::{account_ids[0]}:role/grafana-pdc-agent-restarter", {})
        else:
            assert not allows(policy, "secretsmanager:GetSecretValue", secret, tags)
            assert not allows(policy, "sts:AssumeRole", f"arn:aws:iam::{1000:012d}:role/grafana-pdc-agent-restarter", {"aws:ResourceAccount": f"{1000:012d}"})

        for credential in ("management-token", "stack-query-token"):
            arn = secret_prefix + f"grafana-cloud/pdc-token-rotator/{credential}-ABCDEF"
            assert allows(policy, "secretsmanager:GetSecretValue", arn, {})
            assert not allows(policy, "secretsmanager:PutSecretValue", arn, tags)
            key = resources[f'aws_kms_key.gc_pdc_rotator_credential["{credential}"]']["arn"]
            context = {"kms:ViaService": "secretsmanager.eu-west-2.amazonaws.com", "kms:EncryptionContext:SecretARN": arn}
            assert allows(policy, "kms:Decrypt", key, context)
            assert not allows(policy, "kms:GenerateDataKey", key, context)
            assert not allows(policy, "kms:Decrypt", key, context | {"kms:EncryptionContext:SecretARN": secret})

        for address, tenant in tenant_resources.items():
            key = resources[address.replace("aws_secretsmanager_secret.", "aws_kms_key.")]
            document = json.loads(key["policy"])
            grant = {"Statement": [s for s in document["Statement"] if s["Sid"] == "AllowRotatorForThisSecret"]}
            assert len(grant["Statement"]) == 1
            context = {
                "aws:PrincipalArn": role,
                "kms:ViaService": "secretsmanager.eu-west-2.amazonaws.com",
                "kms:EncryptionContext:SecretARN": secret_prefix + tenant["name"] + "-ABCDEF",
            }
            for action in ("kms:Decrypt", "kms:GenerateDataKey"):
                assert allows(grant, action, key["arn"], context, role)
            for bad_context in (
                context | {"aws:PrincipalArn": role + "-other"},
                context | {"kms:ViaService": "secretsmanager.eu-west-1.amazonaws.com"},
                context | {"kms:EncryptionContext:SecretARN": secret_prefix + f"grafana-cloud/pdc/{9999:012d}-ABCDEF"},
                context | {"kms:EncryptionContext:SecretARN": secret_prefix + "grafana-cloud/pdc-token-rotator/management-token-ABCDEF"},
                {k: v for k, v in context.items() if k != "kms:ViaService"},
            ):
                assert not allows(grant, "kms:Decrypt", key["arn"], bad_context, bad_context["aws:PrincipalArn"])
            assert not allows(grant, "kms:Encrypt", key["arn"], context, role)

        topic = resources['aws_sns_topic.gc_pdc_failure_alerts["this"]']["arn"]
        sns = json.loads(resources['aws_sns_topic_policy.gc_pdc_failure_alerts["this"]']["policy"])
        alert_key = resources['aws_kms_key.gc_pdc_failure_alerts["this"]']
        kms = json.loads(alert_key["policy"])
        alarm_prefix = f"arn:aws:cloudwatch:eu-west-2:{central}:alarm:"
        alarms = [v["alarm_name"] for k, v in resources.items() if k.startswith("aws_cloudwatch_metric_alarm.")]
        assert len(alarms) == count + 1
        for alarm in alarms:
            context = {"aws:SourceAccount": central, "aws:SourceArn": alarm_prefix + alarm}
            assert allows(sns, "sns:Publish", topic, context, "cloudwatch.amazonaws.com")
            for action in ("kms:Decrypt", "kms:GenerateDataKey"):
                assert allows(kms, action, alert_key["arn"], context, "cloudwatch.amazonaws.com")
        for context in (
            {"aws:SourceAccount": central, "aws:SourceArn": alarm_prefix + "unrelated"},
            {"aws:SourceAccount": central, "aws:SourceArn": alarm_prefix + "pdc-enrol-tenant-not-a-delivery-alarm"},
            {"aws:SourceAccount": f"{5:012d}", "aws:SourceArn": alarm_prefix + "pdc-enrol-tenant-delivery-failed"},
            {"aws:SourceAccount": central, "aws:SourceArn": alarm_prefix.replace("eu-west-2", "eu-west-1") + "pdc-enrol-tenant-delivery-failed"},
        ):
            assert not allows(sns, "sns:Publish", topic, context, "cloudwatch.amazonaws.com")
            assert not allows(kms, "kms:GenerateDataKey", alert_key["arn"], context, "cloudwatch.amazonaws.com")

        managed_sizes = {}
        attachments = Counter()
        inline_sizes = Counter()
        for address, resource in resources.items():
            resource_type = address.split(".")[-2]
            if resource_type in ("aws_iam_policy", "aws_iam_role_policy"):
                size = len(compact(json.loads(resource["policy"])))
                if resource_type == "aws_iam_policy":
                    assert size <= 6144, (count, address, size)
                    managed_sizes[address] = size
                else:
                    inline_sizes[resource["role"]] += size
            if resource_type == "aws_iam_role_policy_attachment":
                attachments[resource["role"]] += 1
            if resource_type == "aws_kms_key":
                assert len(resource["policy"].encode()) <= 32768
            if resource_type == "aws_sns_topic_policy":
                assert len(resource["policy"].encode()) <= 30720
            if resource_type == "aws_secretsmanager_secret_policy":
                assert len(resource["policy"].encode()) <= 20480
        assert len(managed_sizes) == 1
        assert max(attachments.values(), default=0) <= 10
        assert max(inline_sizes.values(), default=0) <= 10240

        # AddPermission's resulting statements, with worst-case 100-character Sids.
        permissions = [v for k, v in resources.items() if ".aws_lambda_permission." in "." + k]
        lambda_policy = {"Version": "2012-10-17", "Statement": []}
        for permission in permissions:
            conditions = {}
            if permission.get("source_arn"):
                conditions["ArnLike"] = {"AWS:SourceArn": permission["source_arn"]}
            if permission.get("source_account"):
                conditions["StringEquals"] = {"AWS:SourceAccount": permission["source_account"]}
            lambda_policy["Statement"].append({
                "Sid": "s" * 100, "Effect": "Allow",
                "Principal": {"AWS" if permission["principal"].startswith("arn:") else "Service": permission["principal"]},
                "Action": permission["action"], "Resource": function, "Condition": conditions,
            })
        assert len(permissions) == (3 if count else 0)
        assert len(compact(lambda_policy).encode()) <= 20480
        for permission in permissions:
            if permission["principal"] not in ("events.amazonaws.com", "secretsmanager.amazonaws.com"):
                continue
            for address, tenant in tenant_resources.items():
                name = address.split('["')[1][:-2]
                source = (
                    f"arn:aws:events:eu-west-2:{central}:rule/pdc-enrol-{name}"
                    if permission["principal"] == "events.amazonaws.com" else secret_prefix + tenant["name"] + "-ABCDEF"
                )
                assert matches(source, permission["source_arn"])
                assert permission["source_account"] == central
                assert not matches(source.replace("eu-west-2", "eu-west-1"), permission["source_arn"])
                assert not matches(source.replace(central, f"{5:012d}"), permission["source_arn"])
                unrelated_source = (
                    f"arn:aws:events:eu-west-2:{central}:rule/unrelated"
                    if permission["principal"] == "events.amazonaws.com" else secret_prefix + "grafana-cloud/pdc-token-rotator/management-token-ABCDEF"
                )
                assert not matches(unrelated_source, permission["source_arn"])

        sns_size = len(resources['aws_sns_topic_policy.gc_pdc_failure_alerts["this"]']["policy"].encode())
        tenant_key_size = max((len(v["policy"].encode()) for k, v in resources.items() if k.startswith("aws_kms_key.gc_pdc_token[")), default=0)
        print(f"Policy scale {count}: managed={managed_sizes}, tenant KMS max={tenant_key_size}, alert KMS={len(alert_key['policy'].encode())}, SNS={sns_size}, Lambda upper bound={len(compact(lambda_policy))}, attachments/role={max(attachments.values(), default=0)}, inline aggregate={max(inline_sizes.values(), default=0)}.")


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
        for name in ("main.tf", "providers.tf", "policy_override.tf"):
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
        check_policy_scale(directory, environment)

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
