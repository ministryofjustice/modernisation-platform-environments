# Firewall Log Shipper
AWS Lambda function that reads logs written to S3 (gzip or plain text, one JSON event per line, e.g., AWS Network Firewall EVE JSON) and ships them to CloudWatch Logs.

## Concept of operation
- **Trigger sources:** Handles direct **S3 ObjectCreated** events, or events delivered via **SQS** (raw S3 event in `body`) and **SNS→SQS** (S3 event wrapped in `Message`).
- **Read & decode:** Streams the S3 object; auto-detects gzip (`ContentEncoding=gzip` or `.gz` suffix) and yields UTF-8 lines.
- **Timestamp extraction:** For each line (JSON):
  - Prefer `event_timestamp` (epoch seconds; string or number), then
  - Fallback to `event.timestamp` (ISO-8601; supports `Z` or `+0000`).
- **Event filtering:** Drops events older than **14 days** (`MAX_AGE_MS`) or more than **2 hours** in the future (`MAX_FUTURE_MS`).
- **CloudWatch Logs write:**
  - Uses **existing** log group (does not create it); log stream name is derived from the S3 **object key** (trimmed to 512 chars).
  - Sorts by timestamp and ships in batches (`CHUNK_SIZE`, default 1000).
  - Handles `InvalidSequenceTokenException` with a single refresh/retry of the upload sequence token.
- **Return value:** `{"status": "ok"}` when a batch completes.

### Environment variables
- `LOG_GROUP_NAME` (required): Target CloudWatch Logs log group.

### Tunables (constants in code)
- `CHUNK_SIZE` (default **1000**)
- `MAX_AGE_MS` (default **14 days**)
- `MAX_FUTURE_MS` (default **2 hours**)

## Requirements
- **Python:** 3.12 (AWS Lambda runtime recommended)  
- **AWS permissions (minimum):**
  - `logs:CreateLogStream` (for the target log group)
  - `logs:DescribeLogStreams`
  - `logs:PutLogEvents`
  - `s3:GetObject` (for the source bucket/prefix)
  - If the bucket is KMS-encrypted: `kms:Decrypt` for the key
- **Python packages:** `boto3` (available in Lambda by default; include in local/dev environments)

## Installation / use
1. **Create/choose** a CloudWatch Logs **log group** and set `LOG_GROUP_NAME` on the Lambda.
2. **Deploy** the Lambda (runtime Python 3.12). Attach an IAM role with the permissions above.
3. **Configure triggers:**
   - **Direct S3:** Add an ObjectCreated notification on the bucket/prefix.
   - **SQS:** Point S3 (or SNS) to an SQS queue; subscribe the Lambda to the queue.
   - **SNS→SQS:** S3 → SNS topic → SQS queue → Lambda (the code unwraps the `Message`).
4. **Test:** Upload a sample gz or text file with one JSON event per line and confirm events appear in the log group.

## Command line interface (if applicable)
No CLI is provided; the entry point is the Lambda `handler(event, context)`.

## Arguments (if applicable)
N/A. The function consumes AWS event payloads. Configuration is via environment variables and code constants.

## Usage examples
- **Direct S3 event:** Upload `s3://my-bucket/network-firewall/2025/10/15/part-0001.log.gz`. The Lambda reads, parses, filters, and writes events to the log group specified by `LOG_GROUP_NAME`, creating a log stream derived from the object key.
- **SQS-wrapped event:** Same upload, but S3 sends the event to SQS. The Lambda unwraps `body` → `Records` → `s3`.

## Operational scenarios
- **Network Firewall centralised logging:** Ship EVE JSON from S3 to CloudWatch for dashboards, Insights queries, and alarms.
- **Backfill/redrive:** Push historical object keys to an SQS queue; the Lambda will process in batches.
- **Large files:** The function streams and batches; adjust memory/timeout and `CHUNK_SIZE` if needed.

## Troubleshooting
- **Nothing appears in CloudWatch Logs:**
  - Ensure `LOG_GROUP_NAME` is correct and the log group exists (the function does **not** create it).
  - Verify IAM allows `logs:*` actions listed above and `s3:GetObject` on the source path.
- **`InvalidSequenceTokenException`:** The function auto-refreshes the token once. Repeated failures may indicate concurrent writers to the same stream—ensure a unique stream per object/key or serialize processing.
- **`DataAlreadyAcceptedException` / duplicates:** Indicates overlapping retries with identical batches; safe to ignore if infrequent.
- **`AccessDenied` / `KMS.AccessDenied`:** Add `kms:Decrypt` for the bucket’s CMK.
- **Timestamps rejected:** Events older than 14 days or >2h future are dropped by design; check time sources and parsing.
- **Gzip decode issues:** Ensure the object has the correct encoding or `.gz` suffix.

## Safety, Auditability, and Change Control
- **Least privilege:** The function only needs read on S3 and write to the specific log group.
- **Deterministic ingest:** Sorted by event time; drops out-of-bounds events to respect CloudWatch constraints.
- **No log-group creation:** Prevents accidental sprawl; manage log groups and retention via IaC (Terraform/CloudFormation).
- **Change control:** Version the Lambda (aliases), track changes in VCS, and roll out via CI/CD with approvals.
- **Observability:** Use CloudWatch metrics/alarms on Lambda errors, throttles, and duration; enable log retention on the target log group.
