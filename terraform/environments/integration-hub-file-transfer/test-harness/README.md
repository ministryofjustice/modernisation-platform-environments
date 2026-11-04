# File-transfer test harness

This component provides test-only infrastructure for Integration Hub live tests
in `eu-west-2`. It supplies a GitHub OIDC role, an isolated push-to-S3 destination
with a dedicated KMS key, and a private SFTP server with an S3 read-back bucket.
Together with service-owned pickup storage, these support push-to-S3, hosted
pickup, push-to-SFTP and presigned-pickup tests through the existing file-transfer
pipeline.

The live-test scripts and GitHub Actions workflows belong to the
`ministryofjustice/integration-hub` repository under `tests/file-transfer/`.
This component defines their AWS access and simulated recipients, not the tests
themselves. Its resources are created only in the test environment.

## Architecture

1. A GitHub Actions job assumes the harness role and uploads a non-sensitive
	fixture to a route-specific prefix in the incoming bucket.
2. The parent file-transfer pipeline processes the uploaded object version.
	Only a positive clean malware scan permits clean-file dispatch.
3. Shared dispatch configuration selects the action or notification for that
	source prefix. The corresponding service component delivers or retains the
	clean file using its own execution role.
4. For SFTP, an agent on the recipient server copies completed uploads into the
  read-back bucket. Other routes are observed in their destination or pickup bucket.
5. The test uses the harness role to inspect the result within its permitted
  prefix, comparing contents or checking access restrictions as appropriate.

| Component | Responsibility |
| --- | --- |
| `test-harness` | GitHub test role, simulated customer destination bucket and its encryption key, test SFTP server and its read-back bucket |
| Parent file-transfer service | Incoming and clean storage, malware-processing pipeline and dispatch secrets |
| `push-to-s3` | Copies clean files to the harness-owned destination |
| `push-to-s3-with-hosted-pickup` | Provisions hosted recipient storage and copies clean files into it |
| `push-to-sftp` | Uploads clean files to the harness-owned test SFTP server |
| `pull-from-presigned-url` | Retains recipient files in shared pickup storage and manages pickup grants and notifications |

The GitHub harness role has no destination-write permissions. Service components
perform delivery; a separate instance role lets the SFTP server publish read-back
copies. There is no separate scanning pipeline or test bypass of clean-file dispatch.

## Routes and destinations

All fixtures enter `integration-hub-file-transfer-test-incoming`. The
[shared test dispatch configuration](../modules/file-dispatch-configuration/locals-test.tf)
defines four routes under the `test-harness` identity.

| Route | Incoming prefix | Observed bucket | Observed prefix |
| --- | --- | --- | --- |
| Push to S3 | `test-harness/push-to-s3/` | `integration-hub-file-transfer-test-test-harness` | `push-to-s3/` |
| Hosted pickup | `test-harness/hosted-pickup/` | `integration-hub-test-test-harness-pickup` | `pickup/` |
| Push to SFTP | `test-harness/push-to-sftp/` | `integration-hub-file-transfer-test-test-harness-sftp` (read-back copy) | `push-to-sftp/` |
| Presigned pickup | `test-harness/pull-from-presigned-url/` | `integration-hub-file-transfer-pickup-test-<account-id>` | `test-harness-presigned/` |

Push-to-S3, hosted pickup and push-to-SFTP use their respective delivery actions,
with no notifications configured. The SFTP writer delivers to `incoming/` inside
the server's chroot; the table shows the S3 copy used for assertions, not the SFTP
destination. The presigned route has `action = null` and a Slack notification for
recipient `test-harness-presigned`; its notification component retains the clean
copy for pickup.

The presigned recipient is configured for the `azure-aws-sso-integration-hub`
Identity Center group and `#integration-hub-test-alerts` in the Justice Digital
Slack workspace. Web-app membership is managed by the parent configuration;
pickup grants are managed by the presigned component. Slack channel membership
does not itself grant file access.

### SFTP delivery and read-back

