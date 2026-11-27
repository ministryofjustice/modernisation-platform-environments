"""Plan the real PDC tenant gate in every CP3 network workspace, with a mocked AWS provider in a disposable root."""

import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile


NETWORK = Path(__file__).resolve().parents[1]
FIXTURE = NETWORK / "tests" / "pdc-tenant"

# Expected state of observability_platform.tf: every workspace runs an agent, and only
# cloud-platform-development uses the development stack.
DEVELOPMENT_STACK = {"cloud-platform-development"}

# Synthetic IDs from the fixture
OP_ACCOUNTS = {"development": "000000000001", "production": "000000000002"}
TENANT_ACCOUNT = "000000000011"
SUBNETS = {"subnet-0aaaaaaaaaaaaaaaa", "subnet-0bbbbbbbbbbbbbbbb", "subnet-0cccccccccccccccc"}

# Grafana Cloud stack IDs, from the tenant module
STACK_IDS = {"development": "1907843", "production": "1907875"}

MODULE = "module.observability_platform_tenant[0]."
PDC = MODULE + "module.grafana_cloud[0]."
AMAZON_MANAGED_GRAFANA = MODULE + "module.amazon_managed_grafana"
TENANT_RESOURCES = 18


def workspaces():
    accounts = json.loads((NETWORK.parent / "accounts.json").read_text(encoding="utf-8"))["accounts"]
    return [
        "cloud-platform-development",
        "cloud-platform-preproduction",
        "cloud-platform-nonlive",
        "cloud-platform-live",
        *accounts,
    ]


def terraform(directory, environment, *arguments, stdin=None):
    result = subprocess.run(
        ["terraform", *arguments],
        cwd=directory,
        env=environment,
        input=stdin,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        check=False,
    )
    if result.returncode:
        print(result.stdout)
        raise SystemExit(f"terraform {' '.join(arguments)} failed in {environment.get('TF_WORKSPACE', 'default')}.")
    return result.stdout


def plan(directory, environment, workspace):
    output = terraform(directory, environment | {"TF_WORKSPACE": workspace}, "test", "-no-color", "-json", "-verbose")
    messages = [json.loads(line) for line in output.splitlines() if line.startswith("{")]
    plans = [message["test_plan"] for message in messages if message.get("type") == "test_plan"]
    if len(plans) != 1:
        raise SystemExit(f"{workspace}: expected exactly one plan, got {len(plans)}.")
    return plans[0].get("resource_changes", [])


def primary_cidr(directory, environment, workspace):
    # The workspace's real VPC primary CIDR, from locals.tf
    expression = "local.vpc_cidr[local.cp_vpc_name].primary\n"
    output = terraform(directory, environment | {"TF_WORKSPACE": workspace}, "console", "-no-color", stdin=expression)
    return json.loads(output.strip().splitlines()[-1])


