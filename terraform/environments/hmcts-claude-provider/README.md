# HMCTS Claude Provider

This environment provides AWS Bedrock access for Claude AI models in the eu-west-2 (London) region.

## AWS Bedrock Setup

This environment is configured to use AWS Bedrock with Claude models. The following manual setup steps are required:

### 1. Create Bedrock API Key

The Terraform creates the necessary IAM policies and roles, including a `BedrockAPIKeyCreator` role. Use this role to create the Bedrock API key:

```bash
# 1. Create the IAM user (if it doesn't exist already)
aws iam create-user \
  --user-name BedrockAPIKey-hmcts-claude \
  --profile hmcts-claude-provider-development

# 2. Attach the Bedrock access policy to the user
aws iam attach-user-policy \
  --user-name BedrockAPIKey-hmcts-claude \
  --policy-arn arn:aws:iam::313941174580:policy/HMCTSClaudeBedrockPolicy \
  --profile hmcts-claude-provider-development

# 3. Assume the BedrockAPIKeyCreator role
aws sts assume-role \
  --role-arn "arn:aws:iam::313941174580:role/BedrockAPIKeyCreator" \
  --role-session-name "create-bedrock-key" \
  --profile hmcts-claude-provider-development

# 4. Export the credentials returned from the above command
export AWS_ACCESS_KEY_ID="<AccessKeyId from output>"
export AWS_SECRET_ACCESS_KEY="<SecretAccessKey from output>"
export AWS_SESSION_TOKEN="<SessionToken from output>"

# 5. Create the service-specific credential for Bedrock (30-day expiration)
aws iam create-service-specific-credential \
  --user-name BedrockAPIKey-hmcts-claude \
  --service-name bedrock.amazonaws.com \
  --credential-age-days 30

# 6. Save the returned 'ServicePassword' - this is your AWS_BEARER_TOKEN_BEDROCK
# Note: The password is only shown once and cannot be retrieved again
```

### 2. Create Application Inference Profile

To ensure all requests stay in eu-west-2 (avoiding SCP restrictions in other regions), create a custom inference profile:

```bash
aws bedrock create-inference-profile \
  --region eu-west-2 \
  --profile hmcts-claude-provider-development \
  --inference-profile-name hmcts-claude-sonnet-4-5-eu-west-2 \
  --model-source '{"copyFrom":"arn:aws:bedrock:eu-west-2::foundation-model/anthropic.claude-sonnet-4-5-20250929-v1:0"}'
```

The inference profile ID will be `hmcts-claude-sonnet-4-5-eu-west-2` (the name you specified).

### 3. Configure Claude Code

Create a `claude.sh` script to configure Claude Code for Bedrock:

```bash
#!/usr/bin/env bash

export CLAUDE_CODE_MAX_OUTPUT_TOKENS=4096
export MAX_THINKING_TOKENS=1024
export ANTHROPIC_MODEL='arn:aws:bedrock:eu-west-2:313941174580:application-inference-profile/hmcts-claude-sonnet-4-5-eu-west-2'
export AWS_BEARER_TOKEN_BEDROCK='<your-bedrock-api-key>'    # From step 1
export AWS_REGION=eu-west-2
export CLAUDE_CODE_USE_BEDROCK=1

claude
```

Make it executable and run:

```bash
chmod +x claude.sh
./claude.sh
```

## Available Models

- **Claude Sonnet 4.5**: `anthropic.claude-sonnet-4-5-20250929-v1:0`
- **Claude Sonnet 3.7**: `anthropic.claude-3-7-sonnet-20250219-v1:0`
- **Claude Sonnet 3**: `anthropic.claude-3-sonnet-20240229-v1:0`
- **Claude Haiku 3**: `anthropic.claude-3-haiku-20240307-v1:0`

## Troubleshooting

### SCP Denied Errors

If you get "explicit deny in a service control policy" errors, ensure you're using the custom inference profile (`hmcts-claude-sonnet-4-5-eu-west-2`) rather than the system-defined regional profiles (e.g., `eu.anthropic.claude-*`). The custom profile ensures all requests stay in eu-west-2.


## Mandatory Information

### **Last review date:**

<!-- Adding the last date this page was reviewed, with any accompanying information -->

### **Description:**

<!-- A short (less than 50 word) description of what your service does, and who it’s for.-->

### **Service URLs:**

<!--  The URL(s) of the service’s production environment, and test environments if possible-->

### **Incident response hours:**

<!-- When your service receives support for urgent issues. This should be written in a clear, unambiguous way. For example: 24/7/365, Office hours, usually 9am-6pm on working days, or 7am-10pm, 365 days a year. -->

### **Incident contact details:**

<!-- How people can raise an urgent issue with your service. This must not be the email address or phone number of an individual on your team, it should be a shared email address, phone number, or website that allows someone with an urgent issue to raise it quickly. -->

### **Service team contact:**

<!-- How people with non-urgent issues or questions can get in touch with your team. As with incident contact details, this must not be the email address or phone number of an individual on the team, it should be a shared email address or a ticket tracking system.-->

### **Hosting environment:**

Modernisation Platform

<!-- If your service is hosted on another MOJ team’s infrastructure, link to their runbook. If your service has another arrangement or runs its own infrastructure, you should list the supplier of that infrastructure (ideally linking to your account’s login page) and describe, simply and briefly, how to raise an issue with them. -->

## Optional

### **Other URLs:**

<!--  If you can, provide links to the service’s monitoring dashboard(s), health checks, documentation (ideally describing how to run/work with the service), and main GitHub repository. -->

### **Expected speed and frequency of releases:**

<!-- How often are you able to release changes to your service, and how long do those changes take? -->

### **Automatic alerts:**

<!-- List, briefly, problems (or types of problem) that will automatically alert your team when they occur. -->

### **Impact of an outage:**

<!-- A short description of the risks if your service is down for an extended period of time. -->

### **Out of hours response types:**

<!-- Describe how incidents that page a person on call are responded to. How long are out-of-hours responders expected to spend trying to resolve issues before they stop working, put the service into maintenance mode, and hand the issue to in-hours support? -->

### **Consumers of this service:**

<!-- List which other services (with links to their runbooks) rely on this service. If your service is considered a platform, these may be too numerous to reasonably list. -->

### **Services consumed by this:**

<!-- List which other services (with links to their runbooks) this service relies on. -->

### **Restrictions on access:**

<!-- Describe any conditions which restrict access to the service, such as if it’s IP-restricted or only accessible from a private network.-->

### **How to resolve specific issues:**

<!-- Describe the steps someone might take to resolve a specific issue or incident, often for use when on call. This may be a large amount of information, so may need to be split out into multiple pages, or link to other documents.-->
