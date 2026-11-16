import logging
import os
import shlex
import time

import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)

ssm = boto3.client("ssm")

INSTANCE_ID = os.environ["INSTANCE_ID"]
SECRET_ID = os.environ["SECRET_ID"]

TERMINAL_STATES = {"Success", "Cancelled", "TimedOut", "Failed"}

# Generates a fresh ED25519 keypair on the instance itself, overwrites
# ec2-user's authorized_keys with the new public key, and writes both keys
# into the Secrets Manager secret the team's scp/sftp workflow already reads
# from. Mirrors what new-userdata.sh did once at boot, just re-run on a
# schedule. Runs as root (the SSM agent's default execution user).
ROTATE_SCRIPT = """
set -euo pipefail
WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR"' EXIT
KEY_PATH="$WORKDIR/id_ed25519"

ssh-keygen -t ed25519 -f "$KEY_PATH" -N "" -C "oas-ssh-key-rotated-$(date -u +%Y%m%dT%H%M%SZ)" >/dev/null

install -d -m 700 -o ec2-user -g ec2-user /home/ec2-user/.ssh
install -m 600 -o ec2-user -g ec2-user "$KEY_PATH.pub" /home/ec2-user/.ssh/authorized_keys

SECRET_JSON=$(jq -n --rawfile priv "$KEY_PATH" --rawfile pub "$KEY_PATH.pub" '{private_key: $priv, public_key: $pub}')
aws secretsmanager put-secret-value --secret-id "$SSH_SECRET_ID" --region "$SSH_ROTATE_REGION" --secret-string "$SECRET_JSON" >/dev/null

echo "SSH key rotated for ec2-user, new key pushed to authorized_keys and Secrets Manager"
""".strip()


def lambda_handler(event, context):
    """Rotate the OAS EC2 instance's ec2-user SSH key pair.

    The key_name/aws_key_pair binding on aws_instance only matters at first
    boot, so rotation bypasses it entirely: this Lambda just triggers the
    same authorized_keys-writing mechanism the old userdata block used once,
    via SSM RunShellScript, on a schedule. All key generation and the
    Secrets Manager write happen on the instance under its own IAM role -
    the Lambda never sees the key material.
    """
    region = boto3.session.Session().region_name
    commands = [
        f"export SSH_SECRET_ID={shlex.quote(SECRET_ID)}",
        f"export SSH_ROTATE_REGION={shlex.quote(region)}",
        ROTATE_SCRIPT,
    ]

    send_response = ssm.send_command(
        InstanceIds=[INSTANCE_ID],
        DocumentName="AWS-RunShellScript",
        Comment="Rotate OAS EC2 SSH key pair (ec2-user)",
        Parameters={"commands": commands},
    )
    command_id = send_response["Command"]["CommandId"]
    logger.info("Sent SSH key rotation command %s to instance %s", command_id, INSTANCE_ID)

    status = _wait_for_command(command_id)

    if status != "Success":
        raise RuntimeError(f"SSH key rotation command {command_id} ended with status {status}")

    logger.info("SSH key rotation complete for instance %s", INSTANCE_ID)
    return {
        "statusCode": 200,
        "body": f"SSH key rotated for {INSTANCE_ID}",
        "commandId": command_id,
    }


def _wait_for_command(command_id, attempts=20, delay_seconds=4):
    """Poll GetCommandInvocation until the command reaches a terminal state."""
    status = "Pending"

    for _ in range(attempts):
        time.sleep(delay_seconds)
        try:
            invocation = ssm.get_command_invocation(CommandId=command_id, InstanceId=INSTANCE_ID)
        except ssm.exceptions.InvocationDoesNotExist:
            continue

        status = invocation["Status"]
        if status in TERMINAL_STATES:
            if status != "Success":
                logger.error("Command %s failed: %s", command_id, invocation.get("StandardErrorContent"))
            return status

    logger.error("Command %s did not reach a terminal state within the polling window", command_id)
    return status