def check_enabled(workspace, changes, stack, cidr):
    def fail(reason):
        raise SystemExit(f"{workspace} ({stack}): {reason}")

    resources = {change["address"]: change for change in changes}
    if len(resources) != TENANT_RESOURCES:
        fail(f"expected {TENANT_RESOURCES} tenant resources, got {sorted(resources)}.")
    for address, change in resources.items():
        if not address.startswith(MODULE) or change["change"]["actions"] != ["create"]:
            fail(f"unexpected {change['change']['actions']} of {address}.")
        if address.startswith(AMAZON_MANAGED_GRAFANA):
            fail(f"Amazon Managed Grafana must stay disabled, got {address}.")

    def after(address):
        if PDC + address not in resources:
            fail(f"missing {PDC + address}.")
        return resources[PDC + address]["change"]["after"]

    op_account = OP_ACCOUNTS[stack]
    secret_arn = f"arn:aws:secretsmanager:eu-west-2:{op_account}:secret:grafana-cloud/pdc/{TENANT_ACCOUNT}"

    container = json.loads(after("aws_ecs_task_definition.pdc_agent[0]")["container_definitions"])[0]
    if [secret["valueFrom"] for secret in container["secrets"]] != [secret_arn]:
        fail(f"token secret is {container['secrets']}, expected {secret_arn}.")
    command = container["command"]
    if command[command.index("-gcloud-hosted-grafana-id") + 1] != STACK_IDS[stack]:
        fail(f"agent connects to {command}, expected the {stack} stack {STACK_IDS[stack]}.")
    if command[:4] != [
        "-api-fqdn",
        "pdc-grafana-datasources-api.eu-west-2.vpce.grafana.net",
        "-gateway-fqdn",
        "pdc-grafana-datasources.eu-west-2.vpce.grafana.net",
    ]:
        fail(f"agent does not use the PDC PrivateLink endpoints: {command}.")

    token_policy = json.loads(after("aws_iam_role_policy.pdc_agent_token[0]")["policy"])
    if secret_arn not in json.dumps(token_policy["Statement"][0]["Resource"]):
        fail(f"execution role cannot read {secret_arn}: {token_policy}.")
    kms = f"arn:aws:kms:eu-west-2:{op_account}:key/*"
    if kms not in json.dumps(token_policy):
        fail(f"execution role cannot decrypt with {kms}: {token_policy}.")

    trust = json.loads(after("aws_iam_role.pdc_agent_restarter[0]")["assume_role_policy"])["Statement"]
    rotator = f"arn:aws:iam::{op_account}:role/grafana-pdc-token-rotator"
    if trust != [
        {
            "Effect": "Allow",
            "Action": "sts:AssumeRole",
            "Principal": {"AWS": f"arn:aws:iam::{op_account}:root"},
            "Condition": {"ArnEquals": {"aws:PrincipalArn": rotator}},
        }
    ]:
        fail(f"restarter role trusts {trust}, expected only {rotator}.")

    service = after("aws_ecs_service.pdc_agent[0]")
    network = service["network_configuration"][0]
    if service["desired_count"] != 3 or set(network["subnets"]) != SUBNETS or network["assign_public_ip"]:
        fail(f"expected three private Fargate tasks in the cluster VPC private subnets: {service}.")

    egress = {
        address.split('"')[1] for address in resources if "aws_vpc_security_group_egress_rule.pdc_agent[" in address
    }
    if egress != {"0.0.0.0/0-22", "0.0.0.0/0-443", f"{cidr}-443"}:
        fail(f"unexpected agent egress {sorted(egress)}, expected the VPC primary CIDR {cidr} on 443.")

    other_account = OP_ACCOUNTS["production" if stack == "development" else "development"]
    if other_account in json.dumps(changes):
        fail(f"plan references the other Observability Platform account {other_account}.")
    print(
        f"{workspace}: {TENANT_RESOURCES} to add, {stack} stack {STACK_IDS[stack]} "
        f"and Observability Platform {stack} account."
    )


def run():
    # Copy production files, not a second implementation. Never initialise the live backend.
    with tempfile.TemporaryDirectory(prefix="pdc-tenant-tests-") as temporary:
        directory = Path(temporary) / "network"
        directory.mkdir()
        shutil.copyfile(NETWORK.parent / "accounts.json", directory.parent / "accounts.json")
        for name in ("locals.tf", "observability_platform.tf"):
            shutil.copyfile(NETWORK / name, directory / name)
        shutil.copyfile(FIXTURE / "main.tf", directory / "main.tf")
        shutil.copytree(FIXTURE / "cluster-vpc", directory / "cluster-vpc")
        (directory / "tests").mkdir()
        shutil.copyfile(FIXTURE / "pdc-tenant.tftest.hcl", directory / "tests" / "pdc-tenant.tftest.hcl")
        environment = os.environ | {
            "TF_IN_AUTOMATION": "1",
            "TF_INPUT": "0",
            "TF_DATA_DIR": str(directory / ".terraform"),
        }
        environment.pop("TF_WORKSPACE", None)
        terraform(directory, environment, "init", "-backend=false", "-no-color")
        for workspace in workspaces():
            terraform(directory, environment, "workspace", "new", "-no-color", workspace)
        terraform(directory, environment, "workspace", "select", "-no-color", "default")

        for workspace in workspaces():
            stack = "development" if workspace in DEVELOPMENT_STACK else "production"
            changes = plan(directory, environment, workspace)
            check_enabled(workspace, changes, stack, primary_cidr(directory, environment, workspace))


if __name__ == "__main__":
    run()
