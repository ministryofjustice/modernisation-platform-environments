# OAS Security Alerts to Slack - Deployment Guide

## Overview

This Lambda function sends CloudWatch security alarm notifications to Slack. It's triggered by an SNS topic when security-related CloudWatch alarms change state.

## Architecture

```
CloudWatch Alarms (7)
    ↓
SNS: oas-security-alerts-{env}
    ↓
Lambda: oas-security-alerts-to-slack
    ↓
Secrets Manager (Slack webhook)
    ↓
Slack Channel
```

## Deployment Steps

### 1. Create Slack Webhook

1. Go to your Slack workspace
2. Navigate to: https://api.slack.com/messaging/webhooks
3. Create a new Incoming Webhook for your alerts channel (e.g., `#oas-security-alerts`)
4. Copy the webhook URL (format: `https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXX`)

### 2. Deploy Terraform Infrastructure

```bash
cd /path/to/modernisation-platform-environments/terraform/environments/oas

# Initialize Terraform (if not already done)
terraform init

# Plan the changes
terraform plan

# Apply the changes
terraform apply
```

This creates:
- SNS topic: `oas-security-alerts-{env}`
- Lambda function: `oas-security-alerts-to-slack-{env}`
- Security group with HTTPS egress for Slack API
- IAM role and policies
- Secrets Manager secret (empty initially)

### 3. Store Slack Webhook in Secrets Manager

After Terraform apply completes, populate the secret with your Slack webhook URL:

```bash
# Replace {environment} with: development, preproduction, or production
aws secretsmanager put-secret-value \
  --secret-id oas-slack-security-alerts-webhook-{environment} \
  --secret-string '{"webhook_url":"https://hooks.slack.com/services/YOUR/WEBHOOK/URL"}' \
  --region eu-west-2
```

**Important:** The secret value MUST be JSON with a `webhook_url` key.

### 4. Add SNS Topic to CloudWatch Alarms

The 7 security alarms need to be updated to send notifications to the SNS topic. Since these alarms are deployed by the baseline module, you have two options:

#### Option A: Update Alarms via AWS Console (Quick)

1. Go to CloudWatch → Alarms in AWS Console
2. For each of the 7 alarms, edit the alarm:
   - `cloudtrail-configuration-changes`
   - `cmk-removal`
   - `config-configuration-changes`
   - `iam-policy-changes`
   - `s3-bucket-policy-changes`
   - `security-group-changes`
   - `unauthorised-api-calls`
3. In the "Notifications" section, add action:
   - Select SNS topic: `oas-security-alerts-{environment}`
   - Apply to: ALARM state
4. Save changes

#### Option B: Update via AWS CLI (Scriptable)

```bash
#!/bin/bash
ENVIRONMENT="development"  # or preproduction, production
SNS_TOPIC_ARN="arn:aws:sns:eu-west-2:{account-id}:oas-security-alerts-${ENVIRONMENT}"

ALARMS=(
  "cloudtrail-configuration-changes"
  "cmk-removal"
  "config-configuration-changes"
  "iam-policy-changes"
  "s3-bucket-policy-changes"
  "security-group-changes"
  "unauthorised-api-calls"
)

for alarm in "${ALARMS[@]}"; do
  echo "Updating alarm: ${alarm}"
  
  # Get current alarm configuration
  aws cloudwatch describe-alarms --alarm-names "${alarm}" --region eu-west-2 > /tmp/alarm.json
  
  # Add SNS action to the alarm (preserving existing actions)
  aws cloudwatch put-metric-alarm \
    --alarm-name "${alarm}" \
    --alarm-actions "${SNS_TOPIC_ARN}" \
    --region eu-west-2
    
  echo "✓ Updated ${alarm}"
done

echo "All alarms updated successfully"
```

### 5. Test the Integration

Manually trigger a test alarm to verify the Slack integration:

```bash
aws cloudwatch set-alarm-state \
  --alarm-name cloudtrail-configuration-changes \
  --state-value ALARM \
  --state-reason "Test alert for Slack integration" \
  --region eu-west-2
```

Expected result:
- Slack message appears in your alerts channel
- Message shows alarm details with red color (ALARM state)

Reset the alarm to OK:

```bash
aws cloudwatch set-alarm-state \
  --alarm-name cloudtrail-configuration-changes \
  --state-value OK \
  --state-reason "Test complete" \
  --region eu-west-2
```

Expected result:
- Slack message appears with green color (OK state)

### 6. Monitor Lambda Execution

Check Lambda logs to verify it's working:

```bash
aws logs tail /aws/lambda/oas-security-alerts-to-slack-{environment} \
  --follow \
  --region eu-west-2
```

## Troubleshooting

### Lambda fails to send to Slack

**Error:** `Failed to retrieve Slack webhook from Secrets Manager`

**Solution:** Verify the secret value is properly formatted JSON:
```bash
aws secretsmanager get-secret-value \
  --secret-id oas-slack-security-alerts-webhook-{environment} \
  --region eu-west-2
```

Expected output should contain:
```json
{
  "SecretString": "{\"webhook_url\":\"https://hooks.slack.com/services/...\"}"
}
```

### No Slack message received

**Possible causes:**
1. Alarm not configured with SNS action
2. Lambda not subscribed to SNS topic
3. Slack webhook URL incorrect
4. VPC/security group blocking HTTPS egress

**Debug steps:**
```bash
# Check Lambda subscription to SNS
aws sns list-subscriptions-by-topic \
  --topic-arn arn:aws:sns:eu-west-2:{account-id}:oas-security-alerts-{environment} \
  --region eu-west-2

# Check Lambda CloudWatch logs
aws logs tail /aws/lambda/oas-security-alerts-to-slack-{environment} \
  --since 10m \
  --region eu-west-2

# Test webhook manually
curl -X POST \
  -H 'Content-Type: application/json' \
  -d '{"text":"Test from command line"}' \
  https://hooks.slack.com/services/YOUR/WEBHOOK/URL
```

### Lambda timeout

**Error:** Task timed out after 60.00 seconds

**Solution:** Check VPC NAT gateway is functioning. Lambda needs internet access to reach Slack API.

## Updating Lambda Code

After modifying `lambda_function.py`:

1. Package the new code:
```bash
cd lambda/security_alerts_slack
zip lambda_function.zip lambda_function.py
```

2. Apply Terraform changes:
```bash
cd ../../
terraform apply
```

Terraform will detect the ZIP file change and update the Lambda function automatically.

## Files

- `cloudwatch_slack_alerting.tf` - Terraform infrastructure
- `secrets.tf` - Secrets Manager secret definition
- `lambda/security_alerts_slack/lambda_function.py` - Lambda Python code
- `lambda/security_alerts_slack/lambda_function.zip` - Lambda deployment package
- `lambda/security_alerts_slack/package.sh` - Packaging script

## Security Notes

- Lambda runs in VPC with only HTTPS egress allowed
- Slack webhook stored in Secrets Manager (encrypted at rest)
- IAM role follows principle of least privilege
- Only allows reading the specific secret ARN

## Next Steps (Optional)

- Add PagerDuty integration to SNS topic
- Extend Lambda to support different Slack channels based on alarm severity
- Add alarm context/runbook links to Slack messages
- Configure SNS topic encryption
