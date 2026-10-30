# Push to SFTP

This component sends clean files from S3 to a recipient's SFTP server. It runs in `eu-west-2` and has its own Terraform state in the file-transfer account.

## Set up a recipient

1. Deploy the parent file-transfer component first. This component looks up its event bus, clean bucket, KMS keys and PagerDuty topics.
2. Add a `push-to-sftp` action to the shared [file-dispatch configuration](../modules/file-dispatch-configuration/README.md#action-configuration), then deploy the parent and this component. For an existing dispatch secret, update its action in Secrets Manager through the approved operator process: Terraform ignores subsequent changes to the secret value.
3. Use the `credential_secrets` and `operator_policy_arns` outputs to populate the keypair secrets through approved operator tooling. The private secret contains JSON with `private_key` and an optional `passphrase`; the public secret contains the OpenSSH client public key. The operator policies are created but not attached. Do not put private keys or passphrases in Terraform, events or logs.
4. Ask the recipient to install the client public key. Verify the server host keys through a separate channel, agree the allowed IPv4 CIDRs and check that the destination directory exists. The server must support exclusive temporary-file creation and POSIX overwrite rename.
5. Test with a non-sensitive file. Check both the file on the recipient's server and the completion event before sending service files.

The shared pipeline is enabled even when no recipients are configured. In that case, no per-entry roles or keypair secrets are created, and both Lambdas reject requests without an authorised configuration. Having the infrastructure deployed does not mean a recipient is ready or the service is available to customers.

The writer reads the dispatch secret version named in the request and checks its settings against those authorised by Terraform. It assumes the entry's delivery role to read its clean source prefix and private-key secret. The writer uses the `AWSCURRENT` credential version; coordinate key rotation with the recipient before changing it.

## Network access

The writer uses one shared private subnet in development and test, and all selected private subnets in preproduction and production. Its security group allows SFTP to the configured recipient CIDRs and ports, HTTPS to shared protected-subnet CIDRs, and HTTPS to the regional S3 and DynamoDB managed prefix lists.

Check that the shared VPC has the following endpoints. This component does not create them.

| Service         | Endpoint                                 | What to check                                                                                |
| --------------- | ---------------------------------------- | -------------------------------------------------------------------------------------------- |
| S3              | `com.amazonaws.eu-west-2.s3`             | Gateway endpoint associated with the writer's private-subnet route tables                    |
| DynamoDB        | `com.amazonaws.eu-west-2.dynamodb`       | Gateway endpoint associated with the writer's private-subnet route tables                    |
| Secrets Manager | `com.amazonaws.eu-west-2.secretsmanager` | Interface endpoint in an allowed protected subnet                                            |
| STS             | `com.amazonaws.eu-west-2.sts`            | Interface endpoint in an allowed protected subnet; the client uses the regional STS endpoint |
| EventBridge     | `com.amazonaws.eu-west-2.events`         | Interface endpoint in an allowed protected subnet                                            |

For the interface endpoints, check private DNS and allow inbound TCP/443 from the writer in the endpoint security groups. Check endpoint policies and network ACLs too. For the gateway endpoints, check the routes: security-group rules alone do not create them. Gateway endpoints use regional service IP addresses rather than subnet network interfaces, so the writer also needs the prefix-list rules.

Check DNS and the route to the recipient's SFTP server before testing a delivery.

## How delivery works

An EventBridge rule sends `FileActionExecutionRequested.v1` events for this pattern through an encrypted SNS topic and SQS queue to the writer Lambda. EventBridge, SNS and the processing queue each have an encrypted dead-letter queue (DLQ). A separate Lambda reports terminal failures from those queues to the event bus.

The writer handles one message at a time, with a 900-second timeout and a maximum concurrency of five. The processing queue has a 5,400-second visibility timeout and sends a message to its DLQ after five receives. The reporter handles batches of up to ten, with a 60-second timeout and a maximum concurrency of two per DLQ. DLQ visibility is 360 seconds. Both functions return partial batch failures.

The reporter does not start another record with 30 seconds or less remaining, or another DynamoDB or EventBridge call with 15 seconds or less remaining. Its AWS clients use a two-second connection timeout, a three-second read timeout and two total attempts. Unfinished and unstarted records are returned for retry; earlier successful records are acknowledged. Powertools emits
`ReporterRecordDeferred` and a warning for deadline deferrals, separately from processing failures. Deferral does not mean delivery failed, and existing leases and checkpoints remain in place.

The writer reads the exact clean S3 object version and streams it to a temporary file on the SFTP server. It checks the byte count, then renames the temporary file over the destination. The destination path combines the configured destination prefix with the source key relative to its authorised source prefix. The clean S3 object is retained under the parent component's lifecycle policy; the
recipient manages retention on their server.

The writer checks its 90-second reserve before reading or writing each 32 KiB chunk and before the final SFTP checks and rename. DynamoDB and completion-publication calls require more than 45 seconds remaining, allowing a checkpointed upload to defer publication without reconnecting. Writer AWS clients retain five-second connection and 15-second read timeouts with two total attempts. The SFTP
connection timeout remains ten seconds and its I/O timeout remains 15 seconds.

These are cooperative deadline checks, not hard end-to-end operation limits: DNS and repeated socket reads can outlast the nominal timeouts. Setup consumes part of the transfer window, and a retry before the `COPIED` checkpoint starts the upload again rather than resuming it. Validate the largest expected files against measured recipient throughput before agreeing a supported operating envelope;
these settings do not establish a maximum supported file size or delivery-time guarantee.

The EventBridge publish grant is scoped to the SNS topic, and its KMS grant to the transport key. Source-account and source-ARN conditions are omitted from those grants in line with [SNS topic-policy](https://docs.aws.amazon.com/eventbridge/latest/userguide/eb-use-resource-based.html#sns-permissions) and
[KMS](https://docs.aws.amazon.com/sns/latest/dg/sns-key-management.html#compatibility-with-aws-services) guidance.

## Failures and recovery

DynamoDB stores leases, a `COPIED` checkpoint and terminal outcomes. If a retry finds the `COPIED` checkpoint, it republishes the completion event without uploading the file again. Deduplication and terminal records use seven-day retention windows. DynamoDB TTL removal is asynchronous, and a record may outlive the source file.

If delivery fails before the `COPIED` checkpoint, the file may already be on the server. A retry may overwrite it. Check with the recipient before taking further action; a failed completion does not prove that the file is absent. Do not delete idempotency records, bypass leases or manufacture requests to force a retry. Malformed or unauthorised DLQ messages remain in the queue for investigation.

The [CloudWatch alarms](./locals-cloudwatch.tf) cover DLQ backlogs, record failures, Lambda errors, throttles and duration, processing-message age, and terminal delivery failures. They use the parent component's PagerDuty routing. Terminal delivery failure alarms do not send OK notifications: resolve the incident after investigation, not just because the metric goes quiet.

Duration alarms use the maximum invocation duration over one five-minute period, warning above 720 seconds for the writer and 48 seconds for the reporter. These are retrospective capacity warnings, not evidence that a delivery failed. Deadline deferrals remain visible through `ReporterRecordDeferred` and the existing DLQ backlog alarms.

## Terraform outputs

- `pipeline`: EventBridge rule, SNS topic, processing queue, DLQs and reporter ARNs.
- `delivery_roles`: each entry's identity, source prefix, destination hostname and prefix, and role ARN.
- `credential_secrets`: the private and public key secret ARNs for each entry.
- `operator_policy_arns`: the unattached public-key reader and key-custodian policies for each entry.
- `delivery_role_arns`, `processing_queue_url` and `dead_letter_queue_urls`: role ARNs and queue URLs.

## Local checks

Terraform builds both Python 3.12 packages in an x86 Docker container, so the workflow does not need ARM emulation. Pip installs only ARM64 Linux wheels compatible with the Lambda runtime; the build fails if a dependency has no compatible wheel.

The Lambda module uses its default SAM build image. Do not set `docker_image` to the SAM image tag without also providing a local image or a Docker build configuration: the module tries to build a missing custom image rather than pulling it.

Run these checks from the repository root:

```shell
terraform fmt -check -recursive terraform/environments/integration-hub-file-transfer/push-to-sftp
env AWS_ACCESS_KEY_ID=dummy AWS_SECRET_ACCESS_KEY=dummy AWS_SESSION_TOKEN=dummy \
  AWS_DEFAULT_REGION=eu-west-2 AWS_EC2_METADATA_DISABLED=true \
  PYTHONPATH=terraform/environments/integration-hub-file-transfer/push-to-sftp/lambda/push-to-sftp-writer \
  uv run --no-project --python 3.12 \
  --with-requirements terraform/environments/integration-hub-file-transfer/push-to-sftp/lambda/push-to-sftp-writer/requirements.txt \
  --with-requirements terraform/environments/integration-hub-file-transfer/push-to-sftp/lambda/push-to-sftp-writer/tests/requirements.txt \
  python -m pytest -q terraform/environments/integration-hub-file-transfer/push-to-sftp/lambda/push-to-sftp-writer/tests
```

The tests use dummy credentials and disable EC2 metadata lookup. Neither these tests nor `terraform plan` builds the deployment packages. When changing dependencies or build settings, check that both packages build and their native libraries import on the ARM64 Lambda runtime. Run plans and deployments through the existing Terraform workflow; a failed package build during apply can leave other
resources in place.
