# File-transfer API operations

The API account and the file-processing account are separate. Use an SSO profile for
the account being investigated; a profile name alone doesn't prove it points there.

| Development resource | Account |
| --- | --- |
| API Gateway, upload/docs Lambdas, session table, API alarms | 732169940576 |
| Incoming S3 bucket, scanning/routing and pickup | 346568122691 |

## Verify after apply

From this component directory:

```sh
python3 scripts/verify-operations.py --api-profile integration-hub-api-development \
  --mft-profile YOUR_CURRENT_FILE_TRANSFER_DEVELOPMENT_PROFILE
```

The script is read-only. It checks account IDs, JWT routes, enabled alarm actions,
notification-topic subscribers/encryption, session TTL and bucket multipart cleanup.
It prints only check results and writes `operations-results.json`. Exit 1 means a
failed check; exit 2 means some evidence is still unverified. Read permissions or an
expired SSO session can prevent a check; that isn't evidence that cleanup works.

The locally available `integration-hub-development` profile was found to point to
retired account 508564776517, not the current file-transfer account. Configure/use
the correct SSO profile before verifying the bucket. Don't change credentials in code.

## Notifications

Alarm destinations are existing SNS topic **names** under each environment's
`observability_configuration.alarm_topic_names`, with `high_priority` and `low_priority`.
Terraform looks them up in this component's account and fails if a named topic is
missing. Preproduction and production require both destinations before deployment.

Development uses the existing platform `high-priority-alarms-topic` for both priorities.
It has an encrypted key permitting CloudWatch and a confirmed HTTPS subscriber.
This does not prove message delivery or identify a Slack channel. Confirm the subscriber
route with the platform team and exercise delivery below. No new Slack app, webhook,
SNS subscription, topic policy or encryption key is created by this component.

Alarms cover API 5xx and latency, sustained 4xx, and active Lambda errors/throttles/duration.
The retired Lambda authorizer has no route traffic, so its three alarms are removed.
The 4xx alarm defaults to over 100 responses in each of two five-minute periods; it
includes expected authentication/client failures, not just attacks. Tune it against
customer traffic. It does not by itself identify 429s or every missing-role rejection.
Use access logs to distinguish status codes. Keep security-test runs below that threshold.

## Exercise the notification path

Arrange a development test window with the existing topic's operational recipient.
Use a temporary custom metric/alarm so no application failure needs to be induced.
This produces real ALARM/OK notifications and must use the development account.

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

Wait for the canary to enter ALARM and confirm delivery with its intended recipient.
After that minute has passed, publish Value=0 or let missing data return the alarm to
OK; confirm the recovery notification. Record timestamps and alarm history. Verify the
actual API alarm actions point to the same tested topic. If delivery fails, inspect
alarm history, SNS subscriber delivery and SNS/KMS policies; do not loosen policies
or enable public publish access as a workaround.

Remove only the temporary canary after recording the result:

```sh
aws cloudwatch delete-alarms --profile "$api_profile" --region eu-west-2 \
  --alarm-names integration-hub-api-file-transfer-api-notification-canary
```

A confirmed subscription is not a substitute for this end-to-end check. This procedure
has not been run by the PR. The read-only verification report keeps delivery unverified.

## Follow a failed transfer

Start with time, API request ID and transfer ticket. In the API account inspect:

- `/aws/apigateway/integration-hub-api-file-transfer-api`: status, latency and integration error.
- `/aws/lambda/integration-hub-api-file-transfer-api-upload-ticket`: validation, customer mapping, multipart/S3 failures.
- `/aws/lambda/integration-hub-api-file-transfer-api-docs`: documentation access only.

A 401 points to token validation. For 403, inspect the application role and explicit
consumer/customer mapping. Do not restore Basic authentication. For 429, reduce client
concurrency and retry with backoff. For 5xx, correlate the request with Lambda logs and
S3/DynamoDB failures. Never log a token, secret or full presigned URL.

In the file-transfer account follow file-received, scan-result, stage and route logs,
then the relevant pickup worker and its queue/DLQ. The API alarms do not cover those
separate components. Check queue age, visible messages and DLQ alarms there; confirm
their operational recipients before production sign-off.

## Cleanup and recovery

The session table has TTL on `expires_at_epoch`; deletion is asynchronous. Current API
main retains session records for seven days independently of signed URL expiry.
The incoming bucket's Terraform has a global one-day abort-incomplete-multipart rule.
That lifecycle rule may remove S3 parts before the session record expires. A remaining
session record therefore isn't a promise that an upload can resume for seven days.

For a controlled incomplete transfer, record the ticket/upload ID and confirm that its
parts disappear after lifecycle processing. Use the current file-transfer account to
list multipart uploads and the API account for the session record. Verify both; TTL
only removes the DynamoDB item. Don't delete customer objects or globally abort uploads.
For active test sessions, use the authenticated abort API. For ambiguous completion,
check the session/object outcome before retrying or starting another transfer.

The development recovery test in the API repo exercises interrupted PUT/retry,
invalid ETags, abort and repeat completion. Repeated completion currently returns 409.
Missing checksum, expiry-fixture or cleanup evidence remains incomplete until recorded.

## Capacity and rollout

The verified development gateway baseline is 10 requests/second with burst 20. These
limits govern API control requests, not bytes uploaded directly to S3. Run an agreed,
bounded development load test with representative file sizes and few simultaneous
customers first. Record throughput, API p95/p99 latency, 4xx/5xx/429 counts, Lambda
throttles/duration, queue age and cost. Increase concurrency gradually; don't change
production limits from a laptop benchmark or a single successful upload.

Before release, name the operational owner/on-call, agree alarm thresholds/destinations,
and attach the security/recovery/capacity results. This PR does not create production
identities/accounts or constitute production sign-off.

Deploy application and Terraform revisions together. To recover from a regression,
prefer a reviewed forward fix; otherwise redeploy the last compatible application
revision and apply a reviewed matching Terraform revert. Do not independently roll
back the JWT gateway while leaving a handler expecting different authorizer claims.
Keep access denied during an uncertain rollback rather than re-enable obsolete auth.
Verify a small upload, multipart completion and alarms after recovery.