The recipient is an OpenSSH `internal-sftp` server on a `t3.micro` instance with
an encrypted 8 GiB root volume. It uses host address 100 in the shared private
subnet with the first sorted subnet ID. The harness and shared dispatch module
derive this address independently from matching subnet lookups, so those lookups
must remain aligned. Dispatch pins the server's public host key and restricts
the destination network to that address's `/32`.

The writer uploads temporary files and renames them into their completed paths
under `incoming/`. A server agent runs `aws s3 sync` to the read-back prefix,
excluding `.mft-*` files, with a five-second pause between iterations. GitHub
Actions observes this S3 copy without requiring direct access to the private
SFTP endpoint. The agent copies files; it does not delete the server originals.

## Access boundaries

GitHub OIDC trust accepts jobs using the `smoke-test` environment in
`ministryofjustice/integration-hub` or
`ministryofjustice/modernisation-platform-environments`, with audience
`sts.amazonaws.com`. Jobs require `environment: smoke-test` and
`id-token: write`. Branch restrictions and required reviewers belong to the
GitHub environment protection rules, not the IAM trust policy.

| Scope | Harness permissions |
| --- | --- |
| Incoming storage | Upload and encrypt fixtures beneath the four test prefixes |
| Clean storage | List object versions beneath those prefixes, without reading file contents |
| Dispatch configuration | Describe the four route secrets, without reading their values |
| Delivery functions | Invoke the push-to-S3, hosted-pickup and push-to-SFTP writers |
| Push-to-S3 destination | List, read and decrypt objects beneath `push-to-s3/` |
| Hosted destination | List, read and decrypt objects beneath `pickup/`; read lifecycle configuration |
| SFTP read-back copy | List and read objects beneath `push-to-sftp/` |
| Presigned destination | List objects beneath `test-harness-presigned/`, without object-read or decryption permissions |
| S3 Access Grants | List grant metadata on the account's regional default instance |

KMS permissions are restricted to use through S3 with the configured encryption
contexts. Hosted storage uses S3 Bucket Keys and therefore a bucket-level
encryption context; S3 object permissions still restrict reads to `pickup/`.
The harness policy grants no object deletion, destination writes or
administrative access. Direct writer invocations remain subject to the
writers' request and source/destination validation.

The SFTP server accepts port 22 only from the push-to-SFTP writer's security
group. The `hubtest` account requires public-key authentication and is confined
to an SFTP-only chroot, with shell access and forwarding disabled. The harness
does not configure an SSH shell or SSM administration path. Outbound security
group rules allow HTTPS to shared protected endpoint subnets and regional S3.

The server's instance role can read its host-private-key secret and the writer's
client-public-key secret, decrypt them through Secrets Manager, and list/write
the read-back prefix. It cannot retrieve the writer's private key. Terraform
creates the host-key secret container without a value; operators supply key
material outside Terraform. The agent refreshes keys and starts `sshd` once a
valid host private key is installed; successful login also needs the client
public key and a host key matching the writer's configured pin.

## Verification scope

| Route | Supported assertions |
| --- | --- |
| Push to S3 | Locate the delivered fixture and compare its contents with the original |
| Hosted pickup | Compare delivered contents and inspect configured retention rules |
| Push to SFTP | Locate the server-produced S3 copy and compare its contents with the original |
| Presigned pickup | Locate the retained fixture, inspect grant metadata and check that a direct read with harness credentials is denied |

SFTP verification covers delivery through the server's read-back agent. A missing
S3 copy may indicate either an SFTP delivery failure or a read-back failure; this
observation alone does not distinguish them or prove every SFTP protocol behaviour.

For presigned pickup, establish that the specific run's fixture exists before
checking a denied read. The policy deliberately supplies no presigned object-read
permission; it does not contain an explicit deny. This check does not establish
successful Slack delivery or an authorised recipient download.

Use a unique run token for each fixture and bounded waits for asynchronous
delivery. Assertions must use the harness role, not an operator's broader
credentials. Never copy a fixture into a destination to satisfy a test.

All four routes start with direct S3 staging. They do not exercise customer-facing
SFTP, FTPS, HTTP API or browser ingestion; the SFTP route tests outbound delivery.
Negative scan outcomes, retries, idempotency and completion events require
dedicated assertions. Deploying this infrastructure does not verify them.

