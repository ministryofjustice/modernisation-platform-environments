# File-transfer API runbook

Use this guide to check alerts, investigate a failed upload and verify cleanup.
The API and file-processing resources are in separate AWS accounts:

| Development resources | Account |
| --- | --- |
| API Gateway, API Lambdas, session table and API alarms | 732169940576 |
| Incoming bucket, scanning, routing and pickup | 346568122691 |

Check the account behind your SSO profile before running commands:

```sh
aws sts get-caller-identity --profile YOUR_PROFILE
```

Some older profiles still point to the retired integration-hub account. Use a
profile for the current file-transfer account when checking its bucket.

## Check the deployment

From this component directory, run:

```sh
python3 scripts/verify-operations.py --api-profile integration-hub-api-development \
  --mft-profile YOUR_FILE_TRANSFER_DEVELOPMENT_PROFILE
```

This reads the account IDs, JWT routes, alarms, notification topics, session TTL
and bucket cleanup rules. It doesn't change resources or send messages.

Results are printed and saved to `operations-results.json`. Exit code 1 means a
check failed; 2 means something still needs verification. For example, the script
can't prove notification delivery, and missing AWS read permissions leave the
bucket check unverified.

## Alarm destinations

Set topic names under each environment's
`observability_configuration.alarm_topic_names`, using `high_priority` and
`low_priority`. Terraform looks up those topics in the API account. A missing
configured topic fails the plan. Both destinations are required for preproduction
and production.

Development uses the existing platform `high-priority-alarms-topic` for both
priorities. The topic is encrypted, permits CloudWatch to use its key and has a
confirmed HTTPS subscriber. Confirm where that subscription delivers messages
before relying on it for support.

Alarms cover API server errors, latency, sustained client errors, and active Lambda
errors, throttles and duration. The unused Lambda authorizer's alarms are removed.
The new 4xx alarm fires when there are more than 100 client-error responses in each
of two consecutive five-minute periods. These may include ordinary validation or
login failures, so check the access logs before treating them as a security incident.
Tune the threshold once there is a representative traffic baseline.

## Test an alert

Let the alert recipient know you're testing. Create a temporary alarm on a test
metric, rather than breaking the API. The following commands send real ALARM and
OK notifications through the development topic:

```sh
api_profile=integration-hub-api-development
aws sts get-caller-identity --profile "$api_profile"
# Confirm Account is 732169940576 before continuing.
aws cloudwatch put-metric-alarm --profile "$api_profile" --region eu-west-2 \
  --alarm-name integration-hub-api-file-transfer-api-notification-canary \
  --namespace IntegrationHub/FileTransferAcceptance --metric-name NotificationCanary \
  --statistic Sum --period 60 --evaluation-periods 1 --threshold 0 \
  --comparison-operator GreaterThanThreshold --treat-missing-data notBreaching \
  --alarm-actions arn:aws:sns:eu-west-2:732169940576:high-priority-alarms-topic \
  --ok-actions arn:aws:sns:eu-west-2:732169940576:high-priority-alarms-topic
aws cloudwatch put-metric-data --profile "$api_profile" --region eu-west-2 \
  --namespace IntegrationHub/FileTransferAcceptance \
  --metric-data MetricName=NotificationCanary,Value=1,Unit=Count
```

Wait for the alarm to enter ALARM and confirm the message arrived. Once that minute
has passed, publish the same metric with `Value=0`, or let missing data return it to
OK. Confirm the recovery message too, and save the timestamps and alarm history.

If no message arrives, check CloudWatch alarm history, the SNS subscription and
SNS/KMS permissions. Confirm the API's alarms use the same topic you tested.

Remove the temporary alarm when finished:

```sh
aws cloudwatch delete-alarms --profile "$api_profile" --region eu-west-2 \
  --alarm-names integration-hub-api-file-transfer-api-notification-canary
```

The read-only checker leaves delivery unverified until this test is recorded.

## Investigate an upload

Start with the time, API request ID and transfer ticket. In the API account, check:

| Log group | What it shows |
| --- | --- |
| `/aws/apigateway/integration-hub-api-file-transfer-api` | HTTP status, latency and integration errors |
| `/aws/lambda/integration-hub-api-file-transfer-api-upload-ticket` | Validation, customer permissions and multipart/S3 failures |
| `/aws/lambda/integration-hub-api-file-transfer-api-docs` | Documentation access |

- **401:** check token expiry, issuer and audience.
- **403:** check the application's upload role and customer mapping.
- **429:** reduce request concurrency and use retry backoff.
- **5xx:** follow the request into Lambda logs and check S3 or DynamoDB errors.

Keep secrets, tokens and signed URLs out of logs and shared screenshots.

For a file that uploaded but hasn't reached pickup, switch to the file-transfer
account. Follow file-received, scan-result, stage and route logs, then the pickup
worker. Check its queue age, pending messages and dead-letter queue. Those components
have separate monitoring; confirm their alert recipients before release.

## Incomplete uploads and cleanup

DynamoDB session records use TTL on `expires_at_epoch`. The API currently keeps
records for seven days; removal after expiry is asynchronous. The incoming bucket
has a one-day rule for aborting incomplete S3 multipart uploads.

These are separate lifetimes. A session record can remain after its S3 parts have
been removed, so seven-day record retention doesn't promise seven-day upload resume.

For a controlled incomplete test upload, record its ticket and S3 upload ID. Check
that lifecycle processing removes the parts, and check the session record separately.
DynamoDB TTL doesn't remove S3 parts. Use the authenticated abort endpoint to cancel
an active test upload without waiting for lifecycle processing.

If completion times out, inspect the session and object before trying again. The
file may already have completed. Repeated completion currently returns 409. The
API repo's recovery suite covers this along with interrupted PUTs, retries, invalid
ETags and aborts.

## Capacity testing

Development is configured for 10 API requests/second with burst 20. These limits
apply to ticket and multipart operations, not the bytes sent directly to S3.

Agree a test window and data volume, then start with a few simultaneous uploads.
Use representative file sizes and record:

- Upload throughput and API p95/p99 latency.
- HTTP 4xx, 5xx and 429 counts.
- Lambda throttles and duration.
- Downstream queue age and test cost.

Increase concurrency gradually. Use those results to choose production limits;
a single laptop upload doesn't establish service capacity.

## Release and rollback

Before release, agree the support owner, alert destinations and thresholds. Keep
the security, recovery and capacity results with the release record, including
any checks still outstanding.

Treat the application and Terraform as a coordinated deployment. Prefer a reviewed
forward fix. If a rollback is needed, redeploy the last compatible application
revision and apply its matching reviewed Terraform revert. Don't roll back the
JWT gateway independently of the handler's authentication expectations or restore
Basic authentication as a shortcut.

After recovery, check a small upload, multipart completion and alert delivery.