## Storage and retention

Both harness-owned S3 buckets block public access, enforce TLS and bucket-owner
ownership, and enable versioning. Their lifecycle rules expire current and
noncurrent versions after one day, abort incomplete multipart uploads after one
day and remove expired delete markers.

| Storage | Encryption and retention |
| --- | --- |
| Push-to-S3 destination | Dedicated SSE-KMS key; incorrect encryption headers and alternative keys rejected; S3 Bucket Keys disabled; one-day lifecycle |
| SFTP read-back bucket | S3-managed encryption (`AES256`); one-day lifecycle |
| SFTP server files | Encrypted root volume; no automatic file expiry configured |
| Hosted pickup | Component-owned encryption and one-day retention configured by the test route |
| Presigned pickup | Shared storage governed by the [presigned component's retention policy](../pull-from-presigned-url/README.md) |

S3 lifecycle cleanup is asynchronous, not an exact 24-hour deletion guarantee.
It does not clean the SFTP server's disk. Server originals can accumulate and
may be copied again after their read-back objects expire, so the read-back
lifecycle is not an end-to-end retention limit.

Use small, non-sensitive fixtures and account for server disk capacity. Costs
include the running EC2 instance and EBS volume, Secrets Manager, the dedicated
KMS key, S3 storage and repeated read-back requests, plus the existing scanning
and delivery services.

## Deployment dependencies

The harness depends on the parent incoming and clean buckets, the incoming
encryption key, the hosted key at
`alias/s3/integration-hub-test-test-harness-pickup`, the shared secrets key at
`alias/secrets/integration-hub-file-transfer-test`, and the push-to-SFTP writer's
security group. The SFTP server also needs the shared private networking and
connectivity to Secrets Manager and S3. The shared test dispatch module in turn
looks up the harness destination key at
`alias/s3/integration-hub-file-transfer-test-test-harness`.

For the existing test installation, keep the shared routes present on `main`
and aligned across deploying branches. Deploy parent dispatch configuration
and the delivery/pickup components before applying the updated harness role.
A fresh installation requires staged bootstrapping of these key dependencies;
the complete configuration cannot be applied harness-first unchanged.

New dispatch secrets receive their initial configuration from Terraform.
Existing secret values must be maintained through the approved Secrets Manager
process; changing shared configuration alone does not update those values,
including SFTP server addresses and host-key pins.
The harness outputs `destination_bucket_name` and `destination_kms_key_arn`
identify the push-to-S3 destination. See the
[push-to-S3 configuration contract](../push-to-s3/README.md#configuration-contract).

Before running live tests, confirm GitHub environment protection, deployed
recipient-group access, and the test account's Amazon Q Developer in chat
applications connection to the configured Slack workspace and channel. Review
plans through the deployment process and do not run tests while changing
routing or permissions.

### SFTP credentials and test configuration

After deploying the push-to-SFTP component and harness:

1. Populate `integration-hub-file-transfer/test-harness/sftp-host-private-key`
  with the private host key matching `host_public_keys` in the dispatch entry.
  Obtain it through the approved team process, or generate a new pair and update
  both the public pin in shared configuration and the deployed dispatch secret.
2. Populate the route's client `private-key` and `public-key` secrets using the
  approved operator tooling in the [push-to-SFTP README](../push-to-sftp/README.md).
  The writer's private-key secret uses JSON containing `private_key`; the server
  consumes the corresponding public key. Do not commit private keys or pass
  them through Terraform.
3. Allow the server agent to install the keys and confirm the endpoint is ready.
  Set `FILE_TRANSFER_SFTP_DESTINATION_BUCKET` to
  `integration-hub-file-transfer-test-test-harness-sftp` for the live tests.

### Validation

Formatting can be checked from the repository root:

```shell
terraform fmt -check -recursive terraform/environments/integration-hub-file-transfer/test-harness
```

Formatting and Terraform validation do not verify deployed permissions, OIDC
access or file delivery. Runtime results must come from the live tests.